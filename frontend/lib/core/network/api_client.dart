import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../error/api_exception.dart';

/// Único punto que habla HTTP con el backend ("el puente").
/// Las capas de dominio nunca ven `http`: solo ven repositorios.
///
/// Sesión (ADR-0014): si una petición responde 401 y hay refresh token, pide un par nuevo a
/// `POST /auth/refresh` UNA sola vez (aunque fallen varias peticiones a la vez) y repite la
/// petición. Si el refresco también es rechazado, avisa con [alVencerSesion].
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlFijo = baseUrl;

  final http.Client _client;
  final String? _baseUrlFijo;
  final Random _azar = Random();

  String? _token;
  String? _refresh;
  Future<bool>? _renovando;

  /// Se llama con el par nuevo tras un refresco (para guardarlo en el dispositivo).
  void Function(String access, String refresh)? alRenovarTokens;

  /// Se llama cuando la sesión ya no se puede renovar (refresh vencido o revocado).
  void Function()? alVencerSesion;

  /// Sigue a [ApiConfig.baseUrl], que puede cambiarse en compilaciones de desarrollo.
  String get baseUrl => _baseUrlFijo ?? ApiConfig.baseUrl;

  /// JWT Bearer (ADR-0004).
  void fijarToken(String? token) => _token = token;

  void fijarTokens(String? access, String? refresh) {
    _token = access;
    _refresh = refresh;
  }

  String? get refreshToken => _refresh;

  Map<String, String> _cabeceras([Map<String, String>? extra]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Uri _uri(String ruta, [Map<String, dynamic>? parametros]) {
    final base = Uri.parse('$baseUrl$ruta');
    if (parametros == null || parametros.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...parametros.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  String? get token => _token;

  /// Lee todas las páginas de un listado paginado con skip/limit (la API devuelve como
  /// máximo 100 por página).
  Future<List<dynamic>> getTodo(String ruta, {Map<String, dynamic>? parametros}) async {
    const tamano = 100;
    final todo = <dynamic>[];
    for (var skip = 0;; skip += tamano) {
      final pagina = await get(ruta,
          parametros: {...?parametros, 'skip': skip, 'limit': tamano}) as List<dynamic>;
      todo.addAll(pagina);
      if (pagina.length < tamano) return todo;
    }
  }

  Future<dynamic> get(
    String ruta, {
    Map<String, dynamic>? parametros,
    int? reintentos,
  }) {
    final max = reintentos ?? ApiConfig.reintentosLectura;
    return _conReintentos(
      () => _enviar(ruta, () => _client.get(_uri(ruta, parametros), headers: _cabeceras())),
      max,
    );
  }

  /// Los POST no se reintentan solos: un reintento ciego podría duplicar el préstamo.
  /// Si el llamador quiere reintentar, debe reenviar la MISMA `X-Idempotency-Key` (S11 req. 11.3).
  Future<dynamic> post(
    String ruta, {
    Object? cuerpo,
    Map<String, String>? cabeceras,
  }) {
    return _enviar(
      ruta,
      () => _client.post(
        _uri(ruta),
        headers: _cabeceras(cabeceras),
        body: cuerpo == null ? null : jsonEncode(cuerpo),
      ),
    );
  }

  Future<dynamic> put(
    String ruta, {
    Object? cuerpo,
    Map<String, String>? cabeceras,
  }) {
    return _enviar(
      ruta,
      () => _client.put(
        _uri(ruta),
        headers: _cabeceras(cabeceras),
        body: cuerpo == null ? null : jsonEncode(cuerpo),
      ),
    );
  }

  Future<dynamic> patch(
    String ruta, {
    Object? cuerpo,
    Map<String, String>? cabeceras,
  }) {
    return _enviar(
      ruta,
      () => _client.patch(
        _uri(ruta),
        headers: _cabeceras(cabeceras),
        body: cuerpo == null ? null : jsonEncode(cuerpo),
      ),
    );
  }

  /// GET que devuelve el cuerpo como texto (p. ej. el CSV de la bitácora), con la sesión.
  Future<String> getTexto(String ruta, {Map<String, dynamic>? parametros}) async {
    final r = await _enviar(
      ruta,
      () => _client.get(_uri(ruta, parametros), headers: _cabeceras()),
      comoTexto: true,
    );
    return (r ?? '') as String;
  }

  Future<dynamic> delete(String ruta) {
    return _enviar(ruta, () => _client.delete(_uri(ruta), headers: _cabeceras()));
  }

  static const _sinRefresco = {'/auth/login', '/auth/refresh', '/auth/register'};

  Future<dynamic> _enviar(
    String ruta,
    Future<http.Response> Function() peticion, {
    bool comoTexto = false,
  }) async {
    try {
      var r = await peticion().timeout(ApiConfig.timeout);
      if (r.statusCode == 401 && _refresh != null && !_sinRefresco.contains(ruta)) {
        if (await _renovar()) {
          r = await peticion().timeout(ApiConfig.timeout);
        }
      }
      if (r.statusCode >= 200 && r.statusCode < 300) {
        if (r.bodyBytes.isEmpty) return null;
        final texto = utf8.decode(r.bodyBytes);
        return comoTexto ? texto : jsonDecode(texto);
      }
      throw ApiException.fromResponse(r);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException.tiempoAgotado();
    } on http.ClientException {
      throw ApiException.sinConexion();
    } on FormatException {
      throw ApiException(
        TipoError.desconocido,
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }
  }

  /// Un solo refresco aunque varias peticiones reciban 401 a la vez.
  Future<bool> _renovar() {
    return _renovando ??= _pedirTokensNuevos().whenComplete(() => _renovando = null);
  }

  Future<bool> _pedirTokensNuevos() async {
    try {
      final r = await _client
          .post(
            _uri('/auth/refresh'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'refresh_token': _refresh}),
          )
          .timeout(ApiConfig.timeout);
      if (r.statusCode == 200) {
        final cuerpo = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        final access = (cuerpo['access_token'] ?? '').toString();
        final refresh = (cuerpo['refresh_token'] ?? _refresh).toString();
        if (access.isNotEmpty) {
          fijarTokens(access, refresh);
          alRenovarTokens?.call(access, refresh);
          return true;
        }
      }
      if (r.statusCode == 401 || r.statusCode == 403) {
        fijarTokens(null, null);
        alVencerSesion?.call();
      }
      return false;
    } catch (_) {
      // Sin red: no se cierra la sesión; la petición original devuelve su propio error.
      return false;
    }
  }

  /// Backoff exponencial + jitter: delay = base * 2^intento + aleatorio.
  Future<dynamic> _conReintentos(
    Future<dynamic> Function() accion,
    int maxReintentos,
  ) async {
    var intento = 0;
    while (true) {
      try {
        return await accion();
      } on ApiException catch (e) {
        final transitorio = e.esDeRed || e.tipo == TipoError.servidor;
        if (!transitorio || intento >= maxReintentos) rethrow;
        intento++;
        final base = 300 * pow(2, intento - 1).toInt();
        final jitter = _azar.nextInt(150);
        await Future<void>.delayed(Duration(milliseconds: base + jitter));
      }
    }
  }

  void cerrar() => _client.close();
}

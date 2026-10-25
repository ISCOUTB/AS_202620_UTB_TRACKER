import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../error/api_exception.dart';

/// Único punto que habla HTTP con el backend ("el puente").
/// Las capas de dominio nunca ven `http`: solo ven repositorios.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Random _azar = Random();

  String? _token;

  String get baseUrl => _baseUrl;

  /// JWT Bearer (ADR-0004). Hoy el backend aún no lo exige, pero se envía siempre que exista.
  void fijarToken(String? token) => _token = token;

  Map<String, String> _cabeceras([Map<String, String>? extra]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Uri _uri(String ruta, [Map<String, dynamic>? parametros]) {
    final base = Uri.parse('$_baseUrl$ruta');
    if (parametros == null || parametros.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...parametros.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  String? get token => _token;

  Future<dynamic> get(
    String ruta, {
    Map<String, dynamic>? parametros,
    int? reintentos,
  }) {
    final max = reintentos ?? ApiConfig.reintentosLectura;
    return _conReintentos(
      () => _enviar(() => _client.get(_uri(ruta, parametros), headers: _cabeceras())),
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
      () => _client.patch(
        _uri(ruta),
        headers: _cabeceras(cabeceras),
        body: cuerpo == null ? null : jsonEncode(cuerpo),
      ),
    );
  }

  Future<dynamic> delete(String ruta) {
    return _enviar(() => _client.delete(_uri(ruta), headers: _cabeceras()));
  }

  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    try {
      final r = await peticion().timeout(ApiConfig.timeout);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        if (r.bodyBytes.isEmpty) return null;
        return jsonDecode(utf8.decode(r.bodyBytes));
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

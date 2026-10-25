import '../../../core/error/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';
import '../domain/auth_domain.dart';

class UsuarioModel {
  UsuarioModel._();

  /// JSON de `UserResponse`.
  static Usuario desdeJson(Map<String, dynamic> j) => Usuario(
        id: (j['id'] as num).toInt(),
        nombre: (j['nombre'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        rol: (j['rol'] ?? '').toString(),
      );
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> login(String nombre, String password) async {
    final r = await _api.post(
      '/auth/login',
      cuerpo: {'nombre': nombre, 'password': password},
    );
    return r as Map<String, dynamic>;
  }

  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String rol,
    required String password,
  }) async {
    final r = await _api.post(
      '/auth/register',
      cuerpo: {
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'password': password,
      },
    );
    return UsuarioModel.desdeJson(r as Map<String, dynamic>);
  }

  Future<Usuario> me() async {
    final r = await _api.get('/auth/me');
    return UsuarioModel.desdeJson(r as Map<String, dynamic>);
  }

  Future<Usuario> obtenerUsuario(int id) async {
    final r = await _api.get('/auth/user/$id', reintentos: 0);
    return UsuarioModel.desdeJson(r as Map<String, dynamic>);
  }

  Future<List<Usuario>> listarUsuarios({String? search, String? rol}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (rol != null && rol.trim().isNotEmpty) {
      query['rol'] = rol.trim();
    }
    final r = await _api.get('/auth/users', parametros: query.isEmpty ? null : query);
    if (r is! List) return [];
    return r.map((e) => UsuarioModel.desdeJson(e as Map<String, dynamic>)).toList();
  }

  Future<Usuario> actualizarRolUsuario(int id, String rol) async {
    final r = await _api.patch(
      '/auth/user/$id/role',
      cuerpo: {'rol': rol},
    );
    return UsuarioModel.desdeJson(r as Map<String, dynamic>);
  }

  Future<bool> salud() async {
    try {
      final r = await _api.get('/salud', reintentos: 0);
      return r is Map && r['status'] == 'ok';
    } on ApiException {
      return false;
    }
  }
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoto, this._api);

  final AuthRemoteDataSource _remoto;
  final ApiClient _api;

  /// Tope de ids que se exploran para identificar al usuario (ver [_identificar]).
  static const int _maxIdExploracion = 100;
  static const int _lote = 10;

  @override
  Future<Sesion> iniciarSesion(
    String nombre,
    String password, {
    Usuario? conocido,
  }) async {
    final r = await _remoto.login(nombre, password);
    final token = (r['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException(
        TipoError.desconocido,
        'El servidor no devolvió un token de acceso.',
      );
    }
    _api.fijarToken(token);

    try {
      final usuario = conocido ?? await _identificar(r, token, nombre);
      return Sesion(token: token, usuario: usuario);
    } catch (_) {
      _api.fijarToken(null);
      rethrow;
    }
  }

  /// Identifica el usuario autenticado:
  /// 1) Lee directamente el campo `user` devuelto por `/auth/login`.
  /// 2) O consulta `GET /auth/me` con el token JWT recién fijado.
  /// 3) Si ambos fallan, busca por coincidencia en `/auth/user/{id}`.
  Future<Usuario> _identificar(
    Map<String, dynamic> respuestaLogin,
    String token,
    String nombre,
  ) async {
    // 1) Datos directos incluidos en la respuesta de login
    if (respuestaLogin['user'] is Map<String, dynamic>) {
      return UsuarioModel.desdeJson(
        respuestaLogin['user'] as Map<String, dynamic>,
      );
    }
    final idDirecto = respuestaLogin['id'];
    if (idDirecto is num) return _remoto.obtenerUsuario(idDirecto.toInt());

    // 2) Consultar GET /auth/me
    try {
      return await _remoto.me();
    } catch (_) {}

    // 3) Fallback por escaneo
    final email = (respuestaLogin['email'] ?? leerPayloadJwt(token)?['sub'] ?? '')
        .toString()
        .toLowerCase();

    for (var inicio = 1; inicio <= _maxIdExploracion; inicio += _lote) {
      final lote = await Future.wait(
        List.generate(_lote, (i) => _intentarUsuario(inicio + i)),
      );
      for (final u in lote) {
        if (u == null) continue;
        if (u.email.toLowerCase() == email || u.nombre == nombre) return u;
      }
    }
    throw ApiException(
      TipoError.noEncontrado,
      'Iniciaste sesión, pero no pude identificar tu usuario.',
    );
  }

  @override
  Future<Usuario> usuarioActual() => _remoto.me();

  Future<Usuario?> _intentarUsuario(int id) async {
    try {
      return await _remoto.obtenerUsuario(id);
    } on ApiException catch (e) {
      if (e.tipo == TipoError.noEncontrado) return null;
      rethrow;
    }
  }

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String rol,
    required String password,
  }) =>
      _remoto.registrar(
        nombre: nombre,
        email: email,
        rol: rol,
        password: password,
      );

  @override
  Future<Usuario> obtenerUsuario(int id) => _remoto.obtenerUsuario(id);

  @override
  Future<List<Usuario>> listarUsuarios({String? busqueda, String? rol}) =>
      _remoto.listarUsuarios(search: busqueda, rol: rol);

  @override
  Future<Usuario> actualizarRolUsuario(int usuarioId, String nuevoRol) =>
      _remoto.actualizarRolUsuario(usuarioId, nuevoRol);

  @override
  Future<bool> servidorSaludable() => _remoto.salud();
}

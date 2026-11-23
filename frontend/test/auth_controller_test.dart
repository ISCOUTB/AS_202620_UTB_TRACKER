import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/notifications/fcm_registration.dart';
import 'package:utb_tracker_app/features/auth/data/auth_data.dart';
import 'package:utb_tracker_app/features/auth/domain/auth_domain.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';

class _FcmFalso extends FcmRegistration {
  @override
  Future<void> start(FcmTokenRegistrar registrar) async {}

  @override
  Future<void> stop() async {}
}

/// Repositorio falso con una sola cuenta.
class _AuthFalso implements AuthRepository {
  ApiException? falloRegistro;

  Usuario get _u => const Usuario(
        id: 7,
        nombre: 'Ana',
        email: 'ana@utb.edu.co',
        rol: 'usuario_utb',
      );

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    if (falloRegistro != null) throw falloRegistro!;
    return _u;
  }

  @override
  Future<Sesion> iniciarSesion(String nombre, String password, {Usuario? conocido}) async {
    if (password != 'ClaveSegura1') {
      throw ApiException(TipoError.noAutorizado, 'Usuario, correo o contraseña incorrectos');
    }
    return Sesion(token: 'a', refreshToken: 'r', usuario: conocido ?? _u);
  }

  @override
  Future<Usuario> usuarioActual() async => _u;

  @override
  Future<Usuario> obtenerUsuario(int id) async => _u;

  @override
  Future<List<Usuario>> listarUsuarios({String? busqueda, String? rol}) async => [_u];

  @override
  Future<Usuario> actualizarRolUsuario(int usuarioId, String nuevoRol) async => _u;

  @override
  Future<void> registrarTokenFcm(String token) async {}

  @override
  Future<bool> servidorSaludable() async => true;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  AuthController crear(_AuthFalso repo) => AuthController(
        repo,
        ApiClient(baseUrl: 'http://x', client: MockClient((_) async => http.Response('{}', 200))),
        _FcmFalso(),
      );

  test('al registrarse entra directo y guarda los tokens (sin verificación)', () async {
    final repo = _AuthFalso();
    final auth = crear(repo);

    expect(await auth.registrar(nombre: 'Ana', email: 'ana@utb.edu.co', password: 'ClaveSegura1'),
        isTrue);
    expect(auth.autenticado, isTrue);
    // Se guardaron access y refresh.
    expect(await const FlutterSecureStorage().read(key: 'utb_refresh_token'), 'r');
  });

  test('los errores del registro llegan claros y no inician sesión', () async {
    final repo = _AuthFalso()
      ..falloRegistro = ApiException(TipoError.conflicto,
          'Ya hay una cuenta con ese correo. Inicia sesión o recupera tu contraseña.');
    final auth = crear(repo);

    expect(await auth.registrar(nombre: 'Ana', email: 'ana@utb.edu.co', password: 'ClaveSegura1'),
        isFalse);
    expect(auth.autenticado, isFalse);
    expect(auth.error, contains('Ya hay una cuenta'));
  });

  test('login con correo o usuario; clave mala da mensaje del servidor', () async {
    final auth = crear(_AuthFalso());
    expect(await auth.iniciarSesion('ana@utb.edu.co', 'Mala'), isFalse);
    expect(auth.error, 'Usuario, correo o contraseña incorrectos');
    expect(await auth.iniciarSesion('ana@utb.edu.co', 'ClaveSegura1'), isTrue);
  });

  test('cerrar sesión borra los tokens guardados', () async {
    final auth = crear(_AuthFalso());
    await auth.iniciarSesion('Ana', 'ClaveSegura1');
    auth.cerrarSesion();
    await Future<void>.delayed(Duration.zero);
    expect(auth.autenticado, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'utb_access_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'utb_refresh_token'), isNull);
  });

  test('el parseo ignora el campo email_verificado de servidores viejos', () {
    final u = UsuarioModel.desdeJson(
        {'id': 1, 'nombre': 'A', 'email': 'a@b.co', 'rol': 'auxiliar', 'email_verificado': false});
    expect(u.rol, 'auxiliar');
  });
}

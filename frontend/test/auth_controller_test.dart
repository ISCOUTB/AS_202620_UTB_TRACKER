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

/// Repositorio falso con una sola cuenta que puede estar verificada o no.
class _AuthFalso implements AuthRepository {
  bool verificado = false;
  int reenvios = 0;
  ApiException? falloRegistro;

  Usuario get _u => Usuario(
        id: 7,
        nombre: 'Ana',
        email: 'ana@utb.edu.co',
        rol: 'usuario_utb',
        emailVerificado: verificado,
      );

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String rol,
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
  Future<void> reenviarVerificacion() async {
    reenvios++;
    if (reenvios > 2) {
      throw ApiException(TipoError.limite, 'Ya te enviamos varios correos.');
    }
  }

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

  test('al registrarse queda la verificación pendiente', () async {
    final repo = _AuthFalso();
    final auth = crear(repo);

    expect(await auth.registrar(nombre: 'Ana', email: 'ana@utb.edu.co', password: 'ClaveSegura1'),
        isTrue);
    expect(auth.autenticado, isTrue);
    expect(auth.correoVerificado, isFalse);
    expect(auth.mostrarVerificacionPendiente, isTrue);
    // Se guardaron access y refresh.
    expect(await const FlutterSecureStorage().read(key: 'utb_refresh_token'), 'r');

    auth.continuarSinVerificar();
    expect(auth.mostrarVerificacionPendiente, isFalse);
    expect(auth.correoVerificado, isFalse); // el aviso fijo sigue
  });

  test('"Ya lo verifiqué" relee el perfil', () async {
    final repo = _AuthFalso();
    final auth = crear(repo);
    await auth.registrar(nombre: 'Ana', email: 'ana@utb.edu.co', password: 'ClaveSegura1');

    expect(await auth.comprobarVerificacion(), isFalse);
    expect(auth.error, contains('Aún no vemos'));

    repo.verificado = true;
    expect(await auth.comprobarVerificacion(), isTrue);
    expect(auth.mostrarVerificacionPendiente, isFalse);
    expect(auth.aviso, contains('verificado'));
  });

  test('reenviar muestra aviso y luego el límite', () async {
    final repo = _AuthFalso();
    final auth = crear(repo);
    await auth.registrar(nombre: 'Ana', email: 'ana@utb.edu.co', password: 'ClaveSegura1');

    expect(await auth.reenviarVerificacion(), isTrue);
    expect(auth.aviso, contains('spam'));
    await auth.reenviarVerificacion();
    expect(await auth.reenviarVerificacion(), isFalse);
    expect(auth.error, 'Ya te enviamos varios correos.');
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
    final auth = crear(_AuthFalso()..verificado = true);
    expect(await auth.iniciarSesion('ana@utb.edu.co', 'Mala'), isFalse);
    expect(auth.error, 'Usuario, correo o contraseña incorrectos');
    expect(await auth.iniciarSesion('ana@utb.edu.co', 'ClaveSegura1'), isTrue);
    expect(auth.mostrarVerificacionPendiente, isFalse);
  });

  test('cerrar sesión borra los tokens guardados', () async {
    final auth = crear(_AuthFalso()..verificado = true);
    await auth.iniciarSesion('Ana', 'ClaveSegura1');
    auth.cerrarSesion();
    await Future<void>.delayed(Duration.zero);
    expect(auth.autenticado, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'utb_access_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'utb_refresh_token'), isNull);
  });

  test('el parseo tolera servidores viejos sin email_verificado', () {
    final u = UsuarioModel.desdeJson({'id': 1, 'nombre': 'A', 'email': 'a@b.co', 'rol': 'auxiliar'});
    expect(u.emailVerificado, isTrue);
    final n = UsuarioModel.desdeJson(
        {'id': 1, 'nombre': 'A', 'email': 'a@b.co', 'rol': 'usuario_utb', 'email_verificado': false});
    expect(n.emailVerificado, isFalse);
  });
}

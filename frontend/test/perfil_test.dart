import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'catalogo_roles_falso.dart';
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

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

final _perfil = {
  'id': 3,
  'nombre': 'ana',
  'email': 'ana@utb.edu.co',
  'rol': 'auxiliar',
  'permisos': permisosDe('auxiliar').valores.toList(),
  'nombre_mostrar': 'Ana María',
  'telefono': '+57 300 123 4567',
  'dependencia': 'Laboratorios',
  'color_avatar': '#3DDC97',
  'preferencias': {
    'notificaciones': {
      'correo': {'cuenta': false, 'salones': true},
      'push': {'cuenta': true, 'salones': false},
    },
    'tamano_texto': 'grande',
    'pantalla_inicio': 'salones',
  },
};

class _RepoMin implements AuthRepository {
  @override
  Future<Sesion> iniciarSesion(String nombre, String password, {Usuario? conocido}) async =>
      Sesion(token: 'a1', refreshToken: 'r1', usuario: UsuarioModel.desdeJson(_perfil));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('parseo del perfil completo y de las preferencias', () {
    final u = UsuarioModel.desdeJson(_perfil);
    expect(u.nombreVisible, 'Ana María');
    expect(u.telefono, '+57 300 123 4567');
    expect(u.colorAvatar, '#3DDC97');
    final p = u.preferencias;
    expect(p.tamanoTexto, TamanoTexto.grande);
    expect(p.pantallaInicio, 'salones');
    expect(p.aviso(CanalAviso.correo, CategoriaAviso.cuenta), isFalse);
    expect(p.aviso(CanalAviso.push, CategoriaAviso.salones), isFalse);
    expect(p.aviso(CanalAviso.correo, CategoriaAviso.salones), isTrue);
    // Ida y vuelta sin perder nada.
    expect(Preferencias.desdeJson(p.aJson()).aJson(), p.aJson());
  });

  test('sin preferencias guardadas: todo encendido y texto normal', () {
    final u = UsuarioModel.desdeJson({'id': 1, 'nombre': 'x', 'email': 'x@y.co', 'rol': 'usuario_utb'});
    expect(u.preferencias.tamanoTexto, TamanoTexto.normal);
    expect(u.preferencias.aviso(CanalAviso.correo, CategoriaAviso.salones), isTrue);
    expect(u.nombreVisible, 'x');
  });

  test('editar perfil envía solo los cambios y actualiza el usuario', () async {
    late Map<String, dynamic> enviado;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/auth/me');
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({..._perfil, 'telefono': null});
      }),
    );
    final auth = AuthController(_RepoMin(), api, _FcmFalso());
    await auth.iniciarSesion('ana', 'ClaveSegura1');

    expect(await auth.guardarPerfil({'telefono': ''}, avisoOk: 'Datos guardados'), isTrue);
    expect(enviado, {'telefono': ''});
    expect(auth.usuario!.telefono, isNull);
    expect(auth.aviso, 'Datos guardados');
  });

  test('cambiar contraseña adopta los tokens nuevos de este dispositivo', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async => _json({
            'message': 'ok',
            'access_token': 'a2',
            'refresh_token': 'r2',
            'token_type': 'bearer',
          })),
    );
    final auth = AuthController(_RepoMin(), api, _FcmFalso());
    await auth.iniciarSesion('ana', 'ClaveSegura1');

    expect(await auth.cambiarPassword('ClaveSegura1', 'NuevaClave77'), isTrue);
    expect(auth.sesion!.token, 'a2');
    expect(api.refreshToken, 'r2');
    expect(await const FlutterSecureStorage().read(key: 'utb_refresh_token'), 'r2');
    expect(auth.aviso, contains('demás dispositivos'));
  });

  test('contraseña actual incorrecta: error claro y no cambia nada', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => _json({'detail': 'La contraseña actual no es correcta.'}, 403)),
    );
    final auth = AuthController(_RepoMin(), api, _FcmFalso());
    await auth.iniciarSesion('ana', 'ClaveSegura1');

    expect(await auth.cambiarPassword('mala', 'NuevaClave77'), isFalse);
    expect(auth.error, 'La contraseña actual no es correcta.');
    expect(auth.sesion!.token, 'a1');
  });

  test('desactivar la cuenta cierra la sesión', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => _json({'message': 'Tu cuenta quedó desactivada.'})),
    );
    final auth = AuthController(_RepoMin(), api, _FcmFalso());
    await auth.iniciarSesion('ana', 'ClaveSegura1');
    expect(await auth.desactivarCuenta('ClaveSegura1'), isTrue);
    expect(auth.autenticado, isFalse);
  });

  test('cambiar correo llama al endpoint y el correo cambia al instante', () async {
    late Map<String, dynamic> enviado;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        expect(req.url.path, '/auth/me/cambiar-correo');
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({..._perfil, 'email': 'nueva@utb.edu.co'}, 200);
      }),
    );
    final auth = AuthController(_RepoMin(), api, _FcmFalso());
    await auth.iniciarSesion('ana', 'ClaveSegura1');
    expect(await auth.cambiarCorreo(' nueva@utb.edu.co ', 'ClaveSegura1'), isTrue);
    expect(enviado, {'correo_nuevo': 'nueva@utb.edu.co', 'password': 'ClaveSegura1'});
    expect(auth.usuario!.email, 'nueva@utb.edu.co');
  });
}

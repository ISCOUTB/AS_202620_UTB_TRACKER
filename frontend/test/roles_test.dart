import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/di/injection.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/state/carga.dart';
import 'package:utb_tracker_app/core/storage/token_storage.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/core/theme/escala.dart';
import 'package:utb_tracker_app/features/admin/presentation/estadisticas_page.dart';
import 'package:utb_tracker_app/features/admin/presentation/usuarios_page.dart';
import 'package:utb_tracker_app/features/auth/data/auth_data.dart';
import 'package:utb_tracker_app/features/auth/domain/auth_domain.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';
import 'package:utb_tracker_app/features/home/presentation/shell_page.dart';
import 'package:utb_tracker_app/features/salones/domain/entities/salon.dart';
import 'package:utb_tracker_app/features/solicitudes/data/solicitudes_data.dart';
import 'package:utb_tracker_app/features/solicitudes/presentation/solicitudes_controller.dart';
import 'package:utb_tracker_app/features/solicitudes/presentation/solicitudes_pages.dart';
import 'package:utb_tracker_app/shared/sin_acceso.dart';

/// Roles y permisos en la app (ADR-0018): la navegación sale de los permisos de /auth/me, el
/// modo prueba cambia lo que se ve sin cambiar el rol real, y las pantallas nuevas manejan
/// datos, vacío, error y "sin acceso" sin desbordarse a 360 dp.

Map<String, dynamic> _usuario(int id, String nombre, String rol) => {
      'id': id,
      'nombre': nombre,
      'email': '${nombre.split(' ').first.toLowerCase()}@utb.edu.co',
      'rol': rol,
      'rol_etiqueta': RolUsuario.etiqueta(rol),
      'permisos': Permisos.deRol(rol).valores.toList(),
      'email_verificado': true,
    };

final _estudiante = _usuario(1, 'Estudiante Demo', RolUsuario.estudiante);
final _auditor = _usuario(2, 'Auditor Demo', RolUsuario.auditor);
final _admin = _usuario(3, 'Admin Demo', RolUsuario.administrador);

Map<String, dynamic> _solicitud(int id, String estado,
        {String? respuesta, String? conflicto, String? atendido}) =>
    {
      'id': id,
      'salon_id': id,
      'usuario_id': 1,
      'fecha_inicio': '2030-01-07T15:00:00',
      'fecha_fin': '2030-01-07T16:00:00',
      'motivo': 'Sustentación del proyecto final de ingeniería de software',
      'estado': estado,
      'created_at': '2030-01-01T10:00:00',
      'salon_nombre': 'A4-30$id',
      'usuario_nombre': 'María Fernanda de los Ángeles Rodríguez Villalobos',
      'respuesta': respuesta,
      'atendido_por_nombre': atendido,
      'atendido_en': atendido == null ? null : DateTime.now().toUtc().toIso8601String(),
      'conflicto': conflicto,
    };

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

late Map<String, dynamic> _sesionDe;

Future<http.Response> _servidor(http.Request req) async {
  final ruta = req.url.path;
  if (ruta == '/salud') return _json({'status': 'ok'});
  if (ruta == '/auth/login') {
    return _json({'access_token': 'a', 'refresh_token': 'r', 'token_type': 'bearer', 'user': _sesionDe});
  }
  if (ruta == '/auth/me') return _json(_sesionDe);
  if (ruta == '/prestamos-salon/mias') {
    return _json([
      _solicitud(1, 'pendiente'),
      _solicitud(2, 'rechazado', respuesta: 'Sin cupo ese día', atendido: 'Auditor Demo'),
      _solicitud(3, 'aprobado', atendido: 'Auditor Demo'),
    ]);
  }
  if (ruta == '/prestamos-salon/gestion') {
    if (_sesionDe['rol'] == RolUsuario.estudiante) return _json({'detail': 'No'}, 403);
    return _json([
      _solicitud(4, 'pendiente', conflicto: 'la clase Cálculo (09:00-12:00)'),
      _solicitud(5, 'pendiente'),
    ]);
  }
  if (ruta == '/usuarios') {
    if (_sesionDe['rol'] != RolUsuario.administrador) return _json({'detail': 'No'}, 403);
    return _json([
      for (final u in [_estudiante, _auditor, _admin])
        {...u, 'activo': true, 'ultima_actividad': '2030-01-01T10:00:00'},
    ]);
  }
  if (ruta == '/stats/admin') {
    return _json({
      'dias': 30,
      'usuarios_activos_por_rol': [
        {'rol': 'usuario_utb', 'etiqueta': 'Estudiante', 'total': 12},
        {'rol': 'auxiliar', 'etiqueta': 'Auditor', 'total': 2},
        {'rol': 'administrador', 'etiqueta': 'Administrador', 'total': 1},
      ],
      'usuarios_inactivos': 1,
      'solicitudes_por_estado': {'pendiente': 3, 'aprobado': 7, 'rechazado': 2},
      'salones_mas_solicitados': [
        {'salon': 'LAB-SIS1', 'total': 6},
        {'salon': 'AUD-CT', 'total': 4},
      ],
      'salones_por_tipo': {'aula': 9, 'laboratorio_computo': 1},
      'reportes_salon_por_estado': {'abierto': 2, 'resuelto': 5},
      'reportes_salon_por_tipo': {'equipo': 4, 'limpieza': 3},
    });
  }
  return _json([]);
}

Future<void> _preparar(Map<String, dynamic> usuario) async {
  _sesionDe = usuario;
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(_servidor)),
  );
  await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
}

Future<void> _pintar(WidgetTester tester, Widget pagina, {double sistema = 1.3}) async {
  tester.view.physicalSize = const Size(360 * 3, 740 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = sistema;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.oscuro,
    builder: (context, child) =>
        EscalaGlobal(tamanoTexto: TamanoTexto.extraGrande, child: child!),
    home: pagina,
  ));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Etiquetas visibles de la barra inferior, en orden.
List<String> _pestanas(WidgetTester tester) => [
      for (final s in tester.widgetList<Semantics>(find.descendant(
          of: find.byType(BarraInferior), matching: find.byType(Semantics))))
        if (s.properties.button ?? false) s.properties.label!,
    ];

class _RepoFalso implements SolicitudesRepository {
  _RepoFalso(this.error);
  final Object error;
  @override
  Future<List<PrestamoSalon>> mias() async => throw error;
  @override
  Future<List<PrestamoSalon>> bandeja({String estado = 'pendiente'}) async => throw error;
  @override
  Future<PrestamoSalon> aprobar(int id, {String? nota}) async => throw error;
  @override
  Future<PrestamoSalon> cancelar(int id) async => throw error;
  @override
  Future<PrestamoSalon> rechazar(int id, String motivo) async => throw error;
}

void main() {
  group('Permisos (espejo de app/core/permisos.py)', () {
    test('cada rol tiene exactamente los permisos del servidor', () {
      final est = Permisos.deRol(RolUsuario.estudiante);
      final aud = Permisos.deRol(RolUsuario.auditor);
      final adm = Permisos.deRol(RolUsuario.administrador);
      expect(est.valores.length, 6);
      expect(aud.valores.length, 12);
      expect(adm.valores.length, 17); // + salones.crear_catalogo (ADR-0021)
      expect(est.puede(Permisos.salonesSolicitar), isTrue);
      expect(est.puede(Permisos.solicitudesGestionar), isFalse);
      expect(aud.puede(Permisos.solicitudesGestionar), isTrue);
      expect(aud.puede(Permisos.usuariosGestionar), isFalse);
      expect(aud.puede(Permisos.auditoriaVer), isFalse);
      expect(adm.puede(Permisos.modoPrueba), isTrue);
      expect(Permisos.deRol('desconocido').valores, isEmpty);
    });

    test('usa la lista del servidor y, si no viene, la calcula del rol', () {
      final conLista = UsuarioModel.desdeJson({..._estudiante, 'permisos': ['salones.ver']});
      expect(conLista.permisos.valores, {'salones.ver'});
      final sinLista = UsuarioModel.desdeJson(
          {'id': 9, 'nombre': 'Viejo', 'email': 'v@utb.edu.co', 'rol': 'auxiliar'});
      expect(sinLista.permisos.puede(Permisos.solicitudesGestionar), isTrue);
      expect(sinLista.rolEtiqueta, 'Auditor');
    });

    test('la barra inferior sale de los permisos', () {
      expect(pestanasPara(Permisos.deRol(RolUsuario.estudiante)),
          [Pestana.inicio, Pestana.salones, Pestana.solicitudes, Pestana.perfil]);
      final operacion = [Pestana.inicio, Pestana.salones, Pestana.solicitudes, Pestana.control,
        Pestana.equipos, Pestana.perfil];
      expect(pestanasPara(Permisos.deRol(RolUsuario.auditor)), operacion);
      expect(pestanasPara(Permisos.deRol(RolUsuario.administrador)), operacion);
    });
  });

  group('Modo prueba (solo interfaz)', () {
    test('el administrador ve la app como estudiante sin perder sus permisos reales', () async {
      await _preparar(_admin);
      final auth = sl<AuthController>();
      await auth.verComo(RolUsuario.estudiante);
      expect(auth.vistaComo, RolUsuario.estudiante);
      expect(auth.permisos.puede(Permisos.solicitudesGestionar), isFalse);
      expect(auth.permisosReales.puede(Permisos.usuariosGestionar), isTrue);
      expect(await TokenStorage.leerVistaComo(), RolUsuario.estudiante); // solo en el dispositivo
      await auth.verComo(null);
      expect(auth.vistaComo, isNull);
      expect(auth.permisos.puede(Permisos.usuariosGestionar), isTrue);
    });

    test('un estudiante no puede activarlo', () async {
      await _preparar(_estudiante);
      final auth = sl<AuthController>();
      await auth.verComo(RolUsuario.administrador);
      expect(auth.vistaComo, isNull);
      expect(auth.permisos.puede(Permisos.usuariosGestionar), isFalse);
    });
  });

  group('Sin acceso', () {
    test('un 403 marca "sin acceso" y vuelve a leer el perfil', () async {
      var refrescos = 0;
      final c = SolicitudesController(
        _RepoFalso(ApiException(TipoError.prohibido, 'No', statusCode: 403)),
        bandeja: true,
        onSinPermiso: () async => refrescos++,
      );
      await c.cargar();
      expect(c.sinAcceso, isTrue);
      expect(c.carga, Carga.ok);
      expect(refrescos, 1);
    });

    test('otros errores muestran el error, no "sin acceso"', () async {
      final c = SolicitudesController(
        _RepoFalso(ApiException(TipoError.servidor, 'Se cayó', statusCode: 500)),
        bandeja: false,
        onSinPermiso: () async {},
      );
      await c.cargar();
      expect(c.sinAcceso, isFalse);
      expect(c.carga, Carga.error);
      expect(c.error, 'Se cayó');
    });

    testWidgets('el auditor no entra a Usuarios: pantalla amable', (tester) async {
      await _preparar(_auditor);
      await _pintar(tester, const UsuariosPage());
      expect(tester.takeException(), isNull);
      expect(find.text('No tienes acceso a esto'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('el estudiante no entra a la bandeja', (tester) async {
      await _preparar(_estudiante);
      await _pintar(tester, const Scaffold(body: BandejaSolicitudesPage()));
      expect(find.byType(SinAcceso), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Navegación por rol a 360 dp con texto grande', () {
    testWidgets('Estudiante: 4 pestañas y Mis solicitudes con motivo del rechazo',
        (tester) async {
      await _preparar(_estudiante);
      await _pintar(tester, const ShellPage());
      expect(tester.takeException(), isNull);
      expect(_pestanas(tester), ['Inicio', 'Salones', 'Solicitudes', 'Perfil']);
      await tester.tap(find.text('Solicitudes').last);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('Motivo: Sin cupo ese día'), findsOneWidget);
      expect(find.text('Cancelar solicitud'), findsOneWidget); // solo la pendiente
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Auditor: 6 pestañas y bandeja con el conflicto visible', (tester) async {
      await _preparar(_auditor);
      await _pintar(tester, const ShellPage());
      expect(tester.takeException(), isNull);
      expect(_pestanas(tester),
          ['Inicio', 'Salones', 'Solicitudes', 'Control', 'Equipos', 'Perfil']);
      await tester.tap(find.text('Solicitudes').last);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Choca con la clase Cálculo'), findsOneWidget);
      // La que choca no se puede aprobar; la libre sí.
      expect(find.text('Aprobar'), findsOneWidget);
      expect(find.text('Rechazar'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Rechazar exige escribir el motivo', (tester) async {
      await _preparar(_auditor);
      await _pintar(tester, const Scaffold(body: BandejaSolicitudesPage()), sistema: 1.0);
      await tester.ensureVisible(find.text('Rechazar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rechazar').first);
      await tester.pumpAndSettle();
      final boton = find.widgetWithText(FilledButton, 'Rechazar');
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'Sin cupo');
      await tester.pump();
      expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Administrador en modo prueba: franja visible y navegación de Estudiante',
        (tester) async {
      await _preparar(_admin);
      await sl<AuthController>().verComo(RolUsuario.estudiante);
      await _pintar(tester, const ShellPage());
      expect(tester.takeException(), isNull);
      expect(find.text('Viendo como Estudiante'), findsOneWidget);
      expect(_pestanas(tester), ['Inicio', 'Salones', 'Solicitudes', 'Perfil']);
      await tester.tap(find.text('Salir'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Viendo como Estudiante'), findsNothing);
      expect(_pestanas(tester).length, 6);
      expect(sl<AuthController>().usuario!.rol, RolUsuario.administrador); // rol real intacto
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Pantallas del administrador', () {
    testWidgets('Usuarios: lista con etiqueta de rol y la cuenta propia marcada', (tester) async {
      await _preparar(_admin);
      await _pintar(tester, const UsuariosPage());
      expect(tester.takeException(), isNull);
      expect(find.text('Auditor'), findsWidgets);
      expect(find.text('Admin Demo (tú)'), findsOneWidget);
      // En la hoja de la propia cuenta no se ofrece cambiar el rol.
      await tester.tap(find.text('Admin Demo (tú)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Es tu cuenta'), findsOneWidget);
      expect(find.text('Desactivar cuenta'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Estadísticas: cifras reales del servidor', (tester) async {
      await _preparar(_admin);
      await _pintar(tester, const EstadisticasPage());
      expect(tester.takeException(), isNull);
      expect(find.text('12 en el periodo'), findsOneWidget);
      expect(find.text('LAB-SIS1'), findsOneWidget);
      expect(find.textContaining('Estudiante: 12'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'catalogo_roles_falso.dart';
import 'package:utb_tracker_app/core/di/injection.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';
import 'package:utb_tracker_app/features/admin/data/admin_data.dart';
import 'package:utb_tracker_app/features/admin/presentation/admin_controllers.dart';
import 'package:utb_tracker_app/features/admin/presentation/asignaciones_page.dart';

/// ADR-0024: pantalla "Cargar roles" del administrador (solo cuentas existentes).
class _RepoFalso implements AdminRepository {
  final importaciones = <(String, bool)>[];
  ResultadoImportacion respuesta = const ResultadoImportacion(
    validas: 1,
    actualizadas: 0,
    sinCambios: 0,
    sinCuenta: 0,
    correosSinCuenta: [],
    errores: [(2, 'Usa tu correo institucional de la UTB (termina en @utb.edu.co)')],
    aplicado: false,
  );

  @override
  Future<ResultadoImportacion> importarAsignaciones(String texto, {bool simular = false}) async {
    importaciones.add((texto, simular));
    return respuesta;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _admin = {
  'id': 1,
  'nombre': 'admin',
  'email': 'admin@utb.edu.co',
  'rol': 'administrador',
  'permisos': permisosDe('administrador').valores.toList(),
};

Future<http.Response> _servidor(http.Request req) async {
  final cuerpo = req.url.path == '/auth/login'
      ? {'access_token': 'a', 'refresh_token': 'r', 'token_type': 'bearer', 'user': _admin}
      : _admin;
  return http.Response(jsonEncode(cuerpo), 200, headers: {'content-type': 'application/json'});
}

Future<void> _pintar(WidgetTester tester, Widget pagina) async {
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(_servidor)),
  );
  await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
  tester.view.physicalSize = const Size(360 * 3, 760 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.oscuro, home: pagina));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('explica que nadie recibe un rol por registrarse', (tester) async {
    await _pintar(tester, AsignacionesPage(controller: AsignacionesController(_RepoFalso())));
    expect(find.text('Cargar roles'), findsOneWidget);
    expect(find.textContaining('todas las cuentas nuevas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('importar: revisa primero y muestra errores por línea sin aplicar',
      (tester) async {
    final repo = _RepoFalso();
    await _pintar(tester, AsignacionesPage(controller: AsignacionesController(repo)));
    await tester.tap(find.text('Cargar lista'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'ana@utb.edu.co,Auditor\nmalo@gmail.com,Auditor');
    await tester.pump();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    expect(repo.importaciones.single.$2, isTrue, reason: 'primero simula');
    expect(find.textContaining('No se guardó nada'), findsOneWidget);
    expect(find.textContaining('Línea 2:'), findsOneWidget);
    expect(find.text('Aplicar roles'), findsNothing);
  });

  testWidgets('la vista previa lista los correos sin cuenta y permite aplicar', (tester) async {
    final repo = _RepoFalso()
      ..respuesta = const ResultadoImportacion(
        validas: 2,
        actualizadas: 1,
        sinCambios: 0,
        sinCuenta: 1,
        correosSinCuenta: ['fantasma@utb.edu.co'],
        errores: [],
        aplicado: false,
      );
    await _pintar(tester, AsignacionesPage(controller: AsignacionesController(repo)));
    await tester.tap(find.text('Cargar lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ana@utb.edu.co,Auditor');
    await tester.pump();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 sin cuenta'), findsOneWidget);
    expect(find.textContaining('fantasma@utb.edu.co'), findsOneWidget);
    expect(find.text('Aplicar roles'), findsOneWidget);
  });
}

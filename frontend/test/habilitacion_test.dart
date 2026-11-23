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
import 'package:utb_tracker_app/features/salones/data/salones_data.dart';
import 'package:utb_tracker_app/features/salones/presentation/salones_page.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/disponibilidad.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/salon_control_page.dart';

/// ADR-0022 (Fase 5): habilitación separada de la ocupación, equipos y su estado.
Map<String, dynamic> _salon(int id, String nombre,
        {bool habilitado = true, String estado = 'disponible', String? aviso}) =>
    {
      'id': id,
      'nombre': nombre,
      'ubicacion': 'Edificio A1, piso 1',
      'edificio': 'A1',
      'piso': 1,
      'capacidad': 40,
      'estado': estado,
      'tipo': 'aula',
      'habilitado': habilitado,
      'motivo_deshabilitado': habilitado ? null : 'mantenimiento',
      'aviso_deshabilitado': aviso,
      'ocupado_ahora': estado == 'ocupado',
      'equipamiento': [
        {'categoria': 'video_beam', 'total': 1, 'operativos': 1},
      ],
    };

class _Servidor {
  _Servidor(this.rol);
  final String rol;
  final pedidos = <(String, String, Object?)>[];

  Map<String, dynamic> get _usuario => {
        'id': 1,
        'nombre': 'Prueba',
        'email': 'prueba@utb.edu.co',
        'rol': rol,
        'permisos': permisosDe(rol).valores.toList(),
      };

  Future<http.Response> responder(http.Request req) async {
    final cuerpoPedido = req.body.isEmpty ? null : jsonDecode(req.body);
    pedidos.add((req.method, req.url.path, cuerpoPedido));
    final Object cuerpo = switch ((req.method, req.url.path)) {
      ('POST', '/auth/login') => {
          'access_token': 'a',
          'refresh_token': 'r',
          'token_type': 'bearer',
          'user': _usuario,
        },
      ('GET', '/salones') => [
          _salon(1, 'A1-101', estado: 'ocupado'),
          _salon(2, 'A1-102',
              habilitado: false,
              estado: 'mantenimiento',
              aviso: 'Deshabilitado: Mantenimiento (pintura).'),
        ],
      ('GET', '/salones/1/ocupacion') => {
          'salon': _salon(1, 'A1-101'),
          'ocupante': 'libre',
          'solicitudes_pendientes': 0,
          'reportes_abiertos': 0,
        },
      ('GET', '/recursos') => [
          {'id': 5, 'categoria': 'video_beam', 'serial': 'A1-101-VB-01', 'estado': 'disponible'},
        ],
      ('GET', '/salones/1/historial') => [
          {
            'id': 1,
            'accion': 'deshabilitado',
            'descripcion': 'Deshabilitado: Evento (Feria)',
            'actor_nombre': 'Admin',
            'creado_en': '2026-11-10T15:00:00',
          },
        ],
      ('PATCH', '/salones/1/habilitacion') => {
          'salon': _salon(1, 'A1-101', habilitado: false, estado: 'mantenimiento'),
          'solicitudes_afectadas': [],
        },
      ('PATCH', '/recursos/5/estado') => {
          'recurso': {'id': 5, 'categoria': 'video_beam', 'serial': 'A1-101-VB-01', 'estado': 'dañado'},
          'sugerir_reporte': true,
          'reportes_equipo_abiertos': [],
        },
      _ => <dynamic>[],
    };
    return http.Response(jsonEncode(cuerpo), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  }
}

Future<_Servidor> _pintar(WidgetTester tester, Widget pagina, {String rol = 'auxiliar'}) async {
  final servidor = _Servidor(rol);
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(servidor.responder)),
  );
  await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
  tester.view.physicalSize = const Size(360 * 3, 760 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.oscuro, home: pagina));
  await tester.pumpAndSettle();
  return servidor;
}

void main() {
  test('un servidor viejo (sin `habilitado`) se interpreta por el estado de siempre', () {
    final viejo = SalonModel.desdeJson({
      'id': 1,
      'nombre': 'A1-201',
      'ubicacion': 'x',
      'capacidad': 30,
      'estado': 'mantenimiento',
    });
    expect(viejo.habilitado, isFalse);
    expect(viejo.solicitable, isFalse);
    final ocupado = SalonModel.desdeJson(
        {'id': 2, 'nombre': 'A1-202', 'ubicacion': 'x', 'capacidad': 30, 'estado': 'ocupado'});
    expect(ocupado.solicitable, isTrue, reason: 'ocupado AHORA se pide para otra hora');
    expect(EstadoEquipo.desde('prestado'), EstadoEquipo.operativo);
  });

  testWidgets('detalle del auditor: habilitación, equipos e historial sin desbordes',
      (tester) async {
    await _pintar(tester, const SalonControlPage(salonId: 1));
    expect(find.text('Habilitado'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Operativo'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Operativo'), findsOneWidget, reason: 'estado con texto, no solo color');
    await tester.scrollUntilVisible(find.text('Deshabilitado: Evento (Feria)'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Deshabilitado: Evento (Feria)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deshabilitar exige motivo antes de enviar', (tester) async {
    final servidor = await _pintar(tester, const SalonControlPage(salonId: 1));
    await tester.tap(find.text('Deshabilitar'));
    await tester.pumpAndSettle();
    final boton = find.widgetWithText(FilledButton, 'Deshabilitar');
    expect(tester.widget<FilledButton>(boton).onPressed, isNull, reason: 'sin motivo');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Mantenimiento'));
    await tester.pump();
    expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
    await tester.tap(boton);
    await tester.pumpAndSettle();
    final patch = servidor.pedidos.firstWhere((p) => p.$1 == 'PATCH');
    expect(patch.$2, '/salones/1/habilitacion');
    expect((patch.$3! as Map)['motivo'], 'mantenimiento');
    expect(find.text('A1-101 deshabilitado'), findsOneWidget);
  });

  testWidgets('marcar un equipo dañado sugiere un reporte (no lo abre solo)', (tester) async {
    final servidor = await _pintar(tester, const SalonControlPage(salonId: 1));
    await tester.scrollUntilVisible(find.text('Operativo'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operativo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dañado').last);
    await tester.pumpAndSettle();
    expect(servidor.pedidos.any((p) => p.$1 == 'PATCH' && p.$2 == '/recursos/5/estado'), isTrue);
    expect(find.text('¿Registrar el daño?'), findsOneWidget);
    expect(servidor.pedidos.any((p) => p.$2.endsWith('/reportes') && p.$1 == 'POST'), isFalse);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
  });

  testWidgets('estudiante: deshabilitado con motivo y sin "Solicitar"; ocupado sí se pide',
      (tester) async {
    await _pintar(tester, const SalonesPage(), rol: 'usuario_utb');
    expect(find.text('Deshabilitado: Mantenimiento (pintura).'), findsOneWidget);
    expect(find.text('Ocupado ahora'), findsOneWidget);
    expect(find.byTooltip('Solicitar'), findsOneWidget, reason: 'solo el ocupado ahora');
    expect(tester.takeException(), isNull);
  });
}

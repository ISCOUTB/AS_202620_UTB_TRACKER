import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/di/injection.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/features/auth/domain/permisos.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/catalogo.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/catalogo_page.dart';

/// ADR-0021 (Fase 4): catálogo de salones UTB del administrador.
Map<String, dynamic> _salon(int id, String nombre, String edificio, int piso) => {
      'id': id,
      'nombre': nombre,
      'ubicacion': 'Edificio $edificio, piso $piso',
      'edificio': edificio,
      'piso': piso,
      'capacidad': 40,
      'capacidad_estimada': true,
      'estado': 'disponible',
      'tipo': 'aula',
    };

class _Servidor {
  _Servidor(this.rol);
  final String rol;
  final pedidos = <String>[];

  Map<String, dynamic> get _usuario => {
        'id': 1,
        'nombre': 'Prueba',
        'email': 'prueba@utb.edu.co',
        'rol': rol,
        'email_verificado': true,
      };

  Future<http.Response> responder(http.Request req) async {
    pedidos.add('${req.method} ${req.url.path}');
    final Object cuerpo = switch ((req.method, req.url.path)) {
      ('POST', '/auth/login') => {
          'access_token': 'a',
          'refresh_token': 'r',
          'token_type': 'bearer',
          'user': _usuario,
        },
      ('GET', '/salones') => [
          _salon(3, 'A2-201', 'A2', 2),
          _salon(1, 'A1-102', 'A1', 1),
          _salon(2, 'A1-101', 'A1', 1),
        ],
      ('GET', '/salones/catalogo/fuera') => [
          {
            'id': 9,
            'nombre': 'ALC-201',
            'tiene_historial': true,
            'problema': 'No sigue el formato A1-101 (espacio especial o dato viejo).',
            'propuesta': 'Dejarlo como espacio especial o renombrarlo; tiene historial, no borrar.',
          },
        ],
      ('POST', '/salones/catalogo/rango/vista-previa') => {
          'edificio': 'A1',
          'piso': 1,
          'ubicacion': 'Edificio A1, piso 1',
          'nuevos': ['A1-103', 'A1-104', 'A1-105'],
          'existentes': ['A1-101', 'A1-102'],
        },
      ('POST', '/salones/catalogo/rango') => {
          'edificio': 'A1',
          'piso': 1,
          'ubicacion': 'Edificio A1, piso 1',
          'nuevos': ['A1-103', 'A1-104', 'A1-105'],
          'existentes': ['A1-101', 'A1-102'],
          'creados': ['A1-103', 'A1-104', 'A1-105'],
        },
      _ => _usuario,
    };
    final codigo = req.method == 'POST' && req.url.path == '/salones/catalogo/rango' ? 201 : 200;
    return http.Response(jsonEncode(cuerpo), codigo,
        headers: {'content-type': 'application/json; charset=utf-8'});
  }
}

Future<_Servidor> _pintar(WidgetTester tester, {String rol = 'administrador'}) async {
  final servidor = _Servidor(rol);
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(servidor.responder)),
  );
  await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
  tester.view.physicalSize = const Size(360 * 3, 760 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.oscuro, home: const CatalogoPage()));
  await tester.pumpAndSettle();
  return servidor;
}

void main() {
  group('regla del código (espejo de app/services/catalogo.py)', () {
    test('válidos y sus partes', () {
      expect(errorCodigo('A1-101'), isNull);
      expect(errorCodigo(' a2-505 '), isNull);
      final p = partesCodigo('a2-505')!;
      expect((p.edificio, p.piso, p.numero), ('A2', 5, 5));
    });

    test('inválidos', () {
      for (final malo in ['A1-1011', 'A12-101', 'A1101', 'B1-101']) {
        expect(errorCodigo(malo), isNotNull, reason: malo);
      }
      expect(errorCodigo('A1-100'), contains('00'));
    });

    test('rango y orden natural', () {
      expect(codigosDeRango(2, 5, 1, 3), ['A2-501', 'A2-502', 'A2-503']);
      final l = ['A2-201', 'Auditorio', 'A1-201', 'A1-102', 'A1-101']..sort(compararCodigos);
      expect(l, ['A1-101', 'A1-102', 'A1-201', 'A2-201', 'Auditorio']);
    });

    test('solo el administrador tiene el permiso del catálogo', () {
      expect(Permisos.deRol('administrador').puede(Permisos.salonesCrearCatalogo), isTrue);
      expect(Permisos.deRol('auxiliar').puede(Permisos.salonesCrearCatalogo), isFalse);
      expect(Permisos.deRol('usuario_utb').puede(Permisos.salonesCrearCatalogo), isFalse);
    });
  });

  testWidgets('lista en orden natural, marca la capacidad estimada y el reporte', (tester) async {
    await _pintar(tester);
    expect(find.text('Catálogo de salones'), findsOneWidget);
    final y101 = tester.getTopLeft(find.text('A1-101')).dy;
    final y102 = tester.getTopLeft(find.text('A1-102')).dy;
    final y201 = tester.getTopLeft(find.text('A2-201')).dy;
    expect(y101 < y102 && y102 < y201, isTrue);
    expect(find.textContaining('(estimado)'), findsNWidgets(3));
    expect(find.text('1 fuera del catálogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtro por edificio y piso', (tester) async {
    await _pintar(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'A2'));
    await tester.pumpAndSettle();
    expect(find.text('A1-101'), findsNothing);
    expect(find.text('A2-201'), findsOneWidget);
  });

  testWidgets('crear uno valida en vivo', (tester) async {
    await _pintar(tester);
    await tester.tap(find.text('Crear uno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'A1-1011');
    await tester.pump();
    expect(find.textContaining('Usa la forma A1-101'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'a2-503');
    await tester.pump();
    expect(find.text('Edificio A2, piso 5, salón 03'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crear varios: primero vista previa, luego confirma', (tester) async {
    final servidor = await _pintar(tester);
    await tester.tap(find.text('Crear varios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver vista previa'));
    await tester.pumpAndSettle();
    expect(servidor.pedidos, contains('POST /salones/catalogo/rango/vista-previa'));
    expect(servidor.pedidos, isNot(contains('POST /salones/catalogo/rango')));
    expect(find.text('Se crearán 3'), findsOneWidget);
    expect(find.textContaining('Ya existen (no se tocan): A1-101, A1-102'), findsOneWidget);
    await tester.tap(find.text('Confirmar: crear 3'));
    await tester.pumpAndSettle();
    expect(servidor.pedidos, contains('POST /salones/catalogo/rango'));
    expect(find.text('3 salones creados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el auditor ve "No tienes acceso"', (tester) async {
    await _pintar(tester, rol: 'auxiliar');
    expect(find.textContaining('No tienes acceso'), findsOneWidget);
    expect(find.text('Crear varios'), findsNothing);
  });
}

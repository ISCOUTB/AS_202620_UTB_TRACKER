import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/di/injection.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/core/utils/politica.dart';
import 'package:utb_tracker_app/features/auth/presentation/cambiar_correo_sheet.dart';
import 'package:utb_tracker_app/features/auth/presentation/login_page.dart';

/// ADR-0019 (Fase 1): la app aplica la MISMA regla del servidor antes de enviar.

var _peticiones = <String>[];

Future<http.Response> _servidor(http.Request req) async {
  _peticiones.add(req.url.path);
  return http.Response(jsonEncode({'status': 'ok'}), 200,
      headers: {'content-type': 'application/json'});
}

Future<void> _preparar() async {
  _peticiones = [];
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(_servidor)),
  );
}

void main() {
  group('regla de correo nuevo (espejo de app/core/politica.py)', () {
    const solo = ['utb.edu.co'];

    test('sin configuración solo admite utb.edu.co', () {
      expect(Politica.leerDominios(''), ['utb.edu.co']);
      expect(Politica.leerDominios(' utb.edu.co, @Example.com,utb.edu.co'),
          ['utb.edu.co', 'example.com']);
      expect(Politica.dominiosPermitidos, ['utb.edu.co']);
    });

    test('válidos', () {
      for (final c in ['mmillan@utb.edu.co', 'ana.perez@utb.edu.co', 'USUARIO@UTB.EDU.CO ']) {
        expect(Politica.errorCorreoNuevo(c, dominios: solo), isNull, reason: c);
      }
    });

    test('tramposos con el mismo mensaje que el servidor', () {
      const noInst = Politica.msgCorreoNoInstitucional;
      const malo = Politica.msgCorreoInvalido;
      final casos = {
        'persona@gmail.com': noInst,
        'usuario@utb.edu.co.malo.com': noInst,
        'usuario@estudiantes.utb.edu.co': noInst,
        'usuario@utb.edu.co@otro.com': malo,
        '@utb.edu.co': malo,
        '.ana@utb.edu.co': malo,
        'ana..perez@utb.edu.co': malo,
        'ana!@utb.edu.co': malo,
        'añá@utb.edu.co': malo,
      };
      casos.forEach((correo, msg) {
        expect(Politica.errorCorreoNuevo(correo, dominios: solo), msg, reason: correo);
      });
      expect(noInst, 'Usa tu correo institucional de la UTB (termina en @utb.edu.co)');
    });
  });

  testWidgets('registro: rechaza gmail antes de enviar y muestra el ejemplo', (tester) async {
    await _preparar();
    tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.oscuro, home: const LoginPage()));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('¿Eres nuevo? Crea tu cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Ejemplo: usuario@utb.edu.co'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana Pérez');
    await tester.enterText(campos.at(1), 'ana@gmail.com');
    await tester.enterText(campos.at(2), 'ClaveSegura1');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();
    expect(find.text(Politica.msgCorreoNoInstitucional), findsOneWidget);
    expect(_peticiones.where((p) => p == '/auth/register'), isEmpty);
  });

  testWidgets('cambio de correo: solo institucional', (tester) async {
    await _preparar();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.oscuro,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
              onPressed: () => mostrarCambiarCorreo(context), child: const Text('abrir')),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ejemplo: usuario@utb.edu.co'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'yo@utb.edu.co.malo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'ClaveSegura1');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(find.text(Politica.msgCorreoNoInstitucional), findsOneWidget);
    expect(_peticiones.where((p) => p.contains('cambiar-correo')), isEmpty);
  });
}

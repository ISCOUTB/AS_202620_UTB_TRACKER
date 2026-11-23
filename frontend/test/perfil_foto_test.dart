import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utb_tracker_app/core/di/injection.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/core/theme/escala.dart';
import 'package:utb_tracker_app/features/auth/domain/preferencias.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';
import 'package:utb_tracker_app/features/cuenta/presentation/cuenta_page.dart';
import 'package:utb_tracker_app/features/cuenta/presentation/foto_perfil_sheet.dart';

/// ADR-0019/0020 (Fases 3 y 4): perfil con rol de solo lectura, aviso de correo antiguo, foto
/// de perfil (con y sin foto, hoja con estados) y sin desbordes a 360 dp.

final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

late Map<String, dynamic> _perfil;
var _peticiones = <String>[];
var _respuestaFoto = 200;

Map<String, dynamic> _usuario({
  bool foto = false,
  bool institucional = true,
  String origen = 'correo',
  String? cargo = 'Auxiliar de planta',
  String nombre = 'Ana Pérez',
}) =>
    {
      'id': 7,
      'nombre': 'ana',
      'nombre_mostrar': nombre,
      'email': institucional ? 'ana.perez@utb.edu.co' : 'ana.perez.antigua@gmail.com',
      'rol': 'auxiliar',
      'rol_etiqueta': 'Auditor',
      'email_verificado': true,
      'correo_institucional': institucional,
      'rol_origen': origen,
      'rol_origen_texto': origen == 'correo' ? 'Asignado por tu correo institucional' : null,
      'cargo': cargo,
      'tiene_foto': foto,
      'foto_version': foto ? 1700000000000 : 0,
      'permisos': ['salones.ver', 'solicitudes.gestionar'],
    };

Future<http.Response> _servidor(http.Request req) async {
  final ruta = req.url.path;
  _peticiones.add('${req.method} $ruta');
  http.Response json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo), status,
      headers: {'content-type': 'application/json; charset=utf-8'});
  if (ruta == '/auth/login') {
    return json({'access_token': 'a', 'refresh_token': 'r', 'token_type': 'bearer', 'user': _perfil});
  }
  if (ruta == '/auth/me') return json(_perfil);
  if (ruta == '/auth/me/foto' && req.method == 'GET') {
    return http.Response.bytes(_png, 200, headers: {'content-type': 'image/png'});
  }
  if (ruta == '/auth/me/foto' && req.method == 'PUT') {
    if (_respuestaFoto != 200) {
      return json({'detail': 'Solo se aceptan fotos JPEG o PNG.'}, _respuestaFoto);
    }
    return json({'tiene_foto': true, 'foto_version': 1800000000000});
  }
  if (ruta == '/auth/me/foto' && req.method == 'DELETE') {
    return json({'tiene_foto': false, 'foto_version': 0});
  }
  if (ruta == '/salud') return json({'status': 'ok'});
  return json([]);
}

Future<void> _preparar(Map<String, dynamic> perfil) async {
  _perfil = perfil;
  _peticiones = [];
  _respuestaFoto = 200;
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
      api: ApiClient(baseUrl: 'http://x', client: MockClient(_servidor)));
  await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
}

Future<void> _pintar(WidgetTester tester, Widget pagina,
    {double sistema = 1.0, double alto = 1600}) async {
  tester.view.physicalSize = Size(360 * 3, alto * 3);
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
}

/// Abre la hoja de foto con un selector falso.
Future<void> _abrirHoja(WidgetTester tester, ElegirImagen elegir) async {
  await _pintar(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => mostrarHojaFoto(context, elegir: elegir, hayCamara: true),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('perfil', () {
    testWidgets('rol de solo lectura con origen y cargo, sin selector de rol', (tester) async {
      await _preparar(_usuario());
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      expect(find.text('TU ROL'), findsOneWidget);
      expect(find.text('Asignado por tu correo institucional'), findsOneWidget);
      expect(find.text('Auxiliar de planta'), findsWidgets);
      // El rol no se elige: no hay radios ni botones de rol en el perfil.
      expect(find.byIcon(Icons.radio_button_off_rounded), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      // La dependencia no se edita si viene asignada.
      expect(find.text('Dependencia o cargo'), findsNothing);
      expect(find.text('Tu correo no es institucional'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('estudiante sin asignación ve cómo pedir el cambio', (tester) async {
      await _preparar(_usuario(origen: 'base', cargo: null)..['rol_etiqueta'] = 'Estudiante');
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      expect(find.textContaining('pídeselo a un administrador'), findsOneWidget);
      expect(find.text('Dependencia o cargo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cuenta antigua con correo no institucional ve el aviso', (tester) async {
      await _preparar(_usuario(institucional: false));
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      expect(find.text('Tu correo no es institucional'), findsOneWidget);
      expect(find.text('Cambiar a mi correo institucional'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('avatar sin foto muestra las iniciales', (tester) async {
      await _preparar(_usuario());
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      expect(find.text('AP'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(_peticiones.where((p) => p.endsWith('/auth/me/foto')), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('avatar con foto la descarga UNA vez por versión', (tester) async {
      await _preparar(_usuario(foto: true));
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Tu foto de perfil')), findsOneWidget);
      // Otra pantalla con el mismo avatar no la vuelve a pedir (caché por versión).
      await tester.pumpWidget(const SizedBox());
      await _pintar(tester, const Scaffold(body: CuentaPage()));
      await tester.pumpAndSettle();
      expect(_peticiones.where((p) => p == 'GET /auth/me/foto').length, 1);
      await tester.pumpWidget(const SizedBox());
    });

    for (final sistema in [1.0, 1.3]) {
      testWidgets('360 dp sin desbordes (texto ×$sistema, nombre largo, aviso y cargo)',
          (tester) async {
        await _preparar(_usuario(
          institucional: false,
          nombre: 'María Fernanda de los Ángeles Rodríguez Villalobos',
          cargo: 'Coordinación de laboratorios y salas audiovisuales del campus',
        ));
        await _pintar(tester, const Scaffold(body: CuentaPage()), sistema: sistema, alto: 740);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('hoja de foto', () {
    testWidgets('vista previa, subir y cerrar con aviso', (tester) async {
      await _preparar(_usuario());
      await _abrirHoja(tester, (_) async => XFile.fromData(_png, mimeType: 'image/png'));
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing); // aún no tiene
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(find.text('Vista previa'), findsOneWidget);
      expect(_peticiones.where((p) => p.startsWith('PUT')), isEmpty); // nada sin confirmar
      await tester.tap(find.text('Usar esta foto'));
      await tester.pumpAndSettle();
      expect(_peticiones, contains('PUT /auth/me/foto'));
      expect(find.text('Foto actualizada'), findsOneWidget);
      expect(sl<AuthController>().usuario!.tieneFoto, isTrue);
      expect(sl<AuthController>().usuario!.fotoVersion, 1800000000000);
    });

    testWidgets('error del servidor se muestra y deja reintentar', (tester) async {
      await _preparar(_usuario());
      _respuestaFoto = 415;
      await _abrirHoja(tester, (_) async => XFile.fromData(_png));
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar esta foto'));
      await tester.pumpAndSettle();
      expect(find.text('Solo se aceptan fotos JPEG o PNG.'), findsOneWidget);
      expect(find.text('Usar esta foto'), findsOneWidget);
    });

    testWidgets('archivo que no es JPEG ni PNG se rechaza antes de subir', (tester) async {
      await _preparar(_usuario());
      await _abrirHoja(
          tester, (_) async => XFile.fromData(Uint8List.fromList(utf8.encode('GIF89a....'))));
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Elige una foto JPEG o PNG'), findsOneWidget);
      expect(_peticiones.where((p) => p.startsWith('PUT')), isEmpty);
    });

    testWidgets('permiso de cámara denegado da un mensaje útil', (tester) async {
      await _preparar(_usuario());
      await _abrirHoja(tester, (_) async => throw PlatformException(code: 'camera_access_denied'));
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No tenemos permiso para usar la cámara'), findsOneWidget);
    });

    testWidgets('quitar foto vuelve a las iniciales', (tester) async {
      await _preparar(_usuario(foto: true));
      await _abrirHoja(tester, (_) async => null);
      await tester.tap(find.text('Quitar foto'));
      await tester.pumpAndSettle();
      expect(_peticiones, contains('DELETE /auth/me/foto'));
      expect(find.text('Foto quitada'), findsOneWidget);
      expect(sl<AuthController>().usuario!.tieneFoto, isFalse);
    });
  });
}

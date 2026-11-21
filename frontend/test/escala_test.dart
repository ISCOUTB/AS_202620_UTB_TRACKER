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
import 'package:utb_tracker_app/core/theme/escala.dart';
import 'package:utb_tracker_app/features/auth/domain/preferencias.dart';
import 'package:utb_tracker_app/features/auth/presentation/auth_controller.dart';
import 'package:utb_tracker_app/features/auth/presentation/login_page.dart';
import 'package:utb_tracker_app/features/cuenta/presentation/cuenta_page.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/panel_salones_page.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/salon_control_page.dart';

/// Fase 3: con la escala de la interfaz, el texto del sistema grande y la preferencia
/// "Extra grande", las pantallas principales no se desbordan en un celular de 360 dp.

const _nombreLargo = 'María Fernanda de los Ángeles Rodríguez Villalobos';

Map<String, dynamic> _salon(int id, String nombre) => {
      'id': id,
      'nombre': nombre,
      'ubicacion': 'Edificio Aulas 1, Piso 3, junto a la escalera principal',
      'edificio': 'Aulas 1',
      'piso': 3,
      'capacidad': 40,
      'estado': 'disponible',
      'activo': true,
      'tipo': 'laboratorio_computo',
      'descripcion': 'Sala con muchos equipos y una descripción larga para probar el ajuste del texto',
      'equipamiento': [
        {'categoria': 'computador', 'total': 20, 'operativos': 18},
        {'categoria': 'video_beam', 'total': 1, 'operativos': 0},
        {'categoria': 'audio', 'total': 2, 'operativos': 2},
        {'categoria': 'aire_ac', 'total': 1, 'operativos': 1},
      ],
      'tipo_sugerido': 'auditorio',
    };

Map<String, dynamic> _ocupacion(int id, String nombre, {bool clase = false}) => {
      'salon': _salon(id, nombre),
      'ocupante': clase ? 'clase' : 'libre',
      'clase_actual': clase
          ? {
              'horario_id': id,
              'materia': 'Ecuaciones diferenciales y álgebra lineal aplicada',
              'profesor': _nombreLargo,
              'hora_inicio': '10:00:00',
              'hora_fin': '12:00:00',
            }
          : null,
      'prestamo_actual': null,
      'profesor_presente': clase ? null : false,
      'solicitudes_pendientes': 3,
      'reportes_abiertos': 12,
    };

final _usuario = {
  'id': 1,
  'nombre': _nombreLargo,
  'email': 'maria.fernanda.rodriguez.villalobos@utb.edu.co',
  'rol': 'auxiliar',
  'permisos': permisosDe('auxiliar').valores.toList(),
  'telefono': '+57 300 123 4567',
  'dependencia': 'Coordinación de laboratorios de ingeniería',
};

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<http.Response> _servidor(http.Request req) async {
  final ruta = req.url.path;
  if (ruta == '/salud') return _json({'status': 'ok'});
  if (ruta == '/auth/login') {
    return _json({'access_token': 'a', 'refresh_token': 'r', 'token_type': 'bearer', 'user': _usuario});
  }
  if (ruta == '/auth/me') return _json(_usuario);
  if (ruta == '/salones/ocupacion') {
    return _json([
      for (var i = 1; i <= 8; i++) _ocupacion(i, 'A1-30$i', clase: i.isEven),
    ]);
  }
  if (ruta == '/salones/1/ocupacion') return _json(_ocupacion(1, 'A1-301', clase: true));
  return _json([]);
}

Future<void> _preparar() async {
  FlutterSecureStorage.setMockInitialValues({});
  await configurarDependencias(
    api: ApiClient(baseUrl: 'http://x', client: MockClient(_servidor)),
  );
}

Future<void> _pintar(WidgetTester tester, Widget pagina, double sistema) async {
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

void main() {
  test('el factor de texto respeta el sistema con tope', () {
    expect(Escala.factorTexto(const TextScaler.linear(1), TamanoTexto.normal), 1);
    expect(Escala.factorTexto(const TextScaler.linear(1), TamanoTexto.grande), closeTo(1.15, 1e-9));
    expect(Escala.factorTexto(const TextScaler.linear(2), TamanoTexto.extraGrande), Escala.textoMaximo);
    expect(Escala.interfaz, 1.10);
  });

  // Peor caso: texto del sistema al 130 % y preferencia "Extra grande" (queda en el tope).
  for (final sistema in [1.0, 1.3]) {
    group('360 dp, texto del sistema ×$sistema', () {
      setUp(_preparar);

      testWidgets('login', (tester) async {
        await _pintar(tester, const LoginPage(), sistema);
        expect(tester.takeException(), isNull);
        expect(find.text('Continuar'), findsOneWidget);
      });

      testWidgets('perfil', (tester) async {
        await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
        await _pintar(tester, const Scaffold(body: CuentaPage()), sistema);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('panel de salones', (tester) async {
        await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
        await _pintar(tester, const Scaffold(body: PanelSalonesPage()), sistema);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('control de salón', (tester) async {
        await sl<AuthController>().iniciarSesion('x', 'ClaveSegura1');
        await _pintar(tester, const SalonControlPage(salonId: 1), sistema);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    });
  }
}

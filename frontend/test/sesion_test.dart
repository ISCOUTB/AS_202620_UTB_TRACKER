import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/config/api_config.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/utils/politica.dart';

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('Refresco de sesión (ADR-0014)', () {
    test('un 401 renueva el token UNA vez y repite la petición', () async {
      var refrescos = 0;
      final vistos = <String?>[];
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((req) async {
          if (req.url.path == '/auth/refresh') {
            refrescos++;
            expect(jsonDecode(req.body)['refresh_token'], 'r-viejo');
            return _json({'access_token': 'a-nuevo', 'refresh_token': 'r-nuevo'});
          }
          vistos.add(req.headers['Authorization']);
          return req.headers['Authorization'] == 'Bearer a-nuevo'
              ? _json({'ok': true})
              : _json({'detail': 'Token inválido o expirado'}, 401);
        }),
      )..fijarTokens('a-viejo', 'r-viejo');
      String? guardado;
      api.alRenovarTokens = (a, r) => guardado = '$a|$r';

      // Dos peticiones a la vez: un solo refresco.
      final r = await Future.wait([api.get('/auth/me'), api.get('/salones')]);

      expect(r, [
        {'ok': true},
        {'ok': true},
      ]);
      expect(refrescos, 1);
      expect(guardado, 'a-nuevo|r-nuevo');
      expect(api.refreshToken, 'r-nuevo');
      expect(vistos.where((v) => v == 'Bearer a-nuevo').length, 2);
    });

    test('si el refresh también es rechazado se avisa que la sesión venció', () async {
      var vencida = false;
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((req) async =>
            _json({'detail': 'Refresh token inválido o expirado'}, 401)),
      )
        ..fijarTokens('a', 'r')
        ..alVencerSesion = () {};
      api.alVencerSesion = () => vencida = true;

      await expectLater(
        api.get('/auth/me', reintentos: 0),
        throwsA(isA<ApiException>().having((e) => e.tipo, 'tipo', TipoError.noAutorizado)),
      );
      expect(vencida, isTrue);
      expect(api.token, isNull);
    });

    test('el login nunca intenta refrescar (un 401 es "clave incorrecta")', () async {
      var refrescos = 0;
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((req) async {
          if (req.url.path == '/auth/refresh') refrescos++;
          return _json({'detail': 'Usuario, correo o contraseña incorrectos'}, 401);
        }),
      )..fijarTokens('a', 'r');

      await expectLater(api.post('/auth/login', cuerpo: {}), throwsA(isA<ApiException>()));
      expect(refrescos, 0);
    });

    test('429 y 503 dan mensajes claros', () {
      final limite = ApiException.fromResponse(_json({'detail': 'Espera'}, 429));
      expect(limite.tipo, TipoError.limite);
      final caido = ApiException.fromResponse(http.Response('Bad gateway', 503));
      expect(caido.mensaje, contains('no está disponible'));
    });
  });

  group('Servidor', () {
    test('describe el servidor oficial y el local', () {
      expect(ApiConfig.describir(ApiConfig.servidorProduccion), 'Oficial (nube)');
      expect(ApiConfig.describir('http://127.0.0.1:8000'), 'Local (este PC)');
      expect(ApiConfig.describir('http://192.168.1.5:8000'), 'Personalizado');
    });

    test('el ApiClient sigue al servidor elegido', () {
      final api = ApiClient(client: MockClient((_) async => _json({})));
      ApiConfig.elegir('http://127.0.0.1:8000/');
      expect(api.baseUrl, 'http://127.0.0.1:8000');
      ApiConfig.elegir(null);
      expect(api.baseUrl, ApiConfig.porDefecto);
    });
  });

  group('Política de contraseña (espejo del backend)', () {
    test('mismas reglas y mensajes', () {
      expect(Politica.errorPassword('1234567'), Politica.msgPasswordCorta);
      expect(Politica.errorPassword('ana@utb.edu.co', correo: 'Ana@UTB.edu.co'),
          Politica.msgPasswordIgualCorreo);
      expect(Politica.errorPassword('ana12345', correo: 'ana12345@utb.edu.co'),
          Politica.msgPasswordIgualCorreo);
      expect(Politica.errorPassword('juan perez', nombre: 'Juan  Perez'),
          Politica.msgPasswordIgualNombre);
      expect(Politica.errorPassword('ClaveSegura1', correo: 'a@b.co', nombre: 'Ana'), isNull);
      expect(Politica.msgPasswordCorta, 'La contraseña debe tener al menos 8 caracteres');
    });

    test('correo normalizado y sin saltos de línea', () {
      expect(Politica.normalizarCorreo('  Ana@UTB.edu.CO '), 'ana@utb.edu.co');
      expect(Politica.correoValido('ana@utb.edu.co'), isTrue);
      expect(Politica.correoValido('ana@utb.edu.co\nBcc: x@y.z'), isFalse);
    });
  });
}

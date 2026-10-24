import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:utb_tracker_app/core/utils/utilidades.dart';

void main() {
  group('fechas del servidor (naive = UTC)', () {
    test('parsearFechaServidor trata fechas sin zona como UTC', () {
      final f = parsearFechaServidor('2026-10-20T15:00:00');
      expect(f.toUtc(), DateTime.utc(2026, 10, 20, 15));
    });

    test('parsearFechaServidor respeta la zona si viene', () {
      final f = parsearFechaServidor('2026-10-20T15:00:00Z');
      expect(f.toUtc(), DateTime.utc(2026, 10, 20, 15));
    });

    test('fechaParaServidor envía UTC sin sufijo de zona', () {
      final texto = fechaParaServidor(DateTime.utc(2026, 10, 20, 15, 30));
      expect(texto.endsWith('Z'), isFalse);
      expect(texto.startsWith('2026-10-20T15:30:00'), isTrue);
    });

    test('ida y vuelta conserva el instante', () {
      final original = DateTime.utc(2026, 1, 5, 23, 59).toLocal();
      final vuelta = parsearFechaServidor(fechaParaServidor(original));
      expect(vuelta.toUtc(), original.toUtc());
    });
  });

  group('describirPlazo', () {
    final ahora = DateTime(2026, 10, 20, 12);
    test('futuro en horas', () {
      expect(describirPlazo(DateTime(2026, 10, 20, 15), ahora: ahora), 'vence en 3 h');
    });
    test('pasado en días', () {
      expect(describirPlazo(DateTime(2026, 10, 18, 12), ahora: ahora), 'vencido hace 2 d');
    });
  });

  group('JWT e idempotencia', () {
    test('leerPayloadJwt lee el sub', () {
      String b64(Map<String, dynamic> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final token = '${b64({'alg': 'HS256'})}.${b64({'sub': 'ana@utb.edu.co'})}.firma';
      expect(leerPayloadJwt(token)?['sub'], 'ana@utb.edu.co');
    });

    test('leerPayloadJwt devuelve null si no es un JWT', () {
      expect(leerPayloadJwt('no-es-un-token'), isNull);
    });

    test('las claves de idempotencia son únicas y de 32 hex', () {
      final claves = {for (var i = 0; i < 50; i++) nuevaClaveIdempotencia()};
      expect(claves.length, 50);
      expect(claves.every((c) => RegExp(r'^[0-9a-f]{32}$').hasMatch(c)), isTrue);
    });
  });
}

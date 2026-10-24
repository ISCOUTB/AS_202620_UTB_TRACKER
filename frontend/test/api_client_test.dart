import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/features/prestamos/data/prestamos_data.dart';
import 'package:utb_tracker_app/features/recursos/data/recursos_data.dart';

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('GET envía el Bearer y decodifica JSON', () async {
    late http.Request visto;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        visto = req;
        return _json([
          {'id': 1, 'categoria': 'video_beam', 'salon_id': 'A1-304', 'serial': 'VB-1', 'estado': 'disponible'},
        ]);
      }),
    )..fijarToken('abc');

    final lista = await RecursosRemoteDataSource(api).listar();

    expect(visto.url.toString(), 'http://x/recursos');
    expect(visto.headers['Authorization'], 'Bearer abc');
    expect(lista.single.serial, 'VB-1');
    expect(lista.single.disponible, isTrue);
  });

  test('409 se traduce a conflicto con el detail del backend', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => _json(
            {'detail': 'El recurso no esta disponible (estado actual: prestado)'},
            409,
          )),
    );

    expect(
      () => PrestamosRemoteDataSource(api).crear(
        recursoId: 1,
        usuarioId: 1,
        fechaDevolucionEsperada: DateTime.utc(2030),
        claveIdempotencia: 'k',
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.tipo, 'tipo', TipoError.conflicto)
          .having((e) => e.mensaje, 'mensaje', contains('no esta disponible'))),
    );
  });

  test('POST de préstamo manda X-Idempotency-Key y fecha UTC sin zona', () async {
    late http.Request visto;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        visto = req;
        return _json({
          'id': 7,
          'recurso_id': 1,
          'usuario_id': 2,
          'fecha_prestamo': '2026-10-20T15:00:00',
          'fecha_devolucion_esperada': '2026-10-21T23:00:00',
          'fecha_devolucion_real': null,
        }, 201);
      }),
    );

    final p = await PrestamosRemoteDataSource(api).crear(
      recursoId: 1,
      usuarioId: 2,
      fechaDevolucionEsperada: DateTime.utc(2026, 10, 21, 23),
      claveIdempotencia: 'clave-123',
    );

    expect(visto.headers['X-Idempotency-Key'], 'clave-123');
    final cuerpo = jsonDecode(visto.body) as Map<String, dynamic>;
    expect(cuerpo['recurso_id'], 1);
    expect((cuerpo['fecha_devolucion_esperada'] as String).endsWith('Z'), isFalse);
    expect(p.id, 7);
    expect(p.devuelto, isFalse);
  });

  test('error 422 de Pydantic se resume en un mensaje legible', () async {
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async => _json({
            'detail': [
              {'loc': ['body', 'serial'], 'msg': 'Field required', 'type': 'missing'},
            ],
          }, 422)),
    );
    expect(
      () => api.post('/recursos', cuerpo: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.mensaje, 'mensaje', 'serial: Field required')),
    );
  });

  test('un GET se reintenta ante 5xx y luego tiene éxito', () async {
    var llamadas = 0;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async {
        llamadas++;
        return llamadas < 2 ? _json({'detail': 'boom'}, 503) : _json({'status': 'ok'});
      }),
    );
    final r = await api.get('/salud');
    expect(r['status'], 'ok');
    expect(llamadas, 2);
  });

  test('un POST NO se reintenta solo', () async {
    var llamadas = 0;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((_) async {
        llamadas++;
        return _json({'detail': 'boom'}, 503);
      }),
    );
    await expectLater(api.post('/prestamos', cuerpo: {}), throwsA(isA<ApiException>()));
    expect(llamadas, 1);
  });

  test('PATCH /prestamos/{id}/devolver envía petición y procesa devolución', () async {
    late http.Request visto;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        visto = req;
        return _json({
          'id': 15,
          'recurso_id': 3,
          'usuario_id': 2,
          'fecha_prestamo': '2026-10-20T10:00:00',
          'fecha_devolucion_esperada': '2026-10-21T18:00:00',
          'fecha_devolucion_real': '2026-10-21T17:30:00',
          'estado': 'devuelto',
        }, 200);
      }),
    )..fijarToken('token-auth-xyz');

    final devuelto = await PrestamosRemoteDataSource(api).devolver(15);

    expect(visto.method, 'PATCH');
    expect(visto.url.toString(), 'http://x/prestamos/15/devolver');
    expect(visto.headers['Authorization'], 'Bearer token-auth-xyz');
    expect(devuelto.id, 15);
    expect(devuelto.devuelto, isTrue);
  });

  test('PUT envía el cuerpo y token correctamente', () async {
    late http.Request visto;
    final api = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        visto = req;
        return _json({'status': 'updated'});
      }),
    )..fijarToken('token-put');

    final r = await api.put('/recursos/1', cuerpo: {'descripcion': 'Nuevo detalle'});
    expect(visto.method, 'PUT');
    expect(visto.url.toString(), 'http://x/recursos/1');
    expect(visto.headers['Authorization'], 'Bearer token-put');
    expect(r['status'], 'updated');
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/features/salones/data/salones_data.dart';

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('SalonesRemoteDataSource lista salones y mapea modelos correctamente', () async {
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        return _json([
          {
            'id': 1,
            'nombre': 'A-301',
            'ubicacion': 'Edificio A, Piso 3',
            'edificio': 'A',
            'piso': 3,
            'capacidad': 40,
            'estado': 'disponible',
            'activo': true,
          },
        ]);
      }),
    )..fijarToken('token-123');

    final lista = await SalonesRemoteDataSource(api).listarSalones();
    expect(lista.length, 1);
    expect(lista.first.nombre, 'A-301');
    expect(lista.first.capacidad, 40);
    expect(lista.first.disponible, isTrue);
    expect(lista.first.detalleUbicacion, contains('Edif. A'));
  });

  test('SalonesRemoteDataSource consulta disponibilidad con franjas', () async {
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        expect(req.url.path, '/salones/1/disponibilidad');
        expect(req.url.queryParameters['dia_semana'], '2');
        return _json([
          {
            'dia_semana': 2,
            'hora_inicio': '06:00:00',
            'hora_fin': '08:00:00',
          },
          {
            'dia_semana': 2,
            'hora_inicio': '10:00:00',
            'hora_fin': '14:00:00',
          },
        ]);
      }),
    );

    final franjas = await SalonesRemoteDataSource(api).consultarDisponibilidad(1, diaSemana: 2);
    expect(franjas.length, 2);
    expect(franjas.first.diaNombre, 'Martes');
    expect(franjas.first.horaInicio, '06:00:00');
    expect(franjas.first.horaFin, '08:00:00');
  });

  test('SalonesRemoteDataSource crea solicitud de préstamo de salón', () async {
    late http.Request visto;
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((req) async {
        visto = req;
        return _json({
          'id': 9,
          'salon_id': 1,
          'usuario_id': 3,
          'fecha_inicio': '2026-10-25T08:00:00',
          'fecha_fin': '2026-10-25T10:00:00',
          'motivo': 'Monitoría de Arquitectura',
          'estado': 'pendiente',
          'created_at': '2026-10-24T12:00:00',
        }, 201);
      }),
    )..fijarToken('token-salon');

    final prestamo = await SalonesRemoteDataSource(api).solicitarPrestamoSalon(
      salonId: 1,
      fechaInicio: DateTime.utc(2026, 10, 25, 8),
      fechaFin: DateTime.utc(2026, 10, 25, 10),
      motivo: 'Monitoría de Arquitectura',
    );

    expect(visto.method, 'POST');
    expect(visto.url.path, '/prestamos-salon');
    expect(visto.headers['Authorization'], 'Bearer token-salon');
    expect(prestamo.id, 9);
    expect(prestamo.salonId, 1);
    expect(prestamo.motivo, 'Monitoría de Arquitectura');
    expect(prestamo.estado, 'pendiente');
  });
}

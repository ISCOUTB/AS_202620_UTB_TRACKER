import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/state/carga.dart';
import 'package:utb_tracker_app/features/control/presentation/control_controller.dart';
import 'package:utb_tracker_app/features/recursos/data/recursos_data.dart';
import 'package:utb_tracker_app/features/salones/domain/entities/salon.dart';
import 'package:utb_tracker_app/features/salones_admin/data/salones_admin_data.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/entities/ocupacion.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/repositories/salones_admin_repository.dart';

PrestamoSalon _solicitud(int id, String estado) => PrestamoSalon(
      id: id,
      salonId: 1,
      usuarioId: 7,
      fechaInicio: DateTime(2026, 11, 13, 10 + id),
      fechaFin: DateTime(2026, 11, 13, 11 + id),
      estado: estado,
      createdAt: DateTime(2026, 11, 13),
      salonNombre: 'A4-204',
    );

final _reporte = ReporteSalon(
  id: 3,
  salonId: 1,
  usuarioId: 7,
  tipo: TipoReporteSalon.equipo,
  descripcion: 'El aire gotea',
  abierto: true,
  creadoEn: DateTime(2026, 11, 13),
  salonNombre: 'A4-204',
);

class _RepoFalso extends Fake implements SalonesAdminRepository {
  final cambios = <(int, String)>[];
  bool pidioReportes = false;

  @override
  Future<List<PrestamoSalon>> listarTodasLasSolicitudes() async =>
      [_solicitud(1, 'pendiente'), _solicitud(2, 'aprobado')];

  @override
  Future<List<ReporteSalon>> listarTodosLosReportes() async {
    pidioReportes = true;
    return [_reporte];
  }

  @override
  Future<PrestamoSalon> cambiarEstadoSolicitud(int prestamoId, String estado) async {
    cambios.add((prestamoId, estado));
    return _solicitud(prestamoId, estado);
  }
}

http.Response _json(Object cuerpo) => http.Response(jsonEncode(cuerpo), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('ControlController', () {
    test('separa solicitudes pendientes de las respondidas', () async {
      final repo = _RepoFalso();
      final c = ControlController(repo);
      await c.cargar(conReportes: false);

      expect(c.carga, Carga.ok);
      expect(c.pendientes.map((s) => s.id), [1]);
      expect(c.resueltas.map((s) => s.id), [2]);
      // El usuario UTB no pide los reportes de todos los salones (es solo del auxiliar).
      expect(repo.pidioReportes, isFalse);
    });

    test('el auxiliar ve los reportes abiertos y aprueba solicitudes', () async {
      final repo = _RepoFalso();
      final c = ControlController(repo);
      await c.cargar(conReportes: true);
      expect(c.reportesAbiertos.single.salonNombre, 'A4-204');

      final error = await c.cambiarSolicitud(c.pendientes.single, 'aprobado', conReportes: true);
      expect(error, isNull);
      expect(repo.cambios, [(1, 'aprobado')]);
    });
  });

  group('nombres reales de salón', () {
    test('el recurso muestra el código del salón, no su id', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((_) async => _json([
              {
                'id': 9, 'categoria': 'aire_ac', 'salon_id': 5, 'serial': 'AC-A4-204',
                'estado': 'dañado', 'salon_nombre': 'A4-204', 'salon_edificio': 'Aulas 4',
              },
            ])),
      );
      final r = (await RecursosRemoteDataSource(api).listar()).single;
      expect(r.salonTexto, 'A4-204');
      expect(r.edificioTexto, 'Ed. Aulas 4');
    });

    test('un equipo sin salón no muestra un id vacío', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((_) async => _json([
              {'id': 1, 'categoria': 'audio', 'salon_id': null, 'serial': 'AU-1', 'estado': 'disponible'},
            ])),
      );
      final r = (await RecursosRemoteDataSource(api).listar()).single;
      expect(r.salonTexto, 'Sin salón asignado');
    });

    test('el reporte del listado general trae el código del salón', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        client: MockClient((req) async {
          expect(req.url.path, '/salones/reportes');
          return _json([
            {
              'id': 1, 'salon_id': 5, 'usuario_id': 2, 'tipo': 'limpieza',
              'descripcion': 'Tablero', 'estado': 'abierto', 'salon_nombre': 'A1-101',
              'usuario_nombre': 'Camila Rojas',
            },
          ]);
        }),
      );
      final r = (await SalonesAdminRemoteDataSource(api).listarTodosLosReportes()).single;
      expect(r.salonNombre, 'A1-101');
      expect(r.usuarioNombre, 'Camila Rojas');
    });
  });
}

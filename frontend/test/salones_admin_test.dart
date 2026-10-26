import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:utb_tracker_app/core/network/api_client.dart';
import 'package:utb_tracker_app/core/state/carga.dart';
import 'package:utb_tracker_app/features/salones_admin/data/salones_admin_data.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/entities/ocupacion.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/repositories/salones_admin_repository.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/salones_admin_controller.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/salones_admin_estilos.dart';
import 'package:utb_tracker_app/shared/uber_widgets.dart';

http.Response _json(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _salon(int id, String nombre, {String estado = 'disponible'}) => {
      'id': id,
      'nombre': nombre,
      'ubicacion': 'Edificio A, Piso 3',
      'edificio': 'A',
      'piso': 3,
      'capacidad': 40,
      'estado': estado,
      'activo': true,
    };

Map<String, dynamic> _ocupacionJson({
  required Map<String, dynamic> salon,
  String ocupante = 'libre',
  bool? profesorPresente,
  Map<String, dynamic>? clase,
  Map<String, dynamic>? prestamo,
  int pendientes = 0,
  int reportes = 0,
}) =>
    {
      'salon': salon,
      'ocupante': ocupante,
      'clase_actual': clase,
      'prestamo_actual': prestamo,
      'profesor_presente': profesorPresente,
      'solicitudes_pendientes': pendientes,
      'reportes_abiertos': reportes,
    };

const _clase = {
  'horario_id': 7,
  'materia': 'Cálculo II',
  'profesor': 'Ana Pérez',
  'hora_inicio': '10:00:00',
  'hora_fin': '12:00:00',
};

class _RepoFalso extends Fake implements SalonesAdminRepository {
  _RepoFalso(this.ocupaciones);
  List<OcupacionSalon> ocupaciones;
  bool? ultimaPresencia;
  Object? fallo;

  @override
  Future<List<OcupacionSalon>> listarOcupacion() async {
    if (fallo != null) throw fallo!;
    return ocupaciones;
  }

  @override
  Future<void> registrarPresencia(int salonId, {required bool presente, String? nota}) async {
    ultimaPresencia = presente;
  }
}

void main() {
  group('OcupacionModel', () {
    test('mapea una clase en curso con el profesor sin confirmar', () {
      final o = OcupacionModel.desdeJson(_ocupacionJson(
        salon: _salon(1, 'A-301'),
        ocupante: 'clase',
        clase: Map<String, dynamic>.from(_clase),
      ));

      expect(o.ocupante, Ocupante.clase);
      expect(o.clase!.profesor, 'Ana Pérez');
      expect(o.clase!.rango, '10:00 – 12:00');
      expect(o.profesorPresente, isNull);
      expect(o.situacion, SituacionSalon.claseSinConfirmar);
      expect(o.titular, 'Ana Pérez');
      expect(o.requiereAtencion, isTrue);
    });

    test('mapea un préstamo aprobado con el nombre de quien tiene el salón', () {
      final o = OcupacionModel.desdeJson(_ocupacionJson(
        salon: _salon(2, 'B-101'),
        ocupante: 'prestamo',
        prestamo: {
          'prestamo_id': 4,
          'usuario_id': 9,
          'usuario_nombre': 'Laura Gómez',
          'estado': 'aprobado',
          'fecha_inicio': '2026-10-26T19:00:00',
          'fecha_fin': '2026-10-26T21:00:00',
          'motivo': 'Estudio en grupo',
        },
      ));

      expect(o.situacion, SituacionSalon.prestado);
      expect(o.titular, 'Laura Gómez');
      expect(o.subtitular, 'Estudio en grupo');
      expect(o.prestamo!.enUso, isFalse);
    });

    test('un salón en mantenimiento gana sobre cualquier otra situación', () {
      final o = OcupacionModel.desdeJson(_ocupacionJson(
        salon: _salon(3, 'C-1', estado: 'mantenimiento'),
        ocupante: 'clase',
        clase: Map<String, dynamic>.from(_clase),
        profesorPresente: true,
      ));

      expect(o.situacion, SituacionSalon.mantenimiento);
    });

    test('profesor presente / ausente se refleja en la situación', () {
      OcupacionSalon con(bool presente) => OcupacionModel.desdeJson(_ocupacionJson(
            salon: _salon(1, 'A-301'),
            ocupante: 'clase',
            clase: Map<String, dynamic>.from(_clase),
            profesorPresente: presente,
          ));

      expect(con(true).situacion, SituacionSalon.claseConProfesor);
      expect(con(false).situacion, SituacionSalon.claseSinProfesor);
      expect(con(true).requiereAtencion, isFalse);
    });

    test('un salón libre sin avisos no requiere atención', () {
      final o = OcupacionModel.desdeJson(_ocupacionJson(salon: _salon(1, 'A-301')));

      expect(o.situacion, SituacionSalon.libre);
      expect(o.requiereAtencion, isFalse);
      expect(colorDeSituacion(o.situacion), isNotNull);
    });
  });

  group('SalonesAdminRemoteDataSource', () {
    test('lista la ocupación enviando el token', () async {
      late http.Request visto;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          visto = req;
          return _json([_ocupacionJson(salon: _salon(1, 'A-301'))]);
        }),
      )..fijarToken('tok');

      final lista = await SalonesAdminRemoteDataSource(api).listarOcupacion();

      expect(visto.url.path, '/salones/ocupacion');
      expect(visto.headers['Authorization'], 'Bearer tok');
      expect(lista.single.salon.nombre, 'A-301');
    });

    test('registra la presencia del profesor con PUT', () async {
      late http.Request visto;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          visto = req;
          return _json({'id': 1, 'salon_id': 1, 'horario_id': 7, 'fecha': '2026-10-26',
            'profesor_presente': true, 'registrado_por': 3});
        }),
      );

      await SalonesAdminRemoteDataSource(api).registrarPresencia(1, presente: true);

      expect(visto.method, 'PUT');
      expect(visto.url.path, '/salones/1/presencia');
      expect(jsonDecode(visto.body), {'profesor_presente': true});
    });

    test('crea un reporte con el tipo del backend', () async {
      late http.Request visto;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          visto = req;
          return _json({
            'id': 5, 'salon_id': 1, 'usuario_id': 3, 'tipo': 'equipo',
            'descripcion': 'El video beam no enciende', 'estado': 'abierto',
            'created_at': '2026-10-26T15:00:00', 'resuelto_en': null,
          }, 201);
        }),
      );

      final r = await SalonesAdminRemoteDataSource(api).crearReporte(
        1,
        tipo: TipoReporteSalon.equipo,
        descripcion: 'El video beam no enciende',
      );

      expect(visto.url.path, '/salones/1/reportes');
      expect(jsonDecode(visto.body)['tipo'], 'equipo');
      expect(r.abierto, isTrue);
      expect(r.tipo, TipoReporteSalon.equipo);
    });

    test('lista solicitudes de un salón filtrando por salon_id y estado', () async {
      late http.Request visto;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((req) async {
          visto = req;
          return _json([]);
        }),
      );

      await SalonesAdminRemoteDataSource(api).listarSolicitudes(4, estado: 'pendiente');

      expect(visto.url.path, '/prestamos-salon');
      expect(visto.url.queryParameters['salon_id'], '4');
      expect(visto.url.queryParameters['estado'], 'pendiente');
    });
  });

  group('SalonesAdminController', () {
    OcupacionSalon ocupacion(int id, String nombre, {bool clase = false, int pendientes = 0}) =>
        OcupacionModel.desdeJson(_ocupacionJson(
          salon: _salon(id, nombre),
          ocupante: clase ? 'clase' : 'libre',
          clase: clase ? Map<String, dynamic>.from(_clase) : null,
          pendientes: pendientes,
        ));

    test('los salones que requieren atención van primero y el filtro funciona', () async {
      final repo = _RepoFalso([
        ocupacion(1, 'A-100'),
        ocupacion(2, 'A-200', clase: true),
        ocupacion(3, 'A-300', pendientes: 2),
      ]);
      final c = SalonesAdminController(repo);

      await c.cargar();

      expect(c.carga, Carga.ok);
      expect(c.visibles.map((o) => o.salon.nombre), ['A-200', 'A-300', 'A-100']);

      c.fijarFiltro(FiltroPanel.clases);
      expect(c.visibles.map((o) => o.salon.nombre), ['A-200']);
      expect(c.contar(FiltroPanel.libres), 2);
      expect(c.totalPendientes, 2);
    });

    test('la búsqueda encuentra por nombre de profesor', () async {
      final c = SalonesAdminController(_RepoFalso([
        ocupacion(1, 'A-100'),
        ocupacion(2, 'A-200', clase: true),
      ]));
      await c.cargar();

      c.fijarBusqueda('ana');

      expect(c.visibles.map((o) => o.salon.nombre), ['A-200']);
    });

    test('un fallo de red deja el panel en estado de error con mensaje', () async {
      final repo = _RepoFalso([])..fallo = Exception('sin red');
      final c = SalonesAdminController(repo);

      await c.cargar();

      expect(c.carga, Carga.error);
      expect(c.error, isNotNull);
    });

    test('registrar presencia delega en el repositorio y devuelve null si salió bien', () async {
      final repo = _RepoFalso([ocupacion(2, 'A-200', clase: true)]);
      final c = SalonesAdminController(repo);

      final error = await c.registrarPresencia(2, presente: false);

      expect(error, isNull);
      expect(repo.ultimaPresencia, isFalse);
    });
  });

  group('utilidades visuales', () {
    test('AvatarIniciales toma las iniciales de las dos primeras palabras', () {
      expect(AvatarIniciales.iniciales('Ana Pérez Gómez'), 'AP');
      expect(AvatarIniciales.iniciales('laura'), 'L');
      expect(AvatarIniciales.iniciales('  '), '?');
    });

    test('haceCuanto describe el tiempo transcurrido', () {
      final ahora = DateTime(2026, 10, 26, 12);
      expect(haceCuanto(DateTime(2026, 10, 26, 11, 55), ahora: ahora), 'hace 5 min');
      expect(haceCuanto(DateTime(2026, 10, 26, 9), ahora: ahora), 'hace 3 h');
      expect(haceCuanto(DateTime(2026, 10, 24, 12), ahora: ahora), 'hace 2 d');
    });
  });
}

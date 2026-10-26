import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';
import '../../salones/data/salones_data.dart';
import '../../salones/domain/entities/salon.dart';
import '../domain/entities/ocupacion.dart';
import '../domain/repositories/salones_admin_repository.dart';

/// JSON del backend → entidades de administración de salones.
class OcupacionModel {
  OcupacionModel._();

  static Ocupante _ocupante(String? v) => switch (v) {
        'clase' => Ocupante.clase,
        'prestamo' => Ocupante.prestamo,
        _ => Ocupante.libre,
      };

  static OcupacionSalon desdeJson(Map<String, dynamic> j) {
    final clase = j['clase_actual'] as Map<String, dynamic>?;
    final prestamo = j['prestamo_actual'] as Map<String, dynamic>?;
    return OcupacionSalon(
      salon: SalonModel.desdeJson(j['salon'] as Map<String, dynamic>),
      ocupante: _ocupante(j['ocupante']?.toString()),
      clase: clase == null
          ? null
          : ClaseActual(
              horarioId: (clase['horario_id'] as num).toInt(),
              materia: clase['materia']?.toString(),
              profesor: clase['profesor']?.toString(),
              horaInicio: (clase['hora_inicio'] ?? '').toString(),
              horaFin: (clase['hora_fin'] ?? '').toString(),
            ),
      prestamo: prestamo == null
          ? null
          : PrestamoActual(
              prestamoId: (prestamo['prestamo_id'] as num).toInt(),
              usuarioId: (prestamo['usuario_id'] as num).toInt(),
              usuarioNombre: (prestamo['usuario_nombre'] ?? '').toString(),
              estado: (prestamo['estado'] ?? '').toString(),
              fechaInicio: parsearFechaServidor(prestamo['fecha_inicio'].toString()),
              fechaFin: parsearFechaServidor(prestamo['fecha_fin'].toString()),
              motivo: prestamo['motivo']?.toString(),
            ),
      profesorPresente: j['profesor_presente'] as bool?,
      solicitudesPendientes: (j['solicitudes_pendientes'] as num?)?.toInt() ?? 0,
      reportesAbiertos: (j['reportes_abiertos'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReporteSalonModel {
  ReporteSalonModel._();

  static ReporteSalon desdeJson(Map<String, dynamic> j) => ReporteSalon(
        id: (j['id'] as num).toInt(),
        salonId: (j['salon_id'] as num).toInt(),
        usuarioId: (j['usuario_id'] as num).toInt(),
        tipo: TipoReporteSalon.desde(j['tipo']?.toString()),
        descripcion: (j['descripcion'] ?? '').toString(),
        abierto: (j['estado'] ?? 'abierto') == 'abierto',
        creadoEn: j['created_at'] != null
            ? parsearFechaServidor(j['created_at'].toString())
            : DateTime.now(),
        resueltoEn: j['resuelto_en'] != null
            ? parsearFechaServidor(j['resuelto_en'].toString())
            : null,
      );
}

class SalonesAdminRemoteDataSource {
  SalonesAdminRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<OcupacionSalon>> listarOcupacion() async {
    final cuerpo = await _api.get('/salones/ocupacion') as List<dynamic>;
    return cuerpo
        .map((e) => OcupacionModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OcupacionSalon> obtenerOcupacion(int salonId) async {
    final cuerpo = await _api.get('/salones/$salonId/ocupacion') as Map<String, dynamic>;
    return OcupacionModel.desdeJson(cuerpo);
  }

  Future<void> registrarPresencia(int salonId, {required bool presente, String? nota}) async {
    await _api.put(
      '/salones/$salonId/presencia',
      cuerpo: {
        'profesor_presente': presente,
        if (nota != null && nota.isNotEmpty) 'nota': nota,
      },
    );
  }

  Future<List<ReporteSalon>> listarReportes(int salonId, {bool soloAbiertos = false}) async {
    final cuerpo = await _api.get(
      '/salones/$salonId/reportes',
      parametros: soloAbiertos ? {'estado': 'abierto'} : null,
    ) as List<dynamic>;
    return cuerpo
        .map((e) => ReporteSalonModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReporteSalon> crearReporte(
    int salonId, {
    required TipoReporteSalon tipo,
    required String descripcion,
  }) async {
    final cuerpo = await _api.post(
      '/salones/$salonId/reportes',
      cuerpo: {'tipo': tipo.valor, 'descripcion': descripcion},
    ) as Map<String, dynamic>;
    return ReporteSalonModel.desdeJson(cuerpo);
  }

  Future<ReporteSalon> cambiarEstadoReporte(
    int salonId,
    int reporteId, {
    required bool resuelto,
  }) async {
    final cuerpo = await _api.patch(
      '/salones/$salonId/reportes/$reporteId',
      cuerpo: {'estado': resuelto ? 'resuelto' : 'abierto'},
    ) as Map<String, dynamic>;
    return ReporteSalonModel.desdeJson(cuerpo);
  }

  Future<List<PrestamoSalon>> listarSolicitudes(int salonId, {String? estado}) async {
    final cuerpo = await _api.get(
      '/prestamos-salon',
      parametros: {
        'salon_id': salonId,
        if (estado != null) 'estado': estado,
        'limit': 100,
      },
    ) as List<dynamic>;
    return cuerpo
        .map((e) => PrestamoSalonModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrestamoSalon> cambiarEstadoSolicitud(int prestamoId, String estado) async {
    final cuerpo = await _api.patch(
      '/prestamos-salon/$prestamoId',
      cuerpo: {'estado': estado},
    ) as Map<String, dynamic>;
    return PrestamoSalonModel.desdeJson(cuerpo);
  }
}

class SalonesAdminRepositoryImpl implements SalonesAdminRepository {
  SalonesAdminRepositoryImpl(this._remoto);
  final SalonesAdminRemoteDataSource _remoto;

  @override
  Future<List<OcupacionSalon>> listarOcupacion() => _remoto.listarOcupacion();

  @override
  Future<OcupacionSalon> obtenerOcupacion(int salonId) => _remoto.obtenerOcupacion(salonId);

  @override
  Future<void> registrarPresencia(int salonId, {required bool presente, String? nota}) =>
      _remoto.registrarPresencia(salonId, presente: presente, nota: nota);

  @override
  Future<List<ReporteSalon>> listarReportes(int salonId, {bool soloAbiertos = false}) =>
      _remoto.listarReportes(salonId, soloAbiertos: soloAbiertos);

  @override
  Future<ReporteSalon> crearReporte(
    int salonId, {
    required TipoReporteSalon tipo,
    required String descripcion,
  }) =>
      _remoto.crearReporte(salonId, tipo: tipo, descripcion: descripcion);

  @override
  Future<ReporteSalon> cambiarEstadoReporte(
    int salonId,
    int reporteId, {
    required bool resuelto,
  }) =>
      _remoto.cambiarEstadoReporte(salonId, reporteId, resuelto: resuelto);

  @override
  Future<List<PrestamoSalon>> listarSolicitudes(int salonId, {String? estado}) =>
      _remoto.listarSolicitudes(salonId, estado: estado);

  @override
  Future<PrestamoSalon> cambiarEstadoSolicitud(int prestamoId, String estado) =>
      _remoto.cambiarEstadoSolicitud(prestamoId, estado);
}

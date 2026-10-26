import '../../../salones/domain/entities/salon.dart';
import '../entities/ocupacion.dart';

/// Contrato de la administración de salones. La UI no sabe de HTTP.
abstract class SalonesAdminRepository {
  /// GET /salones/ocupacion (auxiliar/administrador)
  Future<List<OcupacionSalon>> listarOcupacion();

  /// GET /salones/{id}/ocupacion
  Future<OcupacionSalon> obtenerOcupacion(int salonId);

  /// PUT /salones/{id}/presencia — 409 si no hay clase en curso.
  Future<void> registrarPresencia(int salonId, {required bool presente, String? nota});

  /// GET /salones/{id}/reportes
  Future<List<ReporteSalon>> listarReportes(int salonId, {bool soloAbiertos = false});

  /// POST /salones/{id}/reportes
  Future<ReporteSalon> crearReporte(
    int salonId, {
    required TipoReporteSalon tipo,
    required String descripcion,
  });

  /// PATCH /salones/{id}/reportes/{reporteId}
  Future<ReporteSalon> cambiarEstadoReporte(
    int salonId,
    int reporteId, {
    required bool resuelto,
  });

  /// GET /prestamos-salon?salon_id=&estado=
  Future<List<PrestamoSalon>> listarSolicitudes(int salonId, {String? estado});

  /// PATCH /prestamos-salon/{id}
  Future<PrestamoSalon> cambiarEstadoSolicitud(int prestamoId, String estado);
}

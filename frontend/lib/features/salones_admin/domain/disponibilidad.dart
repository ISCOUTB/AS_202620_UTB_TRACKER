/// Habilitación del salón (manual), sus equipos FIJOS y su historial (ADR-0022).
/// Los equipos NO se prestan: solo cambia su estado (operativo, dañado, en mantenimiento).
library;

enum MotivoDeshabilitacion {
  mantenimiento('mantenimiento', 'Mantenimiento'),
  danio('danio', 'Daño'),
  evento('evento', 'Evento'),
  otro('otro', 'Otro');

  const MotivoDeshabilitacion(this.api, this.etiqueta);
  final String api;
  final String etiqueta;
}

/// Estado de un equipo, con texto además del color (accesible).
enum EstadoEquipo {
  operativo('disponible', 'Operativo'),
  danado('dañado', 'Dañado'),
  mantenimiento('mantenimiento', 'En mantenimiento');

  const EstadoEquipo(this.api, this.etiqueta);
  final String api;
  final String etiqueta;

  /// "prestado" (resto del préstamo de equipos) o un valor desconocido se ven como operativo.
  static EstadoEquipo desde(String? v) => switch (v) {
        'dañado' || 'danado' => EstadoEquipo.danado,
        'mantenimiento' => EstadoEquipo.mantenimiento,
        _ => EstadoEquipo.operativo,
      };
}

class EquipoSalon {
  const EquipoSalon({
    required this.id,
    required this.categoria,
    required this.serial,
    required this.estado,
    this.descripcion,
  });

  final int id;
  final String categoria;
  final String serial;
  final EstadoEquipo estado;
  final String? descripcion;
}

class ReporteEquipoAbierto {
  const ReporteEquipoAbierto({required this.id, required this.descripcion});
  final int id;
  final String descripcion;
}

/// Respuesta al cambiar el estado: si quedó dañado, la app SUGIERE un reporte (no lo abre sola).
class ResultadoEstadoEquipo {
  const ResultadoEstadoEquipo({required this.sugerirReporte, required this.reportesAbiertos});
  final bool sugerirReporte;
  final List<ReporteEquipoAbierto> reportesAbiertos;
}

class EntradaHistorial {
  const EntradaHistorial({
    required this.accion,
    required this.descripcion,
    required this.creadoEn,
    this.actorNombre,
  });
  final String accion;
  final String descripcion;
  final DateTime creadoEn;
  final String? actorNombre;
}

class ResumenPiso {
  const ResumenPiso({
    required this.edificio,
    required this.piso,
    required this.total,
    required this.libres,
    required this.ocupados,
    required this.deshabilitados,
  });
  final String edificio;
  final int? piso;
  final int total;
  final int libres;
  final int ocupados;
  final int deshabilitados;
}

class VistaPreviaLote {
  const VistaPreviaLote({
    required this.salones,
    required this.sinCambio,
    required this.solicitudesAfectadas,
  });
  final List<String> salones;
  final List<String> sinCambio;
  final int solicitudesAfectadas;
}

class PlantillaPorSalon {
  const PlantillaPorSalon({required this.salonNombre, required this.agregar});
  final String salonNombre;
  final Map<String, int> agregar;
}

/// Datos para deshabilitar (motivo obligatorio) o habilitar.
class DatosHabilitacion {
  const DatosHabilitacion({required this.habilitado, this.motivo, this.nota, this.reapertura});
  final bool habilitado;
  final MotivoDeshabilitacion? motivo;
  final String? nota;
  final DateTime? reapertura;
}

abstract class DisponibilidadRepository {
  /// PATCH /salones/{id}/habilitacion. Devuelve cuántas solicitudes quedaron afectadas.
  Future<int> cambiarHabilitacion(int salonId, DatosHabilitacion datos);
  Future<List<EntradaHistorial>> historial(int salonId);
  Future<List<EquipoSalon>> equipos(int salonId);
  Future<ResultadoEstadoEquipo> cambiarEstadoEquipo(int equipoId, EstadoEquipo estado,
      {String? nota, int? reporteSalonId});
  Future<void> agregarEquipo(int salonId, String categoria, String serial);
  Future<void> retirarEquipo(int equipoId);
  Future<List<PlantillaPorSalon>> plantilla(String plantilla, List<int> salonIds,
      {int? computadores, required bool aplicar});
  Future<VistaPreviaLote> lote(String edificio, int? piso, DatosHabilitacion datos,
      {required bool aplicar});
  Future<List<ResumenPiso>> resumen();
  Future<String> exportarCsv();
}

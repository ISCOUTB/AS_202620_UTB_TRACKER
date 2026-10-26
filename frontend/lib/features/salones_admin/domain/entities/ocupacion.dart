/// Entidades de la administración de salones: quién tiene el salón ahora,
/// si el profesor llegó y qué novedades tiene reportadas.
library;
import '../../../salones/domain/entities/salon.dart';

enum Ocupante { libre, clase, prestamo }

/// Cómo se ve el salón en el plano del auxiliar (un solo color por estado).
enum SituacionSalon {
  libre,
  claseConProfesor,
  claseSinConfirmar,
  claseSinProfesor,
  prestado,
  mantenimiento,
  fueraDeServicio,
}

String _hm(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

class ClaseActual {
  const ClaseActual({
    required this.horarioId,
    this.materia,
    this.profesor,
    required this.horaInicio,
    required this.horaFin,
  });

  final int horarioId;
  final String? materia;
  final String? profesor;
  final String horaInicio;
  final String horaFin;

  String get rango => '${_hm(horaInicio)} – ${_hm(horaFin)}';
  String get titulo => (materia == null || materia!.isEmpty) ? 'Clase' : materia!;
  String get nombreProfesor =>
      (profesor == null || profesor!.isEmpty) ? 'Profesor sin asignar' : profesor!;
}

class PrestamoActual {
  const PrestamoActual({
    required this.prestamoId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    this.motivo,
  });

  final int prestamoId;
  final int usuarioId;
  final String usuarioNombre;
  final String estado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? motivo;

  bool get enUso => estado == 'en_uso';
}

class OcupacionSalon {
  const OcupacionSalon({
    required this.salon,
    required this.ocupante,
    this.clase,
    this.prestamo,
    this.profesorPresente,
    this.solicitudesPendientes = 0,
    this.reportesAbiertos = 0,
  });

  final Salon salon;
  final Ocupante ocupante;
  final ClaseActual? clase;
  final PrestamoActual? prestamo;

  /// null = el auxiliar todavía no lo ha confirmado.
  final bool? profesorPresente;
  final int solicitudesPendientes;
  final int reportesAbiertos;

  SituacionSalon get situacion {
    switch (salon.estado.toLowerCase()) {
      case 'mantenimiento':
        return SituacionSalon.mantenimiento;
      case 'fuera_servicio':
        return SituacionSalon.fueraDeServicio;
    }
    switch (ocupante) {
      case Ocupante.clase:
        if (profesorPresente == true) return SituacionSalon.claseConProfesor;
        if (profesorPresente == false) return SituacionSalon.claseSinProfesor;
        return SituacionSalon.claseSinConfirmar;
      case Ocupante.prestamo:
        return SituacionSalon.prestado;
      case Ocupante.libre:
        return SituacionSalon.libre;
    }
  }

  /// Línea principal de la tarjeta: lo primero que el auxiliar quiere saber.
  String get titular {
    switch (situacion) {
      case SituacionSalon.libre:
        return 'Libre ahora';
      case SituacionSalon.claseConProfesor:
      case SituacionSalon.claseSinConfirmar:
      case SituacionSalon.claseSinProfesor:
        return clase?.nombreProfesor ?? 'Clase en curso';
      case SituacionSalon.prestado:
        return prestamo?.usuarioNombre ?? 'Salón prestado';
      case SituacionSalon.mantenimiento:
        return 'En mantenimiento';
      case SituacionSalon.fueraDeServicio:
        return 'Fuera de servicio';
    }
  }

  String get subtitular {
    switch (situacion) {
      case SituacionSalon.libre:
        return salon.detalleUbicacion;
      case SituacionSalon.claseConProfesor:
      case SituacionSalon.claseSinConfirmar:
      case SituacionSalon.claseSinProfesor:
        return '${clase?.titulo ?? 'Clase'} · ${clase?.rango ?? ''}';
      case SituacionSalon.prestado:
        final p = prestamo;
        return p?.motivo?.isNotEmpty == true ? p!.motivo! : 'Préstamo de salón';
      case SituacionSalon.mantenimiento:
      case SituacionSalon.fueraDeServicio:
        return salon.detalleUbicacion;
    }
  }

  /// ¿Hay algo que el auxiliar deba atender? (aparece primero en la lista).
  bool get requiereAtencion =>
      situacion == SituacionSalon.claseSinConfirmar ||
      situacion == SituacionSalon.claseSinProfesor ||
      solicitudesPendientes > 0 ||
      reportesAbiertos > 0;
}

enum TipoReporteSalon {
  limpieza('limpieza', 'Limpieza'),
  equipo('equipo', 'Equipo'),
  infraestructura('infraestructura', 'Infraestructura'),
  seguridad('seguridad', 'Seguridad'),
  otro('otro', 'Otro');

  const TipoReporteSalon(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;

  static TipoReporteSalon desde(String? v) => TipoReporteSalon.values.firstWhere(
        (t) => t.valor == v,
        orElse: () => TipoReporteSalon.otro,
      );
}

class ReporteSalon {
  const ReporteSalon({
    required this.id,
    required this.salonId,
    required this.usuarioId,
    required this.tipo,
    required this.descripcion,
    required this.abierto,
    required this.creadoEn,
    this.resueltoEn,
  });

  final int id;
  final int salonId;
  final int usuarioId;
  final TipoReporteSalon tipo;
  final String descripcion;
  final bool abierto;
  final DateTime creadoEn;
  final DateTime? resueltoEn;
}

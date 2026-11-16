/// Entidades del módulo de Salones, Horarios y Préstamos de Salón (UTB Tracker).
library;

/// Para qué sirve el salón (ADR-0017). Espejo de `TipoSalon` del backend.
enum TipoSalon {
  aula('aula', 'Aula'),
  laboratorioComputo('laboratorio_computo', 'Laboratorio de cómputo'),
  salaAudiovisual('sala_audiovisual', 'Sala audiovisual'),
  auditorio('auditorio', 'Auditorio'),
  salaReuniones('sala_reuniones', 'Sala de reuniones'),
  otro('otro', 'Otro');

  const TipoSalon(this.api, this.etiqueta);
  final String api;
  final String etiqueta;

  static TipoSalon desdeApi(Object? v) =>
      values.firstWhere((t) => t.api == v, orElse: () => TipoSalon.aula);
}

/// Equipamiento CALCULADO por el servidor desde los recursos activos del salón.
class EquipoCategoria {
  const EquipoCategoria({required this.categoria, required this.total, required this.operativos});

  final String categoria;
  final int total;
  final int operativos;

  /// Dañados o en mantenimiento.
  int get fueraDeServicio => total - operativos;
}

class Salon {
  const Salon({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.edificio,
    this.piso,
    required this.capacidad,
    required this.estado,
    this.activo = true,
    this.tipo = TipoSalon.aula,
    this.descripcion,
    this.equipamiento = const [],
    this.tipoSugerido,
  });

  final TipoSalon tipo;
  final String? descripcion;
  final List<EquipoCategoria> equipamiento;

  /// Sugerencia del servidor (p. ej. 8+ computadores -> laboratorio). Nunca cambia el tipo sola.
  final TipoSalon? tipoSugerido;

  /// Cantidad operativa de una categoría (para filtros y chips).
  int operativos(String categoria) =>
      equipamiento.where((e) => e.categoria == categoria).fold(0, (a, e) => a + e.operativos);

  final int id;
  final String nombre;
  final String ubicacion;
  final String? edificio;
  final int? piso;
  final int capacidad;
  final String estado;
  final bool activo;

  bool get disponible => estado.toLowerCase() == 'disponible';

  String get detalleUbicacion {
    final partes = <String>[ubicacion];
    if (edificio != null && edificio!.isNotEmpty) partes.add('Edif. $edificio');
    if (piso != null) partes.add('Piso $piso');
    return partes.join(' · ');
  }
}

class FranjaDisponible {
  const FranjaDisponible({
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final int diaSemana;
  final String horaInicio;
  final String horaFin;

  String get diaNombre => switch (diaSemana) {
        1 => 'Lunes',
        2 => 'Martes',
        3 => 'Miércoles',
        4 => 'Jueves',
        5 => 'Viernes',
        6 => 'Sábado',
        7 => 'Domingo',
        _ => 'Día $diaSemana',
      };

  String get rango => '$horaInicio - $horaFin';
}

class Horario {
  const Horario({
    required this.id,
    required this.salonId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.profesor,
    this.materia,
    this.semestre,
    this.activo = true,
  });

  final int id;
  final int salonId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String? profesor;
  final String? materia;
  final String? semestre;
  final bool activo;

  String get diaNombre => switch (diaSemana) {
        1 => 'Lunes',
        2 => 'Martes',
        3 => 'Miércoles',
        4 => 'Jueves',
        5 => 'Viernes',
        6 => 'Sábado',
        7 => 'Domingo',
        _ => 'Día $diaSemana',
      };
}

class PrestamoSalon {
  const PrestamoSalon({
    required this.id,
    required this.salonId,
    required this.usuarioId,
    required this.fechaInicio,
    required this.fechaFin,
    this.motivo,
    required this.estado,
    required this.createdAt,
    this.salonNombre,
    this.usuarioNombre,
    this.respuesta,
    this.atendidoPorNombre,
    this.atendidoEn,
    this.conflicto,
  });

  final int id;
  final int salonId;
  final int usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? motivo;
  final String estado;
  final DateTime createdAt;

  /// Código real del salón ("A4-204") y nombre de quien lo pidió.
  final String? salonNombre;
  final String? usuarioNombre;

  /// ADR-0018: motivo del rechazo o nota al aprobar, quién la atendió y cuándo.
  final String? respuesta;
  final String? atendidoPorNombre;
  final DateTime? atendidoEn;

  /// Solo en la bandeja del auditor: con qué choca la franja (null = libre).
  final String? conflicto;

  String get salonTexto => salonNombre ?? 'Salón';
  bool get pendiente => estado == 'pendiente';

  /// Texto para mostrar (no depender solo del color, accesibilidad).
  String get estadoTexto => switch (estado) {
        'pendiente' => 'Pendiente',
        'aprobado' => 'Aprobada',
        'rechazado' => 'Rechazada',
        'cancelado' => 'Cancelada',
        'en_uso' => 'En uso',
        'finalizado' => 'Finalizada',
        _ => estado,
      };
}

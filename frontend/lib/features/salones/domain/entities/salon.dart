/// Entidades del módulo de Salones, Horarios y Préstamos de Salón (UTB Tracker).

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
  });

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
  });

  final int id;
  final int salonId;
  final int usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? motivo;
  final String estado;
  final DateTime createdAt;
}

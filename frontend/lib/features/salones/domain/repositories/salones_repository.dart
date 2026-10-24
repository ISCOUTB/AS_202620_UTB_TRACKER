import '../entities/salon.dart';

abstract class SalonesRepository {
  /// GET /salones
  Future<List<Salon>> listarSalones();

  /// GET /salones/{id}
  Future<Salon> obtenerSalon(int id);

  /// POST /salones
  Future<Salon> crearSalon({
    required String nombre,
    required String ubicacion,
    String? edificio,
    int? piso,
    required int capacidad,
  });

  /// GET /salones/{id}/disponibilidad?dia_semana={dia}
  Future<List<FranjaDisponible>> consultarDisponibilidad(
    int salonId, {
    int? diaSemana,
  });

  /// GET /horarios?salon_id={id}
  Future<List<Horario>> listarHorarios(int salonId);

  /// POST /horarios
  Future<Horario> crearHorario({
    required int salonId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    String? profesor,
    String? materia,
    String? semestre,
  });

  /// POST /prestamos-salon
  Future<PrestamoSalon> solicitarPrestamoSalon({
    required int salonId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivo,
  });

  /// GET /prestamos-salon
  Future<List<PrestamoSalon>> listarPrestamosSalon();

  /// PATCH /prestamos-salon/{id}
  Future<PrestamoSalon> actualizarEstadoPrestamo(int id, String estado);
}

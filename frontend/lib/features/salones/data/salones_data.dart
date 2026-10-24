import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';
import '../domain/entities/salon.dart';
import '../domain/repositories/salones_repository.dart';

class SalonModel {
  SalonModel._();

  static Salon desdeJson(Map<String, dynamic> j) => Salon(
        id: (j['id'] as num).toInt(),
        nombre: (j['nombre'] ?? '').toString(),
        ubicacion: (j['ubicacion'] ?? '').toString(),
        edificio: j['edificio']?.toString(),
        piso: j['piso'] == null ? null : (j['piso'] as num).toInt(),
        capacidad: (j['capacidad'] as num).toInt(),
        estado: (j['estado'] ?? 'disponible').toString(),
        activo: j['activo'] as bool? ?? true,
      );
}

class FranjaDisponibleModel {
  FranjaDisponibleModel._();

  static FranjaDisponible desdeJson(Map<String, dynamic> j) => FranjaDisponible(
        diaSemana: (j['dia_semana'] as num).toInt(),
        horaInicio: (j['hora_inicio'] ?? '').toString(),
        horaFin: (j['hora_fin'] ?? '').toString(),
      );
}

class HorarioModel {
  HorarioModel._();

  static Horario desdeJson(Map<String, dynamic> j) => Horario(
        id: (j['id'] as num).toInt(),
        salonId: (j['salon_id'] as num).toInt(),
        diaSemana: (j['dia_semana'] as num).toInt(),
        horaInicio: (j['hora_inicio'] ?? '').toString(),
        horaFin: (j['hora_fin'] ?? '').toString(),
        profesor: j['profesor']?.toString(),
        materia: j['materia']?.toString(),
        semestre: j['semestre']?.toString(),
        activo: j['activo'] as bool? ?? true,
      );
}

class PrestamoSalonModel {
  PrestamoSalonModel._();

  static PrestamoSalon desdeJson(Map<String, dynamic> j) => PrestamoSalon(
        id: (j['id'] as num).toInt(),
        salonId: (j['salon_id'] as num).toInt(),
        usuarioId: (j['usuario_id'] as num).toInt(),
        fechaInicio: parsearFechaServidor(j['fecha_inicio'].toString()),
        fechaFin: parsearFechaServidor(j['fecha_fin'].toString()),
        motivo: j['motivo']?.toString(),
        estado: (j['estado'] ?? 'pendiente').toString(),
        createdAt: j['created_at'] != null
            ? parsearFechaServidor(j['created_at'].toString())
            : DateTime.now(),
      );
}

class SalonesRemoteDataSource {
  SalonesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Salon>> listarSalones() async {
    final cuerpo = await _api.get('/salones') as List<dynamic>;
    return cuerpo
        .map((e) => SalonModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Salon> obtenerSalon(int id) async {
    final cuerpo = await _api.get('/salones/$id') as Map<String, dynamic>;
    return SalonModel.desdeJson(cuerpo);
  }

  Future<Salon> crearSalon({
    required String nombre,
    required String ubicacion,
    String? edificio,
    int? piso,
    required int capacidad,
  }) async {
    final cuerpo = await _api.post(
      '/salones',
      cuerpo: {
        'nombre': nombre,
        'ubicacion': ubicacion,
        if (edificio != null && edificio.isNotEmpty) 'edificio': edificio,
        if (piso != null) 'piso': piso,
        'capacidad': capacidad,
      },
    ) as Map<String, dynamic>;
    return SalonModel.desdeJson(cuerpo);
  }

  Future<List<FranjaDisponible>> consultarDisponibilidad(
    int salonId, {
    int? diaSemana,
  }) async {
    final query = diaSemana != null ? '?dia_semana=$diaSemana' : '';
    final cuerpo = await _api.get('/salones/$salonId/disponibilidad$query') as List<dynamic>;
    return cuerpo
        .map((e) => FranjaDisponibleModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Horario>> listarHorarios(int salonId) async {
    final cuerpo = await _api.get('/horarios?salon_id=$salonId') as List<dynamic>;
    return cuerpo
        .map((e) => HorarioModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Horario> crearHorario({
    required int salonId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    String? profesor,
    String? materia,
    String? semestre,
  }) async {
    final cuerpo = await _api.post(
      '/horarios',
      cuerpo: {
        'salon_id': salonId,
        'dia_semana': diaSemana,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        if (profesor != null && profesor.isNotEmpty) 'profesor': profesor,
        if (materia != null && materia.isNotEmpty) 'materia': materia,
        if (semestre != null && semestre.isNotEmpty) 'semestre': semestre,
      },
    ) as Map<String, dynamic>;
    return HorarioModel.desdeJson(cuerpo);
  }

  Future<PrestamoSalon> solicitarPrestamoSalon({
    required int salonId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivo,
  }) async {
    final cuerpo = await _api.post(
      '/prestamos-salon',
      cuerpo: {
        'salon_id': salonId,
        'fecha_inicio': fechaParaServidor(fechaInicio),
        'fecha_fin': fechaParaServidor(fechaFin),
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      },
    ) as Map<String, dynamic>;
    return PrestamoSalonModel.desdeJson(cuerpo);
  }

  Future<List<PrestamoSalon>> listarPrestamosSalon() async {
    final cuerpo = await _api.get('/prestamos-salon') as List<dynamic>;
    return cuerpo
        .map((e) => PrestamoSalonModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrestamoSalon> actualizarEstadoPrestamo(int id, String estado) async {
    final cuerpo = await _api.patch(
      '/prestamos-salon/$id',
      cuerpo: {'estado': estado},
    ) as Map<String, dynamic>;
    return PrestamoSalonModel.desdeJson(cuerpo);
  }
}

class SalonesRepositoryImpl implements SalonesRepository {
  SalonesRepositoryImpl(this._remoto);
  final SalonesRemoteDataSource _remoto;

  @override
  Future<List<Salon>> listarSalones() => _remoto.listarSalones();

  @override
  Future<Salon> obtenerSalon(int id) => _remoto.obtenerSalon(id);

  @override
  Future<Salon> crearSalon({
    required String nombre,
    required String ubicacion,
    String? edificio,
    int? piso,
    required int capacidad,
  }) =>
      _remoto.crearSalon(
        nombre: nombre,
        ubicacion: ubicacion,
        edificio: edificio,
        piso: piso,
        capacidad: capacidad,
      );

  @override
  Future<List<FranjaDisponible>> consultarDisponibilidad(
    int salonId, {
    int? diaSemana,
  }) =>
      _remoto.consultarDisponibilidad(salonId, diaSemana: diaSemana);

  @override
  Future<List<Horario>> listarHorarios(int salonId) =>
      _remoto.listarHorarios(salonId);

  @override
  Future<Horario> crearHorario({
    required int salonId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    String? profesor,
    String? materia,
    String? semestre,
  }) =>
      _remoto.crearHorario(
        salonId: salonId,
        diaSemana: diaSemana,
        horaInicio: horaInicio,
        horaFin: horaFin,
        profesor: profesor,
        materia: materia,
        semestre: semestre,
      );

  @override
  Future<PrestamoSalon> solicitarPrestamoSalon({
    required int salonId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivo,
  }) =>
      _remoto.solicitarPrestamoSalon(
        salonId: salonId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: motivo,
      );

  @override
  Future<List<PrestamoSalon>> listarPrestamosSalon() =>
      _remoto.listarPrestamosSalon();

  @override
  Future<PrestamoSalon> actualizarEstadoPrestamo(int id, String estado) =>
      _remoto.actualizarEstadoPrestamo(id, estado);
}

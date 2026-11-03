import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../domain/entities/salon.dart';
import '../domain/repositories/salones_repository.dart';

class SalonesController extends ChangeNotifier {
  SalonesController(this._repo);

  final SalonesRepository _repo;

  List<Salon> _todos = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  String _busqueda = '';

  Carga get carga => _carga;
  String? get error => _error;
  List<Salon> get todos => _todos;
  String get busqueda => _busqueda;

  void fijarBusqueda(String q) {
    _busqueda = q.trim();
    notifyListeners();
  }

  List<Salon> get filtrados {
    final q = _busqueda.toLowerCase();
    if (q.isEmpty) return _todos;
    return _todos.where((s) {
      final texto = '${s.nombre} ${s.ubicacion} ${s.edificio ?? ""} ${s.estado}'.toLowerCase();
      return texto.contains(q);
    }).toList();
  }

  Salon? porId(int id) {
    for (final s in _todos) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Obtiene el estado fresco de un salón directamente del backend.
  /// Retorna [null] si falla (no lanza excepción).
  Future<Salon?> obtenerSalonPorId(int id) async {
    try {
      return await _repo.obtenerSalon(id);
    } catch (_) {
      return null;
    }
  }

  /// Lista todos los préstamos del endpoint y los filtra por [salonId].
  /// Retorna una tupla (lista, mensajeError?).
  Future<(List<PrestamoSalon>, String?)> obtenerPrestamosSalon(int salonId) async {
    try {
      final todos = await _repo.listarPrestamosSalon();
      return (todos.where((p) => p.salonId == salonId).toList(), null);
    } on ApiException catch (e) {
      return (const <PrestamoSalon>[], e.mensaje);
    } catch (_) {
      return (const <PrestamoSalon>[], 'No se pudieron cargar los préstamos');
    }
  }

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      _todos = await _repo.listarSalones();
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      if (!(silencioso && _todos.isNotEmpty)) {
        _carga = Carga.error;
        _error = e.mensaje;
      }
    } catch (_) {
      if (!(silencioso && _todos.isNotEmpty)) {
        _carga = Carga.error;
        _error = 'No se pudieron cargar los salones';
      }
    }
    notifyListeners();
  }

  Future<String?> crear({
    required String nombre,
    required String ubicacion,
    String? edificio,
    int? piso,
    required int capacidad,
  }) async {
    try {
      final nuevo = await _repo.crearSalon(
        nombre: nombre.trim(),
        ubicacion: ubicacion.trim(),
        edificio: edificio?.trim(),
        piso: piso,
        capacidad: capacidad,
      );
      _todos = [..._todos, nuevo];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo crear el salón';
    }
  }

  /// Retorna la disponibilidad del salón; lanza el error como [String] en lugar de
  /// silenciarlo, para que la UI pueda mostrarlo al usuario.
  Future<(List<FranjaDisponible>, String?)> obtenerDisponibilidad(
    int salonId, {
    int? diaSemana,
  }) async {
    try {
      final franjas = await _repo.consultarDisponibilidad(salonId, diaSemana: diaSemana);
      return (franjas, null);
    } on ApiException catch (e) {
      return (const <FranjaDisponible>[], e.mensaje);
    } catch (_) {
      return (const <FranjaDisponible>[], 'No se pudo consultar la disponibilidad');
    }
  }

  /// Retorna los horarios del salón; propaga error en lugar de silenciarlo.
  Future<(List<Horario>, String?)> obtenerHorarios(int salonId) async {
    try {
      final horarios = await _repo.listarHorarios(salonId);
      return (horarios, null);
    } on ApiException catch (e) {
      return (const <Horario>[], e.mensaje);
    } catch (_) {
      return (const <Horario>[], 'No se pudieron cargar los horarios');
    }
  }

  Future<String?> agregarHorario({
    required int salonId,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
    String? profesor,
    String? materia,
    String? semestre,
  }) async {
    try {
      await _repo.crearHorario(
        salonId: salonId,
        diaSemana: diaSemana,
        horaInicio: horaInicio,
        horaFin: horaFin,
        profesor: profesor,
        materia: materia,
        semestre: semestre,
      );
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'Error al registrar el horario';
    }
  }

  Future<String?> solicitarPrestamo({
    required int salonId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivo,
  }) async {
    try {
      await _repo.solicitarPrestamoSalon(
        salonId: salonId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: motivo,
      );
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'Error al solicitar préstamo de salón';
    }
  }

  /// Cancela una solicitud de préstamo pendiente que le pertenece al usuario actual.
  /// Retorna [null] si tuvo éxito, o el mensaje de error en caso contrario.
  Future<String?> cancelarPrestamoSalon(int id) async {
    try {
      await _repo.cancelarPrestamoSalon(id);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo cancelar el préstamo';
    }
  }
}

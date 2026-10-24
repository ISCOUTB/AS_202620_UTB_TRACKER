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

  Future<List<FranjaDisponible>> obtenerDisponibilidad(int salonId, {int? diaSemana}) async {
    try {
      return await _repo.consultarDisponibilidad(salonId, diaSemana: diaSemana);
    } catch (_) {
      return [];
    }
  }

  Future<List<Horario>> obtenerHorarios(int salonId) async {
    try {
      return await _repo.listarHorarios(salonId);
    } catch (_) {
      return [];
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
}

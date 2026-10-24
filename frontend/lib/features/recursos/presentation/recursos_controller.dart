import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../domain/entities/recurso.dart';
import '../domain/repositories/recursos_repository.dart';

class RecursosController extends ChangeNotifier {
  RecursosController(this._repo);

  final RecursosRepository _repo;

  List<Recurso> _todos = const [];
  Carga _carga = Carga.inicial;
  String? _error;

  // Filtros de la pantalla "Equipos"
  String _busqueda = '';
  CategoriaRecurso? _categoria;
  EstadoRecurso? _estado;
  String? _salon;

  // Último equipo consultado (tarjeta "Reciente" del inicio)
  Recurso? _reciente;

  Carga get carga => _carga;
  String? get error => _error;
  List<Recurso> get todos => _todos;
  String get busqueda => _busqueda;
  CategoriaRecurso? get categoria => _categoria;
  EstadoRecurso? get estado => _estado;
  String? get salon => _salon;
  Recurso? get reciente => _reciente;

  bool get hayFiltros =>
      _busqueda.isNotEmpty ||
      _categoria != null ||
      _estado != null ||
      _salon != null;

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      _todos = await _repo.listar();
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      // Si ya había datos y falla un refresco silencioso, se conservan los que hay.
      if (!(silencioso && _todos.isNotEmpty)) {
        _carga = Carga.error;
        _error = e.mensaje;
      }
    }
    notifyListeners();
  }

  /// Crea un recurso (auxiliar). Devuelve el mensaje de error o null si salió bien.
  Future<String?> crear({
    required String categoria,
    required String salonId,
    required String serial,
  }) async {
    try {
      final nuevo = await _repo.crear(
        categoria: categoria,
        salonId: salonId.trim(),
        serial: serial.trim(),
      );
      _todos = [..._todos, nuevo];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  /// Reporta el estado de un recurso (p. ej. dañado, mantenimiento) con imagen opcional.
  Future<String?> reportar({
    required int recursoId,
    required String estadoReportado,
    String? descripcion,
    String? imagenUrl,
  }) async {
    try {
      await _repo.reportar(
        recursoId: recursoId,
        estadoReportado: estadoReportado,
        descripcion: descripcion,
        imagenUrl: imagenUrl,
      );
      await cargar(silencioso: true);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo registrar el reporte';
    }
  }

  void marcarReciente(Recurso r) {
    _reciente = r;
    notifyListeners();
  }

  // --- filtros ---
  void fijarBusqueda(String v) {
    _busqueda = v.trim();
    notifyListeners();
  }

  void fijarCategoria(CategoriaRecurso? c) {
    _categoria = c;
    notifyListeners();
  }

  void fijarEstado(EstadoRecurso? e) {
    _estado = e;
    notifyListeners();
  }

  void fijarSalon(String? s) {
    _salon = s;
    notifyListeners();
  }

  void limpiarFiltros() {
    _busqueda = '';
    _categoria = null;
    _estado = null;
    _salon = null;
    notifyListeners();
  }

  // --- derivados ---
  List<Recurso> get filtrados {
    final q = _busqueda.toLowerCase();
    return _todos.where((r) {
      if (_categoria != null && r.categoria != _categoria) return false;
      if (_estado != null && r.estado != _estado) return false;
      if (_salon != null && r.salonId != _salon) return false;
      if (q.isNotEmpty) {
        final texto =
            '${r.serial} ${r.salonId} ${r.categoria.etiqueta} ${r.estado.etiqueta}'
                .toLowerCase();
        if (!texto.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<String> get salones {
    final s = _todos.map((r) => r.salonId).toSet().toList()..sort();
    return s;
  }

  int disponiblesDe(CategoriaRecurso c) =>
      _todos.where((r) => r.categoria == c && r.disponible).length;

  int get totalDisponibles => _todos.where((r) => r.disponible).length;

  int get totalFueraDeServicio => _todos
      .where((r) =>
          r.estado == EstadoRecurso.danado ||
          r.estado == EstadoRecurso.mantenimiento)
      .length;

  Recurso? porId(int id) {
    for (final r in _todos) {
      if (r.id == id) return r;
    }
    return null;
  }
}

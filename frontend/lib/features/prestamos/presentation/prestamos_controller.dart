import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../domain/entities/prestamo.dart';
import '../domain/repositories/prestamos_repository.dart';

/// Resultado de intentar registrar un préstamo, listo para pintar en la UI.
class ResultadoPrestamo {
  const ResultadoPrestamo.exito(this.prestamo)
      : error = null,
        recursoYaNoDisponible = false;
  const ResultadoPrestamo.fallo(this.error, {this.recursoYaNoDisponible = false})
      : prestamo = null;

  final Prestamo? prestamo;
  final String? error;

  /// 409: otro auxiliar/usuario lo prestó primero (escenario QS-06).
  final bool recursoYaNoDisponible;

  bool get ok => prestamo != null;
}

class PrestamosController extends ChangeNotifier {
  PrestamosController(this._repo);

  final PrestamosRepository _repo;

  List<Prestamo> _todos = const [];
  Carga _carga = Carga.inicial;
  String? _error;

  Carga get carga => _carga;
  String? get error => _error;
  List<Prestamo> get todos => _todos;

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      final lista = await _repo.listar();
      lista.sort((a, b) => b.fechaPrestamo.compareTo(a.fechaPrestamo));
      _todos = lista;
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      if (!(silencioso && _todos.isNotEmpty)) {
        _carga = Carga.error;
        _error = e.mensaje;
      }
    }
    notifyListeners();
  }

  /// [claveIdempotencia] se genera al abrir el formulario y se REUTILIZA si el usuario reintenta
  /// tras un error de red: así un reintento nunca duplica el préstamo (S11 req. 11.3).
  Future<ResultadoPrestamo> solicitar({
    required int recursoId,
    required int usuarioId,
    required DateTime fechaDevolucionEsperada,
    required String claveIdempotencia,
  }) async {
    try {
      final nuevo = await _repo.crear(
        recursoId: recursoId,
        usuarioId: usuarioId,
        fechaDevolucionEsperada: fechaDevolucionEsperada,
        claveIdempotencia: claveIdempotencia,
      );
      _todos = [nuevo, ..._todos.where((p) => p.id != nuevo.id)];
      notifyListeners();
      return ResultadoPrestamo.exito(nuevo);
    } on ApiException catch (e) {
      return ResultadoPrestamo.fallo(
        e.mensaje,
        recursoYaNoDisponible: e.tipo == TipoError.conflicto,
      );
    }
  }

  /// PATCH /prestamos/{id}/devolver: Devuelve el recurso y lo restaura a 'disponible'.
  Future<bool> devolver(int prestamoId) async {
    try {
      final devuelto = await _repo.devolver(prestamoId);
      _todos = _todos.map((p) => p.id == prestamoId ? devuelto : p).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'No se pudo procesar la devolución';
      notifyListeners();
      return false;
    }
  }

  // --- derivados ---
  List<Prestamo> deUsuario(int usuarioId) =>
      _todos.where((p) => p.usuarioId == usuarioId).toList();

  List<Prestamo> historialDeRecurso(int recursoId) =>
      _todos.where((p) => p.recursoId == recursoId).toList();

  List<Prestamo> filtrarPorEstado(
    Iterable<Prestamo> base,
    EstadoPrestamo estado, {
    DateTime? ahora,
  }) {
    final t = ahora ?? DateTime.now();
    return base.where((p) => p.estadoEn(t) == estado).toList();
  }

  int vencidos(Iterable<Prestamo> base, {DateTime? ahora}) =>
      filtrarPorEstado(base, EstadoPrestamo.vencido, ahora: ahora).length;
}

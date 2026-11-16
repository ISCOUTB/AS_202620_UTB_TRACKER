import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../../shared/sin_acceso.dart';
import '../../salones/domain/entities/salon.dart';
import '../data/solicitudes_data.dart';

/// Estado de una lista de solicitudes (ADR-0018). Dos instancias en DI:
/// "mías" (Estudiante) y "bandeja" (Auditor/Administrador).
class SolicitudesController extends ChangeNotifier {
  SolicitudesController(this._repo, {required this.bandeja, Future<void> Function()? onSinPermiso})
      : _onSinPermiso = onSinPermiso ?? alPerderPermiso;

  final SolicitudesRepository _repo;
  final Future<void> Function() _onSinPermiso;

  /// true = bandeja del auditor; false = mis solicitudes.
  final bool bandeja;

  List<PrestamoSalon> _items = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  bool _sinAcceso = false;

  /// Filtro de estado ('pendiente' por defecto en la bandeja; null = todos en "mías").
  String? _estado;

  List<PrestamoSalon> get items => _items;
  Carga get carga => _carga;
  String? get error => _error;
  bool get sinAcceso => _sinAcceso;
  String? get estado => _estado;

  List<PrestamoSalon> get pendientes => _items.where((s) => s.pendiente).toList();
  int contar(String estado) => _items.where((s) => s.estado == estado).length;

  /// Respuestas recientes (últimos 7 días) para el aviso del Inicio del estudiante.
  List<PrestamoSalon> novedades({DateTime? ahora}) {
    final desde = (ahora ?? DateTime.now()).subtract(const Duration(days: 7));
    return _items
        .where((s) => s.atendidoEn != null && s.atendidoEn!.isAfter(desde))
        .toList()
      ..sort((a, b) => b.atendidoEn!.compareTo(a.atendidoEn!));
  }

  /// Lo que se ve con el filtro actual (en "mías" el filtro es local).
  List<PrestamoSalon> get visibles =>
      bandeja || _estado == null ? _items : _items.where((s) => s.estado == _estado).toList();

  Future<void> fijarEstado(String? estado) async {
    _estado = estado;
    notifyListeners();
    if (bandeja) await cargar();
  }

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      _items = bandeja
          ? await _repo.bandeja(estado: _estado ?? 'pendiente')
          : await _repo.mias();
      _carga = Carga.ok;
      _error = null;
      _sinAcceso = false;
    } catch (e) {
      if (esSinPermiso(e)) {
        _sinAcceso = true;
        _carga = Carga.ok;
        await _onSinPermiso();
      } else if (!(silencioso && _items.isNotEmpty)) {
        _carga = Carga.error;
        _error = e is ApiException ? e.mensaje : 'No se pudieron cargar las solicitudes';
      }
    }
    notifyListeners();
  }

  Future<String?> _accion(Future<void> Function() f) async {
    try {
      await f();
      await cargar(silencioso: true);
      return null;
    } catch (e) {
      if (esSinPermiso(e)) {
        _sinAcceso = true;
        notifyListeners();
        await _onSinPermiso();
      }
      return e is ApiException ? e.mensaje : 'No se pudo completar la acción';
    }
  }

  Future<String?> cancelar(PrestamoSalon s) => _accion(() => _repo.cancelar(s.id));

  Future<String?> aprobar(PrestamoSalon s, {String? nota}) =>
      _accion(() => _repo.aprobar(s.id, nota: nota));

  Future<String?> rechazar(PrestamoSalon s, String motivo) =>
      _accion(() => _repo.rechazar(s.id, motivo));

  /// Al cerrar sesión o cambiar de rol (modo prueba), no se muestran datos del anterior.
  void limpiar() {
    _items = const [];
    _carga = Carga.inicial;
    _error = null;
    _sinAcceso = false;
    _estado = null;
    notifyListeners();
  }
}

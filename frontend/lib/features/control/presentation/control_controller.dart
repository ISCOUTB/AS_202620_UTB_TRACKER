import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../salones/domain/entities/salon.dart';
import '../../salones_admin/domain/entities/ocupacion.dart';
import '../../salones_admin/domain/repositories/salones_admin_repository.dart';

/// Estado de la pestaña "Control": solicitudes de salón y reportes de novedades.
/// Reemplaza a la antigua "Actividad" de préstamos de equipos (ADR-0010: los equipos no se
/// prestan, se controlan).
class ControlController extends ChangeNotifier {
  ControlController(this._repo);

  final SalonesAdminRepository _repo;

  List<PrestamoSalon> _solicitudes = const [];
  List<ReporteSalon> _reportes = const [];
  Carga _carga = Carga.inicial;
  String? _error;

  Carga get carga => _carga;
  String? get error => _error;
  List<ReporteSalon> get reportes => _reportes;

  List<PrestamoSalon> get pendientes => _solicitudes.where((s) => s.pendiente).toList();
  List<PrestamoSalon> get resueltas => _solicitudes.where((s) => !s.pendiente).toList();
  List<ReporteSalon> get reportesAbiertos => _reportes.where((r) => r.abierto).toList();

  /// [conReportes]: solo el auxiliar puede listar los reportes de todos los salones.
  Future<void> cargar({required bool conReportes, bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      final r = await Future.wait([
        _repo.listarTodasLasSolicitudes(),
        if (conReportes) _repo.listarTodosLosReportes(),
      ]);
      _solicitudes = (r[0] as List<PrestamoSalon>)
        ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
      _reportes = conReportes ? r[1] as List<ReporteSalon> : const [];
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      if (!(silencioso && _solicitudes.isNotEmpty)) {
        _carga = Carga.error;
        _error = e.mensaje;
      }
    } catch (_) {
      if (!(silencioso && _solicitudes.isNotEmpty)) {
        _carga = Carga.error;
        _error = 'No se pudo cargar el control';
      }
    }
    notifyListeners();
  }

  Future<String?> _accion(Future<void> Function() f, {required bool conReportes}) async {
    try {
      await f();
      await cargar(conReportes: conReportes, silencioso: true);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo completar la acción';
    }
  }

  /// aprobado | rechazado | cancelado
  Future<String?> cambiarSolicitud(PrestamoSalon s, String estado, {required bool conReportes}) =>
      _accion(() => _repo.cambiarEstadoSolicitud(s.id, estado), conReportes: conReportes);

  Future<String?> resolverReporte(ReporteSalon r) => _accion(
        () => _repo.cambiarEstadoReporte(r.salonId, r.id, resuelto: true),
        conReportes: true,
      );
}

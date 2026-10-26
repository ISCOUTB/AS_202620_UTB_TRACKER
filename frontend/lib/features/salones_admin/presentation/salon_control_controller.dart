import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../auth/domain/auth_domain.dart';
import '../../salones/domain/entities/salon.dart';
import '../domain/entities/ocupacion.dart';
import '../domain/repositories/salones_admin_repository.dart';

/// Estado de la pantalla de control de UN salón: quién lo tiene, solicitudes y reportes.
class SalonControlController extends ChangeNotifier {
  SalonControlController(this._repo, this._auth, this.salonId);

  final SalonesAdminRepository _repo;
  final AuthRepository _auth;
  final int salonId;

  OcupacionSalon? _ocupacion;
  List<ReporteSalon> _reportes = const [];
  List<PrestamoSalon> _solicitudes = const [];
  final Map<int, String> _nombres = {};
  Carga _carga = Carga.inicial;
  String? _error;

  Carga get carga => _carga;
  String? get error => _error;
  OcupacionSalon? get ocupacion => _ocupacion;
  List<ReporteSalon> get reportes => _reportes;
  List<ReporteSalon> get reportesAbiertos => _reportes.where((r) => r.abierto).toList();
  List<PrestamoSalon> get solicitudes => _solicitudes;

  /// Solicitudes que esperan decisión del auxiliar.
  List<PrestamoSalon> get pendientes =>
      _solicitudes.where((s) => s.estado == 'pendiente').toList();

  /// Solicitudes aprobadas o en uso que todavía no terminan.
  List<PrestamoSalon> get vigentes => _solicitudes
      .where((s) => s.estado == 'aprobado' || s.estado == 'en_uso')
      .toList()
    ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

  String nombreDe(int usuarioId) => _nombres[usuarioId] ?? 'Usuario #$usuarioId';

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      final resultados = await Future.wait<Object>([
        _repo.obtenerOcupacion(salonId),
        _repo.listarReportes(salonId),
        _repo.listarSolicitudes(salonId),
      ]);
      _ocupacion = resultados[0] as OcupacionSalon;
      _reportes = resultados[1] as List<ReporteSalon>;
      _solicitudes = resultados[2] as List<PrestamoSalon>;
      _carga = Carga.ok;
      _error = null;
      notifyListeners();
      await _resolverNombres();
    } on ApiException catch (e) {
      _fallar(silencioso, e.mensaje);
    } catch (_) {
      _fallar(silencioso, 'No se pudo cargar el salón');
    }
  }

  void _fallar(bool silencioso, String mensaje) {
    if (!(silencioso && _ocupacion != null)) {
      _carga = Carga.error;
      _error = mensaje;
    }
    notifyListeners();
  }

  /// Busca el nombre de cada solicitante una sola vez (la solicitud solo trae su id).
  Future<void> _resolverNombres() async {
    final ids = {
      ..._solicitudes.map((s) => s.usuarioId),
      ..._reportes.map((r) => r.usuarioId),
    }..removeWhere(_nombres.containsKey);
    if (ids.isEmpty) return;
    for (final id in ids) {
      try {
        _nombres[id] = (await _auth.obtenerUsuario(id)).nombre;
      } catch (_) {
        // Si falla se queda "Usuario #id"; no vale la pena bloquear la pantalla.
      }
    }
    notifyListeners();
  }

  Future<String?> _accion(Future<void> Function() hacer, String falla) async {
    try {
      await hacer();
      await cargar(silencioso: true);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return falla;
    }
  }

  Future<String?> confirmarProfesor({required bool presente, String? nota}) => _accion(
        () => _repo.registrarPresencia(salonId, presente: presente, nota: nota),
        'No se pudo registrar la presencia del profesor',
      );

  Future<String?> decidirSolicitud(int prestamoId, String estado) => _accion(
        () => _repo.cambiarEstadoSolicitud(prestamoId, estado),
        'No se pudo actualizar la solicitud',
      );

  Future<String?> reportar(TipoReporteSalon tipo, String descripcion) => _accion(
        () => _repo.crearReporte(salonId, tipo: tipo, descripcion: descripcion),
        'No se pudo enviar el reporte',
      );

  Future<String?> resolverReporte(int reporteId, {bool resuelto = true}) => _accion(
        () => _repo.cambiarEstadoReporte(salonId, reporteId, resuelto: resuelto),
        'No se pudo actualizar el reporte',
      );
}

import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../../shared/sin_acceso.dart';
import '../data/admin_data.dart';

String _mensaje(Object e, String porDefecto) => e is ApiException ? e.mensaje : porDefecto;

/// Pantalla Usuarios del administrador (ADR-0018): búsqueda, filtro por rol, cambiar rol y
/// activar/desactivar. Las reglas (último administrador, uno mismo) las aplica el servidor.
class UsuariosController extends ChangeNotifier {
  UsuariosController(this._repo, {Future<void> Function()? onSinPermiso})
      : _onSinPermiso = onSinPermiso ?? alPerderPermiso;

  final AdminRepository _repo;
  final Future<void> Function() _onSinPermiso;

  List<UsuarioAdmin> _usuarios = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  bool _sinAcceso = false;
  String _busqueda = '';
  String? _rol;

  List<UsuarioAdmin> get usuarios => _usuarios;
  Carga get carga => _carga;
  String? get error => _error;
  bool get sinAcceso => _sinAcceso;
  String? get rol => _rol;
  String get busqueda => _busqueda;

  Future<void> buscar(String texto) {
    _busqueda = texto;
    return cargar();
  }

  Future<void> filtrarRol(String? rol) {
    _rol = rol;
    return cargar();
  }

  Future<void> cargar() async {
    _carga = Carga.cargando;
    _error = null;
    notifyListeners();
    try {
      _usuarios = await _repo.usuarios(busqueda: _busqueda, rol: _rol);
      _carga = Carga.ok;
      _sinAcceso = false;
    } catch (e) {
      if (esSinPermiso(e)) {
        _sinAcceso = true;
        _carga = Carga.ok;
        await _onSinPermiso();
      } else {
        _carga = Carga.error;
        _error = _mensaje(e, 'No se pudieron cargar los usuarios');
      }
    }
    notifyListeners();
  }

  Future<String?> _cambiar(Future<UsuarioAdmin> Function() f) async {
    try {
      final nuevo = await f();
      _usuarios = [for (final u in _usuarios) u.id == nuevo.id ? nuevo : u];
      notifyListeners();
      return null;
    } catch (e) {
      if (esSinPermiso(e)) await _onSinPermiso();
      return _mensaje(e, 'No se pudo guardar el cambio');
    }
  }

  Future<String?> cambiarRol(UsuarioAdmin u, String rol) => _cambiar(() => _repo.cambiarRol(u.id, rol));

  Future<String?> cambiarEstado(UsuarioAdmin u, {required bool activo}) =>
      _cambiar(() => _repo.cambiarEstado(u.id, activo: activo));
}

/// Pantalla Estadísticas del administrador: solo datos reales de `GET /stats/admin`.
class EstadisticasController extends ChangeNotifier {
  EstadisticasController(this._repo, {Future<void> Function()? onSinPermiso})
      : _onSinPermiso = onSinPermiso ?? alPerderPermiso;

  final AdminRepository _repo;
  final Future<void> Function() _onSinPermiso;

  EstadisticasAdmin? _datos;
  Carga _carga = Carga.inicial;
  String? _error;
  bool _sinAcceso = false;
  int _dias = 30;

  EstadisticasAdmin? get datos => _datos;
  Carga get carga => _carga;
  String? get error => _error;
  bool get sinAcceso => _sinAcceso;
  int get dias => _dias;

  Future<void> fijarDias(int dias) {
    _dias = dias;
    return cargar();
  }

  Future<void> cargar() async {
    _carga = Carga.cargando;
    _error = null;
    notifyListeners();
    try {
      _datos = await _repo.estadisticas(dias: _dias);
      _carga = Carga.ok;
      _sinAcceso = false;
    } catch (e) {
      if (esSinPermiso(e)) {
        _sinAcceso = true;
        _carga = Carga.ok;
        await _onSinPermiso();
      } else {
        _carga = Carga.error;
        _error = _mensaje(e, 'No se pudieron cargar las estadísticas');
      }
    }
    notifyListeners();
  }
}

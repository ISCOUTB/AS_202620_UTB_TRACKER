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

  /// Quita el rol manual: manda la lista de roles por correo (ADR-0019).
  Future<String?> rolAutomatico(UsuarioAdmin u) => _cambiar(() => _repo.rolAutomatico(u.id));
}

/// Roles por correo institucional (ADR-0019): ver, buscar, agregar, editar, quitar e importar.
/// Las reglas (correo institucional exacto, último administrador) las aplica el servidor.
class AsignacionesController extends ChangeNotifier {
  AsignacionesController(this._repo, {Future<void> Function()? onSinPermiso})
      : _onSinPermiso = onSinPermiso ?? alPerderPermiso;

  final AdminRepository _repo;
  final Future<void> Function() _onSinPermiso;

  List<AsignacionRol> _items = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  bool _sinAcceso = false;
  String _busqueda = '';

  List<AsignacionRol> get items => _items;
  Carga get carga => _carga;
  String? get error => _error;
  bool get sinAcceso => _sinAcceso;

  Future<void> buscar(String texto) {
    _busqueda = texto;
    return cargar();
  }

  Future<void> cargar() async {
    _carga = Carga.cargando;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.asignaciones(busqueda: _busqueda);
      _carga = Carga.ok;
      _sinAcceso = false;
    } catch (e) {
      if (esSinPermiso(e)) {
        _sinAcceso = true;
        _carga = Carga.ok;
        await _onSinPermiso();
      } else {
        _carga = Carga.error;
        _error = _mensaje(e, 'No se pudo cargar la lista de roles');
      }
    }
    notifyListeners();
  }

  /// null si salió bien; si no, el mensaje del servidor.
  Future<String?> _guardar(Future<void> Function() f) async {
    try {
      await f();
      await cargar();
      return null;
    } catch (e) {
      if (esSinPermiso(e)) await _onSinPermiso();
      return _mensaje(e, 'No se pudo guardar el cambio');
    }
  }

  Future<String?> crear(String correo, String rol, String? cargo) =>
      _guardar(() => _repo.crearAsignacion(correo, rol, cargo));

  Future<String?> editar(AsignacionRol a, String rol, String? cargo) =>
      _guardar(() => _repo.editarAsignacion(a.id, rol: rol, cargo: cargo));

  Future<String?> quitar(AsignacionRol a) => _guardar(() => _repo.eliminarAsignacion(a.id));

  /// Con [simular] solo revisa. Lanza ApiException si el servidor la rechaza (p. ej. 409).
  Future<ResultadoImportacion> importar(String texto, {required bool simular}) async {
    final r = await _repo.importarAsignaciones(texto, simular: simular);
    if (r.aplicado) await cargar();
    return r;
  }
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

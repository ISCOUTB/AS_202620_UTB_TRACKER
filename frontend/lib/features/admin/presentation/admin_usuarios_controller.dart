import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../auth/domain/auth_domain.dart';

class AdminUsuariosController extends ChangeNotifier {
  AdminUsuariosController(this._repo);

  final AuthRepository _repo;

  List<Usuario> _usuarios = [];
  bool _cargando = false;
  String? _error;
  String _busqueda = '';
  String? _filtroRol;

  List<Usuario> get todos => List.unmodifiable(_usuarios);
  bool get cargando => _cargando;
  String? get error => _error;
  String get busqueda => _busqueda;
  String? get filtroRol => _filtroRol;

  List<Usuario> get filtrados {
    final query = _busqueda.trim().toLowerCase();
    return _usuarios.where((u) {
      if (query.isNotEmpty) {
        final coincideNombre = u.nombre.toLowerCase().contains(query);
        final coincideEmail = u.email.toLowerCase().contains(query);
        if (!coincideNombre && !coincideEmail) return false;
      }
      if (_filtroRol != null && _filtroRol!.isNotEmpty) {
        if (_filtroRol == 'auxiliar') {
          if (!u.esAdministrador) return false;
        } else if (_filtroRol == 'usuario_utb') {
          if (u.esAdministrador) return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await _repo.listarUsuarios();
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo cargar la lista de usuarios.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void fijarBusqueda(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  void fijarFiltroRol(String? rol) {
    _filtroRol = rol;
    notifyListeners();
  }

  Future<bool> cambiarRol({
    required int usuarioId,
    required String nuevoRol,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final actualizado = await _repo.actualizarRolUsuario(usuarioId, nuevoRol);
      final idx = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (idx != -1) {
        _usuarios[idx] = actualizado;
      }
      _cargando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _cargando = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Error inesperado al cambiar el rol del usuario.';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

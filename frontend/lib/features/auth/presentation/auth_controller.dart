import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/fcm_registration.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_domain.dart';

/// Estado de sesión con soporte de persistencia local del token.
class AuthController extends ChangeNotifier {
  AuthController(this._repo, this._api, [FcmRegistration? fcm])
      : _fcm = fcm ?? FcmRegistration();

  final AuthRepository _repo;
  final ApiClient _api;
  final FcmRegistration _fcm;

  Sesion? _sesion;
  bool _cargando = false;
  String? _error;
  bool? _servidorOk;

  Sesion? get sesion => _sesion;
  Usuario? get usuario => _sesion?.usuario;
  bool get autenticado => _sesion != null;
  bool get esAdministrador => usuario?.esAdministrador ?? false;
  bool get cargando => _cargando;
  String? get error => _error;

  /// null = aún no se ha comprobado.
  bool? get servidorOk => _servidorOk;

  /// Restaura la sesión guardada si existe un token en almacenamiento.
  Future<bool> restaurarSesion() async {
    final token = await TokenStorage.leerToken();
    if (token == null || token.isEmpty) return false;
    _api.fijarToken(token);
    try {
      final u = await _repo.usuarioActual();
      _sesion = Sesion(token: token, usuario: u);
      await _registrarFcm();
      notifyListeners();
      return true;
    } catch (_) {
      _api.fijarToken(null);
      await TokenStorage.borrarToken();
      return false;
    }
  }

  Future<bool> iniciarSesion(String nombre, String password) async {
    final ok = await _ejecutar(() async {
      _sesion = await _repo.iniciarSesion(nombre.trim(), password);
    });
    if (ok && _sesion != null) {
      await TokenStorage.guardarToken(_sesion!.token);
      await _registrarFcm();
    }
    return ok;
  }

  Future<bool> solicitarRecuperacion(String email) async {
    return _ejecutar(() async {
      await _api.post(
        '/auth/forgot-password',
        cuerpo: {'email': email.trim()},
      );
    });
  }

  Future<bool> restablecerConToken({
    required String token,
    required String nuevaPassword,
  }) async {
    return _ejecutar(() async {
      await _api.post(
        '/auth/reset-password',
        cuerpo: {'token': token.trim(), 'new_password': nuevaPassword},
      );
    });
  }

  /// Registra y entra directamente (ya sabemos quién es, no hace falta identificarlo).
  Future<bool> registrar({
    required String nombre,
    required String email,
    String rol = 'usuario_utb',
    required String password,
  }) async {
    final ok = await _ejecutar(() async {
      final nuevo = await _repo.registrar(
        nombre: nombre.trim(),
        email: email.trim(),
        rol: rol,
        password: password,
      );
      _sesion = await _repo.iniciarSesion(
        nuevo.nombre,
        password,
        conocido: nuevo,
      );
    });
    if (ok && _sesion != null) {
      await TokenStorage.guardarToken(_sesion!.token);
      await _registrarFcm();
    }
    return ok;
  }

  void cerrarSesion() {
    unawaited(_fcm.stop());
    _sesion = null;
    _error = null;
    _api.fijarToken(null);
    TokenStorage.borrarToken();
    notifyListeners();
  }

  Future<void> _registrarFcm() => _fcm.start(_repo.registrarTokenFcm);

  Future<void> comprobarServidor() async {
    _servidorOk = await _repo.servidorSaludable();
    notifyListeners();
  }

  Future<bool> actualizarPerfil() async {
    try {
      final usuario = await _repo.usuarioActual();
      if (_sesion != null) {
        _sesion = Sesion(token: _sesion!.token, usuario: usuario);
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}

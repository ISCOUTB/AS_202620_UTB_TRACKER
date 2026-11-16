import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/fcm_registration.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_data.dart';
import '../domain/auth_domain.dart';

/// Estado de sesión con soporte de persistencia local del token.
class AuthController extends ChangeNotifier {
  AuthController(this._repo, this._api, [FcmRegistration? fcm])
      : _fcm = fcm ?? FcmRegistration() {
    // El ApiClient renueva el token solo (401 -> /auth/refresh); aquí se guarda el par nuevo
    // y, si ya no se puede renovar, se cierra la sesión con un aviso claro.
    _api.alRenovarTokens = (access, refresh) {
      final s = _sesion;
      if (s != null) {
        _sesion = Sesion(token: access, refreshToken: refresh, usuario: s.usuario);
      }
      TokenStorage.guardarTokens(access, refresh);
    };
    _api.alVencerSesion = () {
      if (_sesion == null) return;
      cerrarSesion();
      _error = 'Tu sesión venció. Vuelve a iniciar sesión.';
      notifyListeners();
    };
  }

  final AuthRepository _repo;
  final ApiClient _api;
  final FcmRegistration _fcm;

  Sesion? _sesion;
  bool _cargando = false;
  String? _error;
  bool? _servidorOk;
  bool _verificacionPendienteVisible = false;
  String? _aviso;

  Sesion? get sesion => _sesion;
  Usuario? get usuario => _sesion?.usuario;
  bool get autenticado => _sesion != null;
  /// Permisos REALES: los que aplica el servidor (ADR-0018).
  Permisos get permisosReales => usuario?.permisos ?? Permisos.ninguno;

  /// Permisos con los que se DIBUJA la app. Iguales a los reales, salvo en el modo prueba del
  /// administrador, que muestra la navegación de otro rol. Es solo de interfaz: el servidor
  /// sigue aplicando el rol real.
  Permisos get permisos {
    final vista = vistaComo;
    return vista == null ? permisosReales : Permisos.deRol(vista);
  }

  String? _vistaComo;

  /// Rol que el administrador está "viendo" (null = el suyo). Nunca para otros roles.
  String? get vistaComo =>
      permisosReales.puede(Permisos.modoPrueba) ? _vistaComo : null;

  /// Activa o apaga el modo prueba. Se guarda solo en este dispositivo; no va al servidor ni
  /// a la bitácora de auditoría.
  Future<void> verComo(String? rol) async {
    if (!permisosReales.puede(Permisos.modoPrueba)) return;
    _vistaComo = (rol == null || rol == usuario?.rol) ? null : rol;
    notifyListeners();
    await TokenStorage.guardarVistaComo(_vistaComo);
  }

  Future<void> _cargarVistaComo() async {
    try {
      _vistaComo = await TokenStorage.leerVistaComo();
    } catch (_) {
      _vistaComo = null;
    }
  }
  bool get cargando => _cargando;
  String? get error => _error;

  /// null = aún no se ha comprobado.
  bool? get servidorOk => _servidorOk;

  bool get correoVerificado => usuario?.emailVerificado ?? true;

  /// Justo después de registrarse se muestra "Revisa tu correo" antes de la app.
  bool get mostrarVerificacionPendiente =>
      autenticado && !correoVerificado && _verificacionPendienteVisible;

  /// Mensaje informativo (no error) para mostrar una vez, p. ej. "Te reenviamos el correo".
  String? get aviso => _aviso;

  void continuarSinVerificar() {
    _verificacionPendienteVisible = false;
    notifyListeners();
  }

  Future<bool> reenviarVerificacion() async {
    final ok = await _ejecutar(_repo.reenviarVerificacion);
    if (ok) {
      _aviso = 'Te enviamos de nuevo el correo. Revisa también la carpeta de spam.';
      notifyListeners();
    }
    return ok;
  }

  /// Vuelve a leer el perfil para saber si ya se abrió el enlace de verificación.
  Future<bool> comprobarVerificacion() async {
    await _ejecutar(() async {
      final u = await _repo.usuarioActual();
      if (_sesion != null) {
        _sesion = Sesion(token: _sesion!.token, refreshToken: _sesion!.refreshToken, usuario: u);
      }
    });
    if (correoVerificado) {
      _verificacionPendienteVisible = false;
      _aviso = '¡Correo verificado! Ya puedes solicitar salones.';
      notifyListeners();
    } else if (_error == null) {
      _error = 'Aún no vemos el correo verificado. Abre el enlace que te enviamos.';
      notifyListeners();
    }
    return correoVerificado;
  }

  /// POST /auth/me/cambiar-correo (el correo cambia al abrir el enlace del correo nuevo).
  Future<bool> solicitarCambioCorreo(String correoNuevo, String password) {
    return _ejecutar(() async {
      await _api.post('/auth/me/cambiar-correo', cuerpo: {
        'correo_nuevo': correoNuevo.trim(),
        'password': password,
      });
    });
  }

  // ── Perfil (ADR-0016) ─────────────────────────────────────────────────

  void _fijarUsuario(Map<String, dynamic> json) {
    final s = _sesion;
    if (s == null) return;
    _sesion = Sesion(
      token: s.token,
      refreshToken: s.refreshToken,
      usuario: UsuarioModel.desdeJson(json),
    );
  }

  /// PATCH /auth/me con solo los campos que cambian ("" borra un campo opcional).
  Future<bool> guardarPerfil(Map<String, dynamic> cambios, {String? avisoOk}) async {
    final ok = await _ejecutar(() async {
      final r = await _api.patch('/auth/me', cuerpo: cambios);
      _fijarUsuario(r as Map<String, dynamic>);
    });
    if (ok && avisoOk != null) {
      _aviso = avisoOk;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> guardarPreferencias(Preferencias p) =>
      guardarPerfil({'preferencias': p.aJson()});

  /// Tokens nuevos para este dispositivo tras cambiar la contraseña o cerrar las demás sesiones.
  Future<void> _adoptarTokens(Map<String, dynamic> r) async {
    final access = (r['access_token'] ?? '').toString();
    final refresh = r['refresh_token']?.toString();
    if (access.isEmpty || _sesion == null) return;
    _api.fijarTokens(access, refresh);
    _sesion = Sesion(token: access, refreshToken: refresh, usuario: _sesion!.usuario);
    await TokenStorage.guardarTokens(access, refresh);
  }

  Future<bool> cambiarPassword(String actual, String nueva) async {
    final ok = await _ejecutar(() async {
      final r = await _api.post('/auth/me/cambiar-password',
          cuerpo: {'password_actual': actual, 'password_nueva': nueva});
      await _adoptarTokens(r as Map<String, dynamic>);
    });
    if (ok) {
      _aviso = 'Contraseña actualizada. Cerramos tu sesión en los demás dispositivos.';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> cerrarOtrasSesiones() async {
    final ok = await _ejecutar(() async {
      final r = await _api.post('/auth/me/cerrar-sesiones');
      await _adoptarTokens(r as Map<String, dynamic>);
    });
    if (ok) {
      _aviso = 'Cerramos tu sesión en los demás dispositivos.';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> desactivarCuenta(String password) async {
    final ok = await _ejecutar(() async {
      await _api.post('/auth/me/desactivar', cuerpo: {'password': password});
    });
    if (ok) cerrarSesion();
    return ok;
  }

  void limpiarAviso() {
    if (_aviso == null) return;
    _aviso = null;
    notifyListeners();
  }

  /// Restaura la sesión guardada. Si el access token ya venció, el ApiClient lo renueva con
  /// el refresh token; solo si el servidor rechaza la sesión se borra lo guardado (sin red se
  /// conserva para reintentar).
  Future<bool> restaurarSesion() async {
    final token = await TokenStorage.leerToken();
    if (token == null || token.isEmpty) return false;
    _api.fijarTokens(token, await TokenStorage.leerRefresh());
    try {
      final u = await _repo.usuarioActual();
      _sesion = Sesion(
        token: _api.token ?? token,
        refreshToken: _api.refreshToken,
        usuario: u,
      );
      await _cargarVistaComo();
      await _registrarFcm();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (!e.esDeRed) {
        _api.fijarTokens(null, null);
        await TokenStorage.borrarToken();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Cambia de servidor (solo compilaciones de desarrollo). Cierra la sesión: un token de un
  /// servidor no sirve en otro.
  Future<void> cambiarServidor(String? url) async {
    ApiConfig.elegir(url);
    await TokenStorage.guardarServidor(url == null ? null : ApiConfig.baseUrl);
    cerrarSesion();
    _servidorOk = null;
    notifyListeners();
    await comprobarServidor();
  }

  /// [identificador] es el nombre de usuario o el correo.
  Future<bool> iniciarSesion(String identificador, String password) async {
    final ok = await _ejecutar(() async {
      _sesion = await _repo.iniciarSesion(identificador.trim(), password);
      _verificacionPendienteVisible = false;
    });
    if (ok && _sesion != null) {
      await TokenStorage.guardarTokens(_sesion!.token, _sesion!.refreshToken);
      await _cargarVistaComo();
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

  /// Registra y entra directamente (ya sabemos quién es, no hace falta identificarlo). La
  /// cuenta nace sin verificar: se muestra "Revisa tu correo".
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
      _verificacionPendienteVisible = !nuevo.emailVerificado;
    });
    if (ok && _sesion != null) {
      await TokenStorage.guardarTokens(_sesion!.token, _sesion!.refreshToken);
      await _registrarFcm();
    }
    return ok;
  }

  void cerrarSesion() {
    unawaited(_fcm.stop());
    _sesion = null;
    _error = null;
    _aviso = null;
    _verificacionPendienteVisible = false;
    _vistaComo = null;
    _api.fijarTokens(null, null);
    TokenStorage.borrarToken();
    TokenStorage.guardarVistaComo(null);
    notifyListeners();
  }

  /// Si las notificaciones push fallan (sin Firebase, permiso negado), la sesión sigue.
  Future<void> _registrarFcm() async {
    try {
      await _fcm.start(_repo.registrarTokenFcm);
    } catch (_) {}
  }

  Future<void> comprobarServidor() async {
    _servidorOk = await _repo.servidorSaludable();
    notifyListeners();
  }

  /// Vuelve a leer el perfil (y sus permisos). Se usa también cuando el servidor responde 403:
  /// el rol pudo cambiar mientras la app estaba abierta.
  Future<bool> actualizarPerfil() async {
    try {
      final usuario = await _repo.usuarioActual();
      if (_sesion != null) {
        _sesion = Sesion(
            token: _sesion!.token, refreshToken: _sesion!.refreshToken, usuario: usuario);
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

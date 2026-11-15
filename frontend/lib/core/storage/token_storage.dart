import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento local de la sesión (access + refresh token) y del servidor elegido en
/// compilaciones de desarrollo, para que sobrevivan al cerrar la app.
class TokenStorage {
  TokenStorage._();

  static const String _clave = 'utb_access_token';
  static const String _claveRefresh = 'utb_refresh_token';
  static const String _claveServidor = 'utb_servidor';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> guardarTokens(String access, String? refresh) async {
    await _storage.write(key: _clave, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _claveRefresh, value: refresh);
    }
  }

  static Future<String?> leerToken() => _storage.read(key: _clave);

  static Future<String?> leerRefresh() => _storage.read(key: _claveRefresh);

  /// Borra access y refresh (cierre de sesión limpio).
  static Future<void> borrarToken() async {
    await _storage.delete(key: _clave);
    await _storage.delete(key: _claveRefresh);
  }

  static Future<String?> leerServidor() => _storage.read(key: _claveServidor);

  static Future<void> guardarServidor(String? url) => url == null
      ? _storage.delete(key: _claveServidor)
      : _storage.write(key: _claveServidor, value: url);
}

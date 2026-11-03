import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento local del token de sesión para persistencia entre aperturas de la app.
class TokenStorage {
  TokenStorage._();

  static const String _clave = 'utb_access_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> guardarToken(String token) async {
    await _storage.write(key: _clave, value: token);
  }

  static Future<String?> leerToken() => _storage.read(key: _clave);

  static Future<void> borrarToken() => _storage.delete(key: _clave);
}

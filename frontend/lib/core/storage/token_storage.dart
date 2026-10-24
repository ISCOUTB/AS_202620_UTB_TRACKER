import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Almacenamiento local del token de sesión para persistencia entre aperturas de la app.
/// Funciona de forma segura en Android, iOS, Desktop y en memoria como fallback.
class TokenStorage {
  TokenStorage._();

  static const String _archivo = '.utb_sesion.json';
  static String? _memoriaToken;

  static Future<void> guardarToken(String token) async {
    _memoriaToken = token;
    if (kIsWeb) return;
    try {
      final f = File(_archivo);
      await f.writeAsString(jsonEncode({'token': token}));
    } catch (_) {
      // Si el entorno no permite escribir (p. ej. pruebas o sandbox estricto), se mantiene en memoria
    }
  }

  static Future<String?> leerToken() async {
    if (_memoriaToken != null && _memoriaToken!.isNotEmpty) {
      return _memoriaToken;
    }
    if (kIsWeb) return null;
    try {
      final f = File(_archivo);
      if (await f.exists()) {
        final contenido = await f.readAsString();
        final data = jsonDecode(contenido) as Map<String, dynamic>;
        _memoriaToken = data['token'] as String?;
        return _memoriaToken;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> borrarToken() async {
    _memoriaToken = null;
    if (kIsWeb) return;
    try {
      final f = File(_archivo);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}

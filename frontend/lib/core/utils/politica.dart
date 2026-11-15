/// Reglas de identidad: espejo exacto de `app/core/politica.py` (ADR-0014).
/// Mismas reglas y mismos mensajes en la app y en el backend: si cambias una, cambia la otra.
class Politica {
  Politica._();

  static const int passwordMinimo = 8;

  static const msgPasswordCorta =
      'La contraseña debe tener al menos $passwordMinimo caracteres';
  static const msgPasswordIgualCorreo =
      'La contraseña no puede ser igual a tu correo';
  static const msgPasswordIgualNombre =
      'La contraseña no puede ser igual a tu nombre de usuario';
  static const msgCorreoInvalido = 'Escribe un correo válido';

  static final RegExp _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizarCorreo(String correo) => correo.trim().toLowerCase();

  static String normalizarNombre(String nombre) =>
      nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');

  static bool correoValido(String correo) {
    final c = normalizarCorreo(correo);
    return _correo.hasMatch(c) && !RegExp(r'[\r\n,;<>"]').hasMatch(c);
  }

  /// Mensaje de error de la política, o null si la contraseña es válida.
  static String? errorPassword(String password, {String? correo, String? nombre}) {
    if (password.length < passwordMinimo) return msgPasswordCorta;
    final p = password.trim().toLowerCase();
    if (correo != null && correo.trim().isNotEmpty) {
      final c = normalizarCorreo(correo);
      if (p == c || p == c.split('@').first) return msgPasswordIgualCorreo;
    }
    if (nombre != null &&
        nombre.trim().isNotEmpty &&
        p == normalizarNombre(nombre).toLowerCase()) {
      return msgPasswordIgualNombre;
    }
    return null;
  }
}

/// Reglas de identidad: espejo exacto de `app/service/politica.py` (ADR-0014).
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
  static const msgCorreoAlias = 'Escribe tu correo sin alias: no uses el signo + en el correo';

  /// Dominio institucional (ADR-0019). Solo se admiten correos NUEVOS de esta lista, por
  /// coincidencia exacta tras la última "@". En desarrollo se amplía igual que en el servidor:
  /// `flutter run --dart-define=DOMINIOS_PERMITIDOS=utb.edu.co,example.com`.
  static const dominioInstitucional = 'utb.edu.co';
  static const ejemploCorreo = 'usuario@$dominioInstitucional';
  static const msgCorreoNoInstitucional =
      'Usa tu correo institucional de la UTB (termina en @$dominioInstitucional)';
  static final List<String> dominiosPermitidos = leerDominios(
      const String.fromEnvironment('DOMINIOS_PERMITIDOS'));

  static List<String> leerDominios(String valor) {
    final dominios = <String>[];
    for (final d in valor.split(',')) {
      var limpio = d.trim().toLowerCase();
      if (limpio.startsWith('@')) limpio = limpio.substring(1);
      if (limpio.isNotEmpty && !dominios.contains(limpio)) dominios.add(limpio);
    }
    return dominios.isEmpty ? const [dominioInstitucional] : dominios;
  }

  static final RegExp _usuarioCorreo = RegExp(r'^[a-z0-9._\-]{1,64}$');

  static final RegExp _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizarCorreo(String correo) => correo.trim().toLowerCase();

  static String normalizarNombre(String nombre) =>
      nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');

  static bool correoValido(String correo) {
    final c = normalizarCorreo(correo);
    return _correo.hasMatch(c) && !RegExp(r'[\r\n,;<>"]').hasMatch(c);
  }

  static String dominioDe(String correo) {
    final c = normalizarCorreo(correo);
    return c.substring(c.lastIndexOf('@') + 1);
  }

  static bool esInstitucional(String correo, {List<String>? dominios}) =>
      (dominios ?? dominiosPermitidos).contains(dominioDe(correo));

  /// Regla de correos NUEVOS (registro y cambio de correo): espejo de `error_correo_nuevo`.
  static String? errorCorreoNuevo(String correo, {List<String>? dominios}) {
    final c = normalizarCorreo(correo);
    if (!correoValido(c)) return msgCorreoInvalido;
    final usuario = c.substring(0, c.lastIndexOf('@'));
    if (usuario.contains('+')) return msgCorreoAlias;
    if (!_usuarioCorreo.hasMatch(usuario) ||
        '._-'.contains(usuario[0]) ||
        usuario.endsWith('.') ||
        usuario.contains('..')) {
      return msgCorreoInvalido;
    }
    if (!esInstitucional(c, dominios: dominios)) return msgCorreoNoInstitucional;
    return null;
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

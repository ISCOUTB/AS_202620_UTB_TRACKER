import 'dart:convert';
import 'dart:math';

/// Clave para el encabezado `X-Idempotency-Key` (S11 req. 11.3).
/// Se genera UNA vez por intento de préstamo y se reutiliza si el usuario reintenta,
/// así el backend devuelve el préstamo original en vez de duplicarlo o dar un falso 409.
String nuevaClaveIdempotencia() {
  final azar = Random.secure();
  final bytes = List<int>.generate(16, (_) => azar.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Lee el payload de un JWT sin verificarlo (la verificación es del servidor).
/// Solo sirve para leer `sub` (el correo) y `exp`.
Map<String, dynamic>? leerPayloadJwt(String token) {
  try {
    final partes = token.split('.');
    if (partes.length != 3) return null;
    final json = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
    final mapa = jsonDecode(json);
    return mapa is Map<String, dynamic> ? mapa : null;
  } catch (_) {
    return null;
  }
}

/// El backend guarda fechas SIN zona horaria y usa UTC (`datetime.utcnow`).
/// Convención del cliente: lo que llega sin zona es UTC; se muestra en hora local.
DateTime parsearFechaServidor(String texto) {
  final tieneZona = texto.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(texto);
  return DateTime.parse(tieneZona ? texto : '${texto}Z').toLocal();
}

/// Inversa de la anterior: el cliente envía UTC sin sufijo de zona (igual que guarda el backend).
String fechaParaServidor(DateTime fecha) {
  final iso = fecha.toUtc().toIso8601String();
  return iso.endsWith('Z') ? iso.substring(0, iso.length - 1) : iso;
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _dos(int n) => n.toString().padLeft(2, '0');

String formatearFechaHora(DateTime f) {
  final h12 = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final sufijo = f.hour < 12 ? 'a. m.' : 'p. m.';
  return '${f.day} ${_meses[f.month - 1]} · $h12:${_dos(f.minute)} $sufijo';
}

/// "vence en 3 h", "vencido hace 2 d"…
String describirPlazo(DateTime limite, {DateTime? ahora}) {
  final d = limite.difference(ahora ?? DateTime.now());
  final abs = d.abs();
  final cantidad = abs.inDays >= 1
      ? '${abs.inDays} d'
      : abs.inHours >= 1
          ? '${abs.inHours} h'
          : '${max(abs.inMinutes, 1)} min';
  return d.isNegative ? 'vencido hace $cantidad' : 'vence en $cantidad';
}

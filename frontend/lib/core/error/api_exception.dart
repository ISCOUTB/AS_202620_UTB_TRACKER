import 'dart:convert';

import 'package:http/http.dart' as http;

enum TipoError {
  sinConexion,
  tiempoAgotado,
  noAutorizado,
  prohibido,
  noEncontrado,
  conflicto,
  validacion,
  servidor,
  desconocido,
}

/// Error del puente con el API. Siempre trae un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  ApiException(this.tipo, this.mensaje, {this.statusCode});

  final TipoError tipo;
  final String mensaje;
  final int? statusCode;

  bool get esDeRed =>
      tipo == TipoError.sinConexion || tipo == TipoError.tiempoAgotado;

  factory ApiException.sinConexion() => ApiException(
        TipoError.sinConexion,
        'No hay conexión con el servidor. Revisa tu red e intenta de nuevo.',
      );

  factory ApiException.tiempoAgotado() => ApiException(
        TipoError.tiempoAgotado,
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );

  /// Traduce una respuesta HTTP de error usando el campo `detail` de FastAPI.
  factory ApiException.fromResponse(http.Response r) {
    final detalle = _detalle(r);
    switch (r.statusCode) {
      case 401:
        return ApiException(
          TipoError.noAutorizado,
          detalle ?? 'Credenciales inválidas o sesión vencida.',
          statusCode: 401,
        );
      case 403:
        return ApiException(
          TipoError.prohibido,
          detalle ?? 'No tienes permiso para esta acción.',
          statusCode: 403,
        );
      case 404:
        return ApiException(
          TipoError.noEncontrado,
          detalle ?? 'No se encontró lo que buscabas.',
          statusCode: 404,
        );
      case 409:
        return ApiException(
          TipoError.conflicto,
          detalle ?? 'La acción choca con el estado actual.',
          statusCode: 409,
        );
      case 422:
        return ApiException(
          TipoError.validacion,
          detalle ?? 'Hay datos con formato inválido.',
          statusCode: 422,
        );
      default:
        if (r.statusCode >= 500) {
          return ApiException(
            TipoError.servidor,
            'El servidor tuvo un problema (${r.statusCode}). Intenta de nuevo en un momento.',
            statusCode: r.statusCode,
          );
        }
        return ApiException(
          TipoError.desconocido,
          detalle ?? 'Error inesperado (${r.statusCode}).',
          statusCode: r.statusCode,
        );
    }
  }

  /// `detail` puede ser texto (HTTPException) o una lista (errores 422 de Pydantic).
  static String? _detalle(http.Response r) {
    try {
      final cuerpo = jsonDecode(utf8.decode(r.bodyBytes));
      if (cuerpo is Map && cuerpo['detail'] != null) {
        final d = cuerpo['detail'];
        if (d is String) return d;
        if (d is List && d.isNotEmpty) {
          final partes = d.map((e) {
            if (e is Map) {
              final loc = (e['loc'] is List)
                  ? (e['loc'] as List).where((x) => x != 'body').join('.')
                  : '';
              final msg = e['msg']?.toString() ?? 'inválido';
              return loc.isEmpty ? msg : '$loc: $msg';
            }
            return e.toString();
          });
          return partes.join('\n');
        }
      }
    } catch (_) {
      // cuerpo no JSON: se usa el mensaje por defecto
    }
    return null;
  }

  @override
  String toString() => 'ApiException($tipo, $statusCode): $mensaje';
}

import 'package:flutter/foundation.dart';

/// Configuración del puente con el backend FastAPI.
///
/// Dirección por plataforma (Blueprint FastAPI + Flutter, "El laberinto de la red local"):
///  - Web / simulador iOS: http://127.0.0.1:8000
///  - Emulador Android:    http://10.0.2.2:8000 (localhost apuntaría al propio teléfono)
///  - Celular real:        usar la IP de tu PC en la red, con --dart-define=API_BASE_URL=...
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Servidor UTB Tracker en la nube (dominio HTTPS con certificado).
  static const String servidorProduccion = 'https://129-80-171-141.nip.io';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return servidorProduccion;
  }

  /// Tiempo máximo de espera por petición (el auxiliar tiene conexión intermitente en el campus).
  static const Duration timeout = Duration(seconds: 10);

  /// Mientras el backend siga aceptando cualquier `rol` en /auth/register (brecha B-5 de
  /// docs/brechas_backend.md), la app deja elegir el rol para poder crear auxiliares en demos.
  /// Para una entrega/producción: --dart-define=PERMITIR_ELEGIR_ROL=false.
  static const bool permitirElegirRol =
      bool.fromEnvironment('PERMITIR_ELEGIR_ROL', defaultValue: true);

  /// Reintentos de lecturas (GET) ante fallo de red o 5xx, con backoff exponencial y jitter
  /// (misma idea que `with_retry` del backend, S11 req. 11.2).
  static const int reintentosLectura = 2;
}

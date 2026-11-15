import 'package:flutter/foundation.dart';

/// Configuración del puente con el backend FastAPI.
///
/// Servidor OFICIAL: [servidorProduccion] (la nube). Es el que usan el APK y cualquier
/// compilación sin `--dart-define=API_BASE_URL=...`; ahí viven las cuentas reales.
///
/// Dirección por plataforma para desarrollo (Blueprint FastAPI + Flutter):
///  - Web / simulador iOS: http://127.0.0.1:8000
///  - Emulador Android:    http://10.0.2.2:8000 (localhost apuntaría al propio teléfono)
///  - Celular real:        la IP de tu PC en la red, con --dart-define=API_BASE_URL=...
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// En compilaciones de desarrollo (debug o `--dart-define=PERMITIR_CAMBIAR_SERVIDOR=true`)
  /// el login y el perfil dejan cambiar de servidor. En el APK de release no.
  static const bool _permitirCambio =
      bool.fromEnvironment('PERMITIR_CAMBIAR_SERVIDOR');

  /// Servidor UTB Tracker en la nube (dominio HTTPS con certificado).
  static const String servidorProduccion = 'https://129-80-171-141.nip.io';

  /// Servidores que se ofrecen al cambiar (además de escribir uno a mano).
  static const Map<String, String> sugeridos = {
    servidorProduccion: 'Oficial (nube)',
    'http://127.0.0.1:8000': 'Local (este PC)',
    'http://10.0.2.2:8000': 'Local (emulador Android)',
  };

  static String? _elegido;

  /// Servidor con el que se compiló la app.
  static String get porDefecto =>
      _override.isNotEmpty ? _override : servidorProduccion;

  static String get baseUrl => _elegido ?? porDefecto;

  static bool get permiteCambiarServidor => kDebugMode || _permitirCambio;

  /// Cambia el servidor en tiempo de ejecución (null = volver al de compilación).
  static void elegir(String? url) {
    final limpio = url?.trim().replaceAll(RegExp(r'/+$'), '');
    _elegido = (limpio == null || limpio.isEmpty) ? null : limpio;
  }

  /// Nombre corto para mostrar: "Oficial (nube)", "Local (este PC)" o la dirección.
  static String describir([String? url]) {
    final u = url ?? baseUrl;
    return sugeridos[u] ?? (u.contains('127.0.0.1') || u.contains('localhost')
        ? 'Local'
        : 'Personalizado');
  }

  static bool get esOficial => baseUrl == servidorProduccion;

  /// Tiempo máximo de espera por petición (el auxiliar tiene conexión intermitente en el campus).
  static const Duration timeout = Duration(seconds: 10);

  /// Reintentos de lecturas (GET) ante fallo de red o 5xx, con backoff exponencial y jitter
  /// (misma idea que `with_retry` del backend, S11 req. 11.2).
  static const int reintentosLectura = 2;
}

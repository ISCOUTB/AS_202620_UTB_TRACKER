import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'core/di/injection.dart';
import 'core/storage/token_storage.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _manejarMensajeEnSegundoPlano(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase solo está configurado para Android; en web se omite (sin push).
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_manejarMensajeEnSegundoPlano);
  }
  // En compilaciones de desarrollo se recuerda el servidor elegido en el login/perfil.
  if (ApiConfig.permiteCambiarServidor) {
    try {
      ApiConfig.elegir(await TokenStorage.leerServidor());
    } catch (_) {
      // Sin almacenamiento disponible: se usa el servidor de compilación.
    }
  }
  await configurarDependencias();
  runApp(const UtbTrackerApp());
}

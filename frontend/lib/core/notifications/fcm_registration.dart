import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef FcmTokenRegistrar = Future<void> Function(String token);

class FcmRegistration {
  FcmRegistration({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> start(FcmTokenRegistrar registrar) async {
    if (kIsWeb) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      developer.log(
        'Permiso de notificaciones denegado',
        name: 'utb_tracker.fcm',
      );
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registrar(registrar, token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (nuevoToken) => _registrar(registrar, nuevoToken),
      onError: (Object error, StackTrace stack) {
        developer.log(
          'No se pudo escuchar la rotación del token FCM',
          name: 'utb_tracker.fcm',
          error: error,
          stackTrace: stack,
        );
      },
    );
  }

  Future<void> stop() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _registrar(
    FcmTokenRegistrar registrar,
    String token,
  ) async {
    try {
      await registrar(token);
      developer.log('Token FCM registrado', name: 'utb_tracker.fcm');
    } catch (error, stack) {
      developer.log(
        'No se pudo registrar el token FCM en el backend',
        name: 'utb_tracker.fcm',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

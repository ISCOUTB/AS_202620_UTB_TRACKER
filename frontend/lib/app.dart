import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/escala.dart';
import 'features/auth/domain/preferencias.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/verificacion_page.dart';
import 'features/home/presentation/shell_page.dart';

class UtbTrackerApp extends StatelessWidget {
  const UtbTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTB Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.oscuro,
      darkTheme: AppTheme.oscuro,
      themeMode: ThemeMode.dark,
      // Escala de la interfaz y tamaño de texto en un solo punto (Fase 3). El tamaño de texto
      // elegido en el perfil (guardado en el servidor) se aplica al iniciar sesión.
      builder: (context, child) => ListenableBuilder(
        listenable: sl<AuthController>(),
        builder: (context, _) => EscalaGlobal(
          tamanoTexto: sl<AuthController>().usuario?.preferencias.tamanoTexto ??
              TamanoTexto.normal,
          child: child!,
        ),
      ),
      home: const _Raiz(),
    );
  }
}

/// Decide entre login y pantalla principal según haya sesión.
/// Al iniciar sesión se crea un ShellPage nuevo, que vuelve a cargar equipos y préstamos.
class _Raiz extends StatefulWidget {
  const _Raiz();

  @override
  State<_Raiz> createState() => _RaizState();
}

class _RaizState extends State<_Raiz> {
  final AuthController _auth = sl<AuthController>();

  @override
  void initState() {
    super.initState();
    _auth.restaurarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => !_auth.autenticado
          ? const LoginPage()
          : _auth.mostrarVerificacionPendiente
              ? const VerificacionPage()
              : const ShellPage(),
    );
  }
}

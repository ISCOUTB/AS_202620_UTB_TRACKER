import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
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
      builder: (context, _) =>
          _auth.autenticado ? const ShellPage() : const LoginPage(),
    );
  }
}

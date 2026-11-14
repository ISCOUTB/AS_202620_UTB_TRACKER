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
      builder: (context, child) => EscalaGlobal(child: child!),
      home: const _Raiz(),
    );
  }
}

/// Dibuja toda la app (pantallas, hojas y diálogos) un poco más pequeña para que quepa más
/// información, como bajar el "tamaño de pantalla" del teléfono. La app se diseña en un
/// lienzo mayor (tamaño / [factor]) y se pinta reducida; los toques se convierten solos.
class EscalaGlobal extends StatelessWidget {
  const EscalaGlobal({super.key, required this.child, this.factor = 0.9});

  final Widget child;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final lienzo = mq.size / factor;
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: lienzo.width,
      maxWidth: lienzo.width,
      minHeight: lienzo.height,
      maxHeight: lienzo.height,
      child: Transform.scale(
        scale: factor,
        alignment: Alignment.topLeft,
        child: MediaQuery(
          data: mq.copyWith(
            size: lienzo,
            devicePixelRatio: mq.devicePixelRatio * factor,
            padding: mq.padding / factor,
            viewPadding: mq.viewPadding / factor,
            viewInsets: mq.viewInsets / factor,
            systemGestureInsets: mq.systemGestureInsets / factor,
          ),
          child: child,
        ),
      ),
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

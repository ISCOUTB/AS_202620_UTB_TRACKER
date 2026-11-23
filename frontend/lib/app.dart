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

  /// Mientras se recupera la sesión guardada se ve el mismo logo de la pantalla nativa de
  /// arranque (sin pasar un instante por el login), y luego se entra con un fundido.
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _auth.restaurarSesion().whenComplete(() {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: !_listo
            ? const _Arranque()
            : !_auth.autenticado
                ? const LoginPage()
                : _auth.mostrarVerificacionPendiente
                    ? const VerificacionPage()
                    : const ShellPage(),
      ),
    );
  }
}

/// Continuación de la pantalla nativa de arranque: fondo negro y el logo centrado.
class _Arranque extends StatelessWidget {
  const _Arranque();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abriendo UTB Tracker',
      child: const ColoredBox(
        color: AppColors.fondo,
        child: Center(
          child: Image(
            image: AssetImage('assets/icono/logo_splash.png'),
            // El círculo ocupa 520/768 de la imagen: ~120 dp, parecido al de Android.
            width: 176,
            height: 176,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Identidad visual de UTB Tracker (ver `docs/identidad/identidad-visual.md`).
///
/// Paleta alineada con la app oficial "UTB App": azul real [primario] como color de acción,
/// degradado azul → índigo para encabezados, fondo negro puro y superficies gris carbón
/// neutras (sin tinte), de modo que el azul sea el único color dominante.
class AppColors {
  AppColors._();

  // Marca.
  static const primario = Color(0xFF2F55E4);
  static const primarioClaro = Color(0xFF6B93FF); // texto/íconos azules sobre fondo oscuro
  static const indigo = Color(0xFF4B3BDB);
  static const indigoClaro = Color(0xFFA9BFFF);
  static const sobrePrimario = Color(0xFFFFFFFF);
  static const seleccion = Color(0xFF1E2C57); // píldora activa (barra inferior, botón "Hoy")

  /// Degradado de encabezados, como el de "Inicio" y "Agenda" en UTB App.
  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D3FE0), indigo],
  );

  // Fondos y superficies (negro y gris carbón neutro).
  static const fondo = Color(0xFF000000);
  static const superficie = Color(0xFF1B1C21);
  static const superficieAlta = Color(0xFF2A2C33);
  static const borde = Color(0xFF3A3D46);

  // Texto.
  static const texto = Color(0xFFFFFFFF);
  static const textoSuave = Color(0xFFC5C8D0);
  static const textoTenue = Color(0xFF8C9099);

  // Estados (semánticos: no cambian con la marca).
  static const disponible = Color(0xFF3DDC97);
  static const prestado = Color(0xFFFFB84D);
  static const danado = Color(0xFFFF6B6B);
  static const mantenimiento = Color(0xFF6CB4FF);
  static const neutro = Color(0xFF9EA3AE);
}

/// Fondo de todas las pantallas: negro con dos brillos difuminados (azul arriba, índigo abajo),
/// en lugar de un color plano.
class FondoDifuminado extends StatelessWidget {
  const FondoDifuminado({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.fondo),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.9, -1.0),
            radius: 1.25,
            colors: [Color(0x552F55E4), Color(0x00000000)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.1, 1.0),
              radius: 1.1,
              colors: [Color(0x334B3BDB), Color(0x00000000)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Transición entre pantallas: aparece desvaneciendo y subiendo un poco (suave, sin el
/// "deslizamiento" brusco por defecto). Cada pantalla lleva su propio [FondoDifuminado],
/// así la de atrás no se transparenta.
class _TransicionSuave extends PageTransitionsBuilder {
  const _TransicionSuave();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entrada = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: entrada,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(entrada),
        child: FondoDifuminado(child: child),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get oscuro {
    const esquema = ColorScheme.dark(
      primary: AppColors.primario,
      onPrimary: AppColors.sobrePrimario,
      secondary: AppColors.indigoClaro,
      onSecondary: Colors.black,
      surface: AppColors.superficie,
      onSurface: AppColors.texto,
      error: AppColors.danado,
    );

    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      // Transparente: el fondo difuminado lo pone la transición de cada pantalla.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.fondo,
      fontFamily: null,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values) p: const _TransicionSuave(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.superficie,
        modalBackgroundColor: AppColors.superficie,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        labelStyle: const TextStyle(color: AppColors.textoSuave),
        hintStyle: const TextStyle(color: AppColors.textoTenue),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: borde(AppColors.borde),
        enabledBorder: borde(AppColors.borde),
        focusedBorder: borde(AppColors.primarioClaro, 1.5),
        errorBorder: borde(AppColors.danado),
        focusedErrorBorder: borde(AppColors.danado, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: AppColors.sobrePrimario,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.texto,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.borde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primarioClaro),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.superficieAlta,
        contentTextStyle: TextStyle(color: AppColors.texto),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primarioClaro),
      dividerColor: AppColors.borde,
    );
  }
}

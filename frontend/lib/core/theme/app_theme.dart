import 'package:flutter/material.dart';

/// Paleta oscura inspirada en la propuesta de interfaz del equipo (fondo carbón, tarjetas
/// con borde sutil, botón principal blanco). Colores propios del proyecto.
class AppColors {
  AppColors._();

  static const fondo = Color(0xFF141414);
  static const superficie = Color(0xFF1E1E1E);
  static const superficieAlta = Color(0xFF2A2A2A);
  static const borde = Color(0xFF3A3A3A);
  static const texto = Color(0xFFFFFFFF);
  static const textoSuave = Color(0xFFB3B3B3);
  static const textoTenue = Color(0xFF7D7D7D);

  static const disponible = Color(0xFF3DDC97);
  static const prestado = Color(0xFFFFB84D);
  static const danado = Color(0xFFFF6B6B);
  static const mantenimiento = Color(0xFF6CB4FF);
  static const neutro = Color(0xFF9A9A9A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get oscuro {
    const esquema = ColorScheme.dark(
      primary: AppColors.texto,
      onPrimary: Colors.black,
      secondary: AppColors.disponible,
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
      scaffoldBackgroundColor: AppColors.fondo,
      canvasColor: AppColors.fondo,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondo,
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
        focusedBorder: borde(AppColors.texto, 1.5),
        errorBorder: borde(AppColors.danado),
        focusedErrorBorder: borde(AppColors.danado, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.texto,
          foregroundColor: Colors.black,
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
        style: TextButton.styleFrom(foregroundColor: AppColors.texto),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.superficieAlta,
        contentTextStyle: TextStyle(color: AppColors.texto),
      ),
      dividerColor: AppColors.borde,
    );
  }
}

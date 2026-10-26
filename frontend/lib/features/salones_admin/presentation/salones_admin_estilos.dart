import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/entities/ocupacion.dart';

/// Un solo color y una sola etiqueta por situación, para que el plano, las tarjetas
/// y la pantalla de control digan exactamente lo mismo.
const Color _colorPrestado = Color(0xFFB892FF);

Color colorDeSituacion(SituacionSalon s) => switch (s) {
      SituacionSalon.libre => AppColors.disponible,
      SituacionSalon.claseConProfesor => AppColors.mantenimiento,
      SituacionSalon.claseSinConfirmar => AppColors.prestado,
      SituacionSalon.claseSinProfesor => AppColors.danado,
      SituacionSalon.prestado => _colorPrestado,
      SituacionSalon.mantenimiento => AppColors.neutro,
      SituacionSalon.fueraDeServicio => AppColors.textoTenue,
    };

String etiquetaDeSituacion(SituacionSalon s) => switch (s) {
      SituacionSalon.libre => 'Libre',
      SituacionSalon.claseConProfesor => 'Clase · profesor presente',
      SituacionSalon.claseSinConfirmar => 'Clase · profesor sin confirmar',
      SituacionSalon.claseSinProfesor => 'Clase · profesor ausente',
      SituacionSalon.prestado => 'Prestado',
      SituacionSalon.mantenimiento => 'Mantenimiento',
      SituacionSalon.fueraDeServicio => 'Fuera de servicio',
    };

IconData iconoDeTipoReporte(TipoReporteSalon t) => switch (t) {
      TipoReporteSalon.limpieza => Icons.cleaning_services_rounded,
      TipoReporteSalon.equipo => Icons.devices_other_rounded,
      TipoReporteSalon.infraestructura => Icons.construction_rounded,
      TipoReporteSalon.seguridad => Icons.shield_outlined,
      TipoReporteSalon.otro => Icons.report_gmailerrorred_rounded,
    };

String _dos(int n) => n.toString().padLeft(2, '0');

/// "2:30 p. m." en hora local.
String formatearHora(DateTime f) {
  final h12 = f.hour % 12 == 0 ? 12 : f.hour % 12;
  return '$h12:${_dos(f.minute)} ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
}

/// "hace 5 min", "hace 3 h", "hace 2 d".
String haceCuanto(DateTime f, {DateTime? ahora}) {
  final d = (ahora ?? DateTime.now()).difference(f);
  if (d.inMinutes < 1) return 'justo ahora';
  if (d.inHours < 1) return 'hace ${d.inMinutes} min';
  if (d.inDays < 1) return 'hace ${d.inHours} h';
  return 'hace ${d.inDays} d';
}

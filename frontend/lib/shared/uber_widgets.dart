import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Piezas del lenguaje visual "tipo Uber": negro/blanco, tipografía gruesa,
/// botones de píldora grandes y hojas que se arrastran desde abajo.
enum EstiloBoton { principal, secundario, peligro }

class BotonPildora extends StatelessWidget {
  const BotonPildora({
    super.key,
    required this.texto,
    required this.onPressed,
    this.estilo = EstiloBoton.principal,
    this.icono,
    this.cargando = false,
    this.compacto = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final EstiloBoton estilo;
  final IconData? icono;
  final bool cargando;

  /// Versión baja (40 px) para acciones dentro de tarjetas.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final (fondo, frente, borde) = switch (estilo) {
      EstiloBoton.principal => (AppColors.texto, Colors.black, AppColors.texto),
      EstiloBoton.secundario => (AppColors.superficieAlta, AppColors.texto, AppColors.superficieAlta),
      EstiloBoton.peligro => (AppColors.danado.withValues(alpha: 0.14), AppColors.danado, AppColors.danado.withValues(alpha: 0.4)),
    };
    final alto = compacto ? 40.0 : 56.0;
    final activo = onPressed != null && !cargando;

    return Opacity(
      opacity: onPressed == null && !cargando ? 0.45 : 1,
      child: Material(
        color: fondo,
        shape: StadiumBorder(side: BorderSide(color: borde)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: activo ? onPressed : null,
          child: SizedBox(
            height: alto,
            child: Center(
              child: cargando
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: frente),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icono != null) ...[
                            Icon(icono, size: compacto ? 18 : 22, color: frente),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              texto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: frente,
                                fontSize: compacto ? 14 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra pequeña que invita a arrastrar la hoja.
class AsaHoja extends StatelessWidget {
  const AsaHoja({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.borde,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Círculo con las iniciales de una persona (como el avatar del conductor en Uber).
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.nombre, this.tamano = 52, this.color});

  final String nombre;
  final double tamano;
  final Color? color;

  static String iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (color ?? AppColors.superficieAlta).withValues(alpha: color == null ? 1 : 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color ?? AppColors.borde),
      ),
      child: Text(
        iniciales(nombre),
        style: TextStyle(
          fontSize: tamano * 0.36,
          fontWeight: FontWeight.w800,
          color: color ?? AppColors.texto,
        ),
      ),
    );
  }
}

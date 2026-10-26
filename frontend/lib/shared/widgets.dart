import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/assets/figuras.dart';
import '../core/theme/app_theme.dart';
import '../features/prestamos/domain/entities/prestamo.dart';
import '../features/recursos/domain/entities/recurso.dart';

/// Círculo oscuro con una figura SVG dentro (los accesos de "Para ti" y los listados).
class FiguraCircular extends StatelessWidget {
  const FiguraCircular({
    super.key,
    required this.figura,
    this.tamano = 76,
    this.relleno = 0.16,
  });

  final String figura;
  final double tamano;

  /// Margen interno como fracción del tamaño.
  final double relleno;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * relleno),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(figura, fit: BoxFit.contain),
    );
  }
}

/// Tarjeta con borde sutil, como las de la propuesta de interfaz.
class TarjetaBorde extends StatelessWidget {
  const TarjetaBorde({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borde),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SeccionTitulo extends StatelessWidget {
  const SeccionTitulo(this.texto, {super.key, this.accion});
  final String texto;
  final VoidCallback? accion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        if (accion != null)
          InkResponse(
            onTap: accion,
            radius: 28,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.superficie,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, size: 22),
            ),
          ),
      ],
    );
  }
}

Color colorDeEstado(EstadoRecurso e) {
  switch (e) {
    case EstadoRecurso.disponible:
      return AppColors.disponible;
    case EstadoRecurso.prestado:
      return AppColors.prestado;
    case EstadoRecurso.danado:
      return AppColors.danado;
    case EstadoRecurso.mantenimiento:
      return AppColors.mantenimiento;
    case EstadoRecurso.desconocido:
      return AppColors.neutro;
  }
}

Color colorDePrestamo(EstadoPrestamo e) {
  switch (e) {
    case EstadoPrestamo.activo:
      return AppColors.prestado;
    case EstadoPrestamo.vencido:
      return AppColors.danado;
    case EstadoPrestamo.devuelto:
      return AppColors.disponible;
  }
}

/// Insignia de estado: punto de color + texto (el color nunca va solo: también dice el estado).
class Insignia extends StatelessWidget {
  const Insignia({super.key, required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // withOpacity existe en todas las versiones de Flutter (en las más nuevas solo avisa
        // de deprecación; migrar a withValues(alpha:) cuando el equipo suba de versión).
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class VistaCargando extends StatelessWidget {
  const VistaCargando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: AppColors.texto),
      ),
    );
  }
}

/// Error de conexión / servidor con botón de reintento (ConnectionState.hasError del Blueprint).
class VistaError extends StatelessWidget {
  const VistaError({super.key, required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.textoSuave),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 15),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaVacia extends StatelessWidget {
  const VistaVacia({super.key, required this.mensaje, this.detalle, this.figura});
  final String mensaje;
  final String? detalle;
  final String? figura;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(figura ?? Figuras.vacio, height: 110),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Piezas del lenguaje visual inspirado en la app oficial "UTB App": encabezado con degradado
/// azul y arcos, tarjeta destacada con barra de estado, control segmentado en píldora,
/// títulos con subtítulo y aparición escalonada de los elementos.

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

/// "VIERNES, 13 DE NOVIEMBRE"
String fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}'.toUpperCase();

/// "Buenos días" / "Buenas tardes" / "Buenas noches"
String saludo(DateTime d) => d.hour < 12
    ? 'Buenos días'
    : d.hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';

/// Encabezado con degradado azul → índigo, arcos finos de fondo y esquinas inferiores
/// redondeadas. Va pegado arriba (detrás de la barra de estado).
class EncabezadoDegradado extends StatelessWidget {
  const EncabezadoDegradado({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.degradado,
          boxShadow: [
            BoxShadow(
              color: AppColors.primario.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _Arcos(),
          child: Padding(
            padding: EdgeInsets.only(top: arriba).add(padding),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Arcos extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);
    final centro = Offset(size.width * 1.05, -size.height * 0.15);
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(centro, size.width * 0.18 * i, p);
    }
    // Brillo difuso en la esquina superior izquierda.
    final brillo = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.6));
    canvas.drawCircle(Offset.zero, size.width * 0.6, brillo);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tarjeta destacada (como "Próxima clase" en UTB App): fondo oscuro translúcido, barra de
/// color a la izquierda que comunica el estado, y un dato grande opcional a la derecha.
class TarjetaDestacada extends StatelessWidget {
  const TarjetaDestacada({
    super.key,
    required this.etiqueta,
    required this.titulo,
    this.detalle,
    this.datoGrande,
    this.datoPequeno,
    this.color = AppColors.disponible,
    this.onTap,
  });

  final String etiqueta;
  final String titulo;
  final String? detalle;
  final String? datoGrande;
  final String? datoPequeno;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xEE16171C),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        etiqueta.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textoTenue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (detalle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          detalle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5),
                        ),
                      ],
                    ],
                  ),
                ),
                if (datoGrande != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        datoGrande!,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1),
                      ),
                      if (datoPequeno != null) ...[
                        const SizedBox(height: 6),
                        Text(datoPequeno!,
                            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección grande con subtítulo y flecha (como "Noticias" en UTB App).
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.titulo, {super.key, this.subtitulo, this.onVerTodo});
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onVerTodo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onVerTodo,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  if (subtitulo != null)
                    Text(subtitulo!,
                        style: const TextStyle(color: AppColors.textoTenue, fontSize: 14)),
                ],
              ),
            ),
            if (onVerTodo != null)
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textoSuave, size: 26),
          ],
        ),
      ),
    );
  }
}

/// Control segmentado en píldora (Horario | Eventos en UTB App). La opción activa se llena
/// con el degradado y se desliza suavemente.
class PildoraSegmentada extends StatelessWidget {
  const PildoraSegmentada({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onCambio,
  });

  final List<(IconData, String)> opciones;
  final int seleccion;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borde),
        color: const Color(0x99101114),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth / opciones.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: ancho * seleccion,
                top: 0,
                bottom: 0,
                width: ancho,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.degradado,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(color: AppColors.primario.withValues(alpha: 0.4), blurRadius: 14),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < opciones.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onCambio(i),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(opciones[i].$1, size: 19),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                opciones[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: i == seleccion ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta promocional en degradado con figura a la derecha (como "Tu carnet digital").
class TarjetaPromo extends StatelessWidget {
  const TarjetaPromo({
    super.key,
    required this.etiqueta,
    required this.titulo,
    required this.detalle,
    required this.accion,
    required this.onTap,
    this.icono = Icons.meeting_room_rounded,
  });

  final String etiqueta;
  final String titulo;
  final String detalle;
  final String accion;
  final VoidCallback onTap;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2D86), Color(0xFF2F55E4), Color(0xFF5B8CFF)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primario.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -22,
                child: Transform.rotate(
                  angle: -math.pi / 14,
                  child: Icon(icono, size: 150, color: Colors.white.withValues(alpha: 0.16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 110, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiqueta.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    const SizedBox(height: 6),
                    Text(titulo,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(detalle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(accion,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador compacto para el resumen (número grande + etiqueta) con brillo del color dado.
class Indicador extends StatelessWidget {
  const Indicador({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.color,
    this.onTap,
  });

  final String valor;
  final String etiqueta;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.04)],
              ),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Column(
              children: [
                Text(valor,
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1.1)),
                const SizedBox(height: 4),
                Text(etiqueta,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textoSuave, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de línea de tiempo: hora a la izquierda, nodo + línea, y contenido (UTB App, Agenda).
class FilaLineaTiempo extends StatelessWidget {
  const FilaLineaTiempo({
    super.key,
    required this.hora,
    required this.child,
    this.color = AppColors.primarioClaro,
    this.ultimo = false,
  });

  final String hora;
  final Widget child;
  final Color color;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(hora,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)],
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: AppColors.borde,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hace aparecer a su hijo desvaneciendo y subiendo, con un retraso según [orden], para que
/// las listas entren de forma escalonada en lugar de aparecer de golpe.
class Aparecer extends StatefulWidget {
  const Aparecer({super.key, required this.child, this.orden = 0});
  final Widget child;
  final int orden;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 50 * widget.orden.clamp(0, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curva),
        child: widget.child,
      ),
    );
  }
}

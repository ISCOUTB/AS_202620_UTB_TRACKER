import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Lenguaje visual propio de UTB Tracker (ADR-0011). Toma de UTB App solo los colores; la
/// forma es nuestra: el motivo es el **plano de baldosas** del logo (cuatro salones, uno
/// encendido), los encabezados se funden con el fondo sin bordes y las tarjetas son de vidrio.

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

/// Encabezado de cada pestaña: degradado azul → índigo que se **desvanece hacia el fondo**
/// (sin borde ni esquinas, no parece una caja) con el plano de baldosas del logo arriba a la
/// derecha. Va pegado arriba (detrás de la barra de estado).
class EncabezadoDegradado extends StatelessWidget {
  const EncabezadoDegradado({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 30),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        // El degradado lleva su propia transparencia (llega a 0 abajo), así se funde con el
        // fondo sin máscaras, igual en Android y en web.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1D3FE0), Color(0xB8383ED8), Color(0x004B3BDB)],
                stops: [0, 0.5, 1],
              ),
            ),
            child: DecoratedBox(
              // Brillo índigo desde la esquina superior derecha; se apaga antes del borde
              // inferior (el radio es relativo al lado corto, la altura).
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 0.95,
                  colors: [Color(0x994B3BDB), Color(0x004B3BDB)],
                ),
              ),
              child: CustomPaint(painter: _Plano()),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: arriba).add(padding),
          child: child,
        ),
      ],
    );
  }
}

/// Motivo de la marca: rejilla de baldosas redondeadas que se apaga hacia la izquierda y hacia
/// abajo, con una baldosa encendida (el salón libre del logo).
class _Plano extends CustomPainter {
  const _Plano();

  @override
  void paint(Canvas canvas, Size size) {
    const lado = 22.0;
    const paso = 30.0;
    final columnas = (size.width * 0.5 / paso).ceil();
    final filas = (size.height * 0.75 / paso).ceil();
    final p = Paint();
    for (var f = 0; f < filas; f++) {
      for (var c = 0; c < columnas; c++) {
        final x = size.width - (c + 1) * paso + 4;
        final y = f * paso - 6.0;
        // Más visible en la esquina superior derecha.
        final peso = (1 - c / columnas) * (1 - f / filas);
        final encendida = f == 1 && c == 1;
        p.color = Colors.white.withValues(alpha: encendida ? 0.30 : 0.11 * peso);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, lado, lado), const Radius.circular(6)),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Contenedor con sombra y degradado que sí respeta las esquinas redondeadas al tocarlo.
/// (Un `Ink` con `boxShadow` dibuja la sombra en un rectángulo: se veía una caja detrás.)
class _Tocable extends StatelessWidget {
  const _Tocable({
    required this.decoration,
    required this.radio,
    required this.child,
    this.onTap,
  });

  final BoxDecoration decoration;
  final double radio;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final forma = BorderRadius.circular(radio);
    return DecoratedBox(
      decoration: decoration.copyWith(borderRadius: forma),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

/// Tarjeta destacada de vidrio: deja ver el degradado de atrás, un punto luminoso con el color
/// del estado junto a la etiqueta y, opcional, un dato grande en una baldosa a la derecha.
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
    return _Tocable(
      radio: 22,
      onTap: onTap,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          etiqueta.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                  if (detalle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      detalle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            if (datoGrande != null) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 64),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Column(
                  children: [
                    Text(
                      datoGrande!,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1),
                    ),
                    if (datoPequeno != null) ...[
                      const SizedBox(height: 3),
                      Text(datoPequeno!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Título de sección con subtítulo y flecha.
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  if (subtitulo != null)
                    Text(subtitulo!,
                        style: const TextStyle(color: AppColors.textoTenue, fontSize: 12.5)),
                ],
              ),
            ),
            if (onVerTodo != null)
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textoSuave, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Control segmentado en píldora. La opción activa se llena con el degradado y se desliza
/// suavemente.
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
      height: 46,
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
                            Icon(opciones[i].$1, size: 17),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                opciones[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
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

/// Acceso rápido compacto: baldosa en degradado con el ícono, título, una línea de detalle y
/// la acción a la derecha. Ocupa poco alto para que quepa más información en pantalla.
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
    return _Tocable(
      radio: 18,
      onTap: onTap,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primario.withValues(alpha: 0.30),
            AppColors.indigo.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: AppColors.primarioClaro.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.degradado,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.indigoClaro,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 1),
                  Text(titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(accion,
                style: const TextStyle(
                    color: AppColors.primarioClaro, fontSize: 12, fontWeight: FontWeight.w700)),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primarioClaro),
          ],
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                        fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
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

/// Fila de línea de tiempo: hora a la izquierda, nodo + línea, y contenido.
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

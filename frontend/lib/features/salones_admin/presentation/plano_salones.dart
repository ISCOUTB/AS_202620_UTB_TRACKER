import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/entities/ocupacion.dart';
import 'salones_admin_estilos.dart';

/// "Mapa" del campus: cada salón es una baldosa del color de su situación.
/// Hace el papel del mapa de Uber: de un vistazo se ve qué está libre, ocupado o con problemas.
class PlanoSalones extends StatelessWidget {
  const PlanoSalones({super.key, required this.salones, required this.onTap});

  final List<OcupacionSalon> salones;
  final ValueChanged<OcupacionSalon> onTap;

  /// Agrupa por edificio (los sin edificio van juntos al final).
  Map<String, List<OcupacionSalon>> _porEdificio() {
    final mapa = <String, List<OcupacionSalon>>{};
    for (final o in salones) {
      final e = (o.salon.edificio == null || o.salon.edificio!.isEmpty)
          ? 'Otros'
          : 'Edificio ${o.salon.edificio}';
      mapa.putIfAbsent(e, () => []).add(o);
    }
    final claves = mapa.keys.toList()..sort();
    return {for (final k in claves) k: mapa[k]!};
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CuadriculaPainter(),
      child: salones.isEmpty
          ? const Center(
              child: Text('Sin salones para mostrar', style: TextStyle(color: AppColors.textoSuave)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entrada in _porEdificio().entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Text(
                        entrada.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoTenue,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in entrada.value) _Baldosa(ocupacion: o, onTap: () => onTap(o)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Baldosa extends StatelessWidget {
  const _Baldosa({required this.ocupacion, required this.onTap});

  final OcupacionSalon ocupacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorDeSituacion(ocupacion.situacion);
    final avisos = ocupacion.solicitudesPendientes + ocupacion.reportesAbiertos;
    return Semantics(
      button: true,
      label: 'Salón ${ocupacion.salon.nombre}, ${etiquetaDeSituacion(ocupacion.situacion)}',
      child: Material(
        color: color.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 76,
            height: 62,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      ocupacion.salon.nombre,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (avisos > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.texto,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$avisos',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula tenue de fondo: da la sensación de plano sin necesitar un mapa real.
class _CuadriculaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = const Color(0xFF181818);
    canvas.drawRect(Offset.zero & size, fondo);
    final linea = Paint()
      ..color = AppColors.borde.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const paso = 28.0;
    for (var x = 0.0; x <= size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linea);
    }
    for (var y = 0.0; y <= size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

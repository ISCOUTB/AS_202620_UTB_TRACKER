import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/assets/figuras.dart';
import '../core/theme/app_theme.dart';
import '../features/salones/domain/entities/salon.dart';

/// Nombre legible y figura de cada categoría de equipo.
const Map<String, (String, String)> categoriasEquipo = {
  'computador': ('Computadores', Figuras.computador),
  'video_beam': ('Video beam', Figuras.videoBeam),
  'tv': ('TV', Figuras.tv),
  'audio': ('Audio', Figuras.audio),
  'aire_ac': ('Aire', Figuras.aireAc),
  'otro': ('Otros', Figuras.otros),
};

String nombreCategoria(String c) => categoriasEquipo[c]?.$1 ?? c;

/// Chips del equipamiento calculado de un salón (ADR-0017): figura, cantidad y, si hay equipos
/// fuera de servicio, el texto "1 dañado" además del color (no se depende solo del color).
class EquipamientoChips extends StatelessWidget {
  const EquipamientoChips({super.key, required this.equipamiento, this.compacto = false});

  final List<EquipoCategoria> equipamiento;

  /// En tarjetas: solo figura + número. Desplegado: con el nombre de la categoría.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (equipamiento.isEmpty) {
      return compacto
          ? const SizedBox.shrink()
          : const Text('Sin equipos registrados',
              style: TextStyle(color: AppColors.textoTenue, fontSize: 12.5));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final e in equipamiento) _Chip(e: e, compacto: compacto)],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.e, required this.compacto});
  final EquipoCategoria e;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final (nombre, figura) = categoriasEquipo[e.categoria] ?? (e.categoria, Figuras.otros);
    final malos = e.fueraDeServicio;
    final color = malos == 0 ? AppColors.textoSuave : AppColors.prestado;
    final texto = compacto ? '${e.total}' : '${e.total} $nombre';
    final aviso = malos == 0 ? '' : (malos == 1 ? '1 dañado' : '$malos dañados');
    return Semantics(
      label: '$nombre: ${e.total}${aviso.isEmpty ? '' : ', $aviso'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.superficieAlta.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: malos == 0 ? AppColors.borde : AppColors.prestado.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(figura, width: 16, height: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                aviso.isEmpty ? texto : '$texto · $aviso',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

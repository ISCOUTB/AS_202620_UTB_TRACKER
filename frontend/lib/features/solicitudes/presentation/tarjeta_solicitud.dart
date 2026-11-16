import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/widgets.dart';
import '../../salones/domain/entities/salon.dart';
import '../../salones_admin/presentation/salones_admin_estilos.dart';

Color colorSolicitud(String estado) => switch (estado) {
      'pendiente' => AppColors.prestado,
      'aprobado' || 'en_uso' => AppColors.disponible,
      'rechazado' => AppColors.danado,
      _ => AppColors.neutro,
    };

IconData iconoSolicitud(String estado) => switch (estado) {
      'pendiente' => Icons.hourglass_top_rounded,
      'aprobado' || 'en_uso' => Icons.check_circle_rounded,
      'rechazado' => Icons.cancel_rounded,
      _ => Icons.remove_circle_outline_rounded,
    };

/// Tarjeta compacta de una solicitud de salón. El estado se muestra con ícono + texto (no solo
/// color). [verSolicitante]: en la bandeja se ve quién la pidió; en "mías", no hace falta.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({
    super.key,
    required this.solicitud,
    this.verSolicitante = false,
    this.acciones = const [],
  });

  final PrestamoSalon solicitud;
  final bool verSolicitante;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final color = colorSolicitud(s.estado);
    final motivo = (s.motivo?.trim().isNotEmpty ?? false) ? s.motivo!.trim() : null;
    return Semantics(
      container: true,
      label: 'Solicitud del salón ${s.salonTexto}, ${s.estadoTexto}',
      child: TarjetaBorde(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.degradado,
                  ),
                  child: Text(s.salonTexto,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    verSolicitante && s.usuarioNombre != null
                        ? s.usuarioNombre!
                        : (motivo ?? 'Solicitud de salón'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(child: Insignia(texto: s.estadoTexto, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            _Linea(
              icono: Icons.schedule_rounded,
              texto: '${formatearFechaHora(s.fechaInicio)} → ${formatearHora(s.fechaFin)}',
            ),
            if (verSolicitante && motivo != null) _Linea(icono: Icons.notes_rounded, texto: motivo),
            if (s.conflicto != null && s.pendiente)
              _Linea(
                icono: Icons.warning_amber_rounded,
                texto: 'Choca con ${s.conflicto}',
                color: AppColors.danado,
              ),
            if (s.avisoSalon != null)
              _Linea(
                icono: Icons.block_rounded,
                texto: s.avisoSalon!,
                color: AppColors.prestado,
              ),
            if (s.respuesta != null)
              _Linea(
                icono: iconoSolicitud(s.estado),
                texto: '${s.estado == 'rechazado' ? 'Motivo' : 'Nota'}: ${s.respuesta}',
                color: color,
              ),
            if (s.atendidoPorNombre != null && s.atendidoEn != null)
              _Linea(
                icono: Icons.person_outline_rounded,
                texto: 'Atendió ${s.atendidoPorNombre} · ${haceCuanto(s.atendidoEn!)}',
              ),
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                for (final (i, a) in acciones.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: a),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto, this.color});
  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 15, color: color ?? AppColors.textoTenue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(texto,
                style: TextStyle(color: color ?? AppColors.textoSuave, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

/// Botones con el estilo de la app.
Widget botonSecundario(String texto, VoidCallback onPressed, {Color? color}) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        foregroundColor: color,
        side: color == null ? null : BorderSide(color: color),
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

Widget botonPrincipal(String texto, VoidCallback onPressed) => FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

/// Pide un texto (motivo del rechazo u nota). Devuelve null si se cancela.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  required String confirmar,
  bool obligatorio = false,
}) {
  final control = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final valido = !obligatorio || control.text.trim().length >= 3;
        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: control,
            autofocus: true,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: etiqueta,
              helperText: obligatorio ? 'El estudiante verá este motivo' : 'Opcional',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
            FilledButton(
              onPressed: valido ? () => Navigator.pop(context, control.text.trim()) : null,
              child: Text(confirmar),
            ),
          ],
        );
      },
    ),
  );
}

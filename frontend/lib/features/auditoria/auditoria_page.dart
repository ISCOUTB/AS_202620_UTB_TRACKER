import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/injection.dart';
import '../../core/state/carga.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/utilidades.dart';
import '../../features/auth/domain/permisos.dart';
import '../../shared/sin_acceso.dart';
import '../../shared/utb_ui.dart';
import '../../shared/widgets.dart';
import 'auditoria.dart';

/// Bitácora de auditoría (ADR-0010) para el administrador: línea de tiempo filtrable por
/// entidad y por acción, y exportación a CSV. Ojo: "Auditor" es un ROL que administra salones;
/// esta bitácora de cambios solo la ve el administrador (permiso `auditoria.ver`, ADR-0018).
class AuditoriaPage extends StatefulWidget {
  const AuditoriaPage({super.key});

  @override
  State<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<AuditoriaPage> {
  final AuditoriaController _c = sl<AuditoriaController>();

  @override
  void initState() {
    super.initState();
    _c.cargar(entidad: null, cambiarFiltro: true);
  }

  Future<void> _exportar() async {
    try {
      final csv = await _c.exportarCsv();
      await Clipboard.setData(ClipboardData(text: csv));
      // Líneas sin contar el encabezado.
      final filas = '\n'.allMatches(csv.trimRight()).length;
      if (mounted) {
        mostrarMensaje(context, 'CSV copiado ($filas filas): pégalo en Excel o Google Sheets.');
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo exportar el CSV');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConPermiso(
        permiso: Permisos.auditoriaVer,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => RefreshIndicator(
            onRefresh: () => _c.cargar(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                EncabezadoDegradado(
                  padding: const EdgeInsets.fromLTRB(12, 4, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('Bitácora de auditoría',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          'Quién hizo qué y cuándo, en todo el sistema.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 0, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                textInputAction: TextInputAction.search,
                                onSubmitted: _c.fijarAccion,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(Icons.search_rounded),
                                  hintText: 'Acción (ej. usuario.rol)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: _exportar,
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('CSV'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 58,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    children: [
                      for (final e in [null, ...AuditoriaController.entidades.keys])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(e == null ? 'Todo' : AuditoriaController.entidades[e]!),
                            selected: _c.entidad == e,
                            onSelected: (_) => _c.cargar(entidad: e, cambiarFiltro: true),
                            selectedColor: AppColors.primario,
                            backgroundColor: AppColors.superficieAlta,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: _cuerpo(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    switch (_c.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(mensaje: _c.error ?? 'Error', onReintentar: () => _c.cargar());
      case Carga.ok:
        if (_c.eventos.isEmpty) {
          return const VistaVacia(mensaje: 'Sin registros', detalle: 'Aún no hay acciones.');
        }
        final ev = _c.eventos;
        return Column(
          children: [
            for (final (i, e) in ev.indexed)
              Aparecer(
                orden: i,
                child: FilaLineaTiempo(
                  hora: '${e.ocurrioEn.toLocal().hour.toString().padLeft(2, '0')}:'
                      '${e.ocurrioEn.toLocal().minute.toString().padLeft(2, '0')}',
                  color: _color(e.accion),
                  ultimo: i == ev.length - 1,
                  child: TarjetaBorde(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.accionLegible,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        if (e.detalle != null && e.detalle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(e.detalle!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${e.actorNombre ?? 'Sistema'} · ${formatearFechaHora(e.ocurrioEn)}',
                          style: const TextStyle(color: AppColors.textoTenue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }

  Color _color(String accion) {
    if (accion.contains('eliminar') || accion.contains('cancelar')) return AppColors.danado;
    if (accion.contains('crear')) return AppColors.disponible;
    if (accion.contains('estado') || accion.contains('actualizar')) return AppColors.prestado;
    return AppColors.primarioClaro;
  }
}

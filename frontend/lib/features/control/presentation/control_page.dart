import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../../shared/sin_acceso.dart';
import '../../auth/domain/permisos.dart';
import '../../salones_admin/domain/entities/ocupacion.dart';
import '../../salones_admin/presentation/salones_admin_estilos.dart';
import 'control_controller.dart';

/// Pestaña "Control" del Auditor y el Administrador (ADR-0018): novedades de los salones
/// (reportes) por atender. Las solicitudes de salón tienen su propia pestaña (bandeja) y la
/// presencia del profesor se confirma en el control de cada salón.
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ControlController _control = sl<ControlController>();

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: si esta pantalla aparece mientras otra aún se dibuja
    // (cambio de pestaña o de rol en el modo prueba), no se avisa a mitad del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _control.cargar(conReportes: true, silencioso: _control.carga == Carga.ok);
    });
  }

  Future<void> _refrescar() => _control.cargar(conReportes: true, silencioso: true);

  Future<void> _resolver(ReporteSalon r) async {
    final error = await _control.resolverReporte(r);
    if (!mounted) return;
    mostrarMensaje(context, error ?? 'Reporte marcado como resuelto');
  }

  @override
  Widget build(BuildContext context) {
    return ConPermiso(
      permiso: Permisos.reportesGestionar,
      child: ListenableBuilder(
        listenable: _control,
        builder: (context, _) => RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              EncabezadoDegradado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text('Control',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Novedades de los salones por atender',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Indicador(
                          valor: '${_control.reportesAbiertos.length}',
                          etiqueta: 'Abiertos',
                          color: AppColors.danado,
                        ),
                        const SizedBox(width: 10),
                        Indicador(
                          valor: '${_control.reportes.length - _control.reportesAbiertos.length}',
                          etiqueta: 'Resueltos',
                          color: AppColors.disponible,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _contenido(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    switch (_control.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
          mensaje: _control.error ?? 'No se pudo cargar',
          onReintentar: () => _control.cargar(conReportes: true),
        );
      case Carga.ok:
        return _reportes();
    }
  }

  Widget _reportes() {
    final abiertos = _control.reportesAbiertos;
    final resueltos = _control.reportes.where((r) => !r.abierto).toList();
    if (_control.reportes.isEmpty) {
      return const VistaVacia(
        mensaje: 'Sin reportes',
        detalle: 'Ningún salón tiene novedades.',
      );
    }
    var orden = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (abiertos.isNotEmpty) ...[
          TituloSeccion('Abiertos', subtitulo: '${abiertos.length} novedades por atender'),
          const SizedBox(height: 14),
          for (final (i, r) in abiertos.indexed)
            Aparecer(
              orden: orden++,
              child: FilaLineaTiempo(
                hora: haceCuanto(r.creadoEn).replaceFirst('hace ', ''),
                color: AppColors.danado,
                ultimo: i == abiertos.length - 1,
                child: _TarjetaReporte(reporte: r, onResolver: () => _resolver(r)),
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (resueltos.isNotEmpty) ...[
          const TituloSeccion('Resueltos'),
          const SizedBox(height: 14),
          for (final (i, r) in resueltos.take(15).indexed)
            Aparecer(
              orden: orden++,
              child: FilaLineaTiempo(
                hora: haceCuanto(r.creadoEn).replaceFirst('hace ', ''),
                color: AppColors.disponible,
                ultimo: i == resueltos.length - 1 || i == 14,
                child: _TarjetaReporte(reporte: r),
              ),
            ),
        ],
      ],
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({required this.reporte, this.onResolver});
  final ReporteSalon reporte;
  final VoidCallback? onResolver;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    return TarjetaBorde(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(iconoDeTipoReporte(r.tipo),
                  color: r.abierto ? AppColors.danado : AppColors.disponible, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${r.salonNombre ?? 'Salón'} · ${r.tipo.etiqueta}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.descripcion, style: const TextStyle(color: AppColors.textoSuave, fontSize: 14)),
          if (r.usuarioNombre != null) ...[
            const SizedBox(height: 4),
            Text('Reportó ${r.usuarioNombre}',
                style: const TextStyle(color: AppColors.textoTenue, fontSize: 12.5)),
          ],
          if (onResolver != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: const StadiumBorder(),
                ),
                onPressed: onResolver,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Marcar resuelto'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

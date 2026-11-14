import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../salones/domain/entities/salon.dart';
import '../../salones_admin/domain/entities/ocupacion.dart';
import '../../salones_admin/presentation/salones_admin_estilos.dart';
import 'control_controller.dart';

/// Pestaña "Control": el auxiliar aprueba solicitudes de salón y atiende reportes; el
/// usuario UTB sigue el estado de sus solicitudes.
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ControlController _control = sl<ControlController>();
  final AuthController _auth = sl<AuthController>();
  int _pestana = 0;

  bool get _esAuxiliar => _auth.esAdministrador;

  @override
  void initState() {
    super.initState();
    _control.cargar(conReportes: _esAuxiliar, silencioso: _control.carga == Carga.ok);
  }

  Future<void> _refrescar() => _control.cargar(conReportes: _esAuxiliar, silencioso: true);

  Future<void> _cambiar(PrestamoSalon s, String estado) async {
    final error = await _control.cambiarSolicitud(s, estado, conReportes: _esAuxiliar);
    if (!mounted) return;
    mostrarMensaje(context, error ?? switch (estado) {
      'aprobado' => 'Solicitud aprobada',
      'rechazado' => 'Solicitud rechazada',
      _ => 'Solicitud cancelada',
    });
  }

  Future<void> _resolver(ReporteSalon r) async {
    final error = await _control.resolverReporte(r);
    if (!mounted) return;
    mostrarMensaje(context, error ?? 'Reporte marcado como resuelto');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
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
                  const SizedBox(height: 10),
                  const Text('Control',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _esAuxiliar
                        ? 'Solicitudes de salón y novedades por atender'
                        : 'El estado de tus solicitudes de salón',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Indicador(
                        valor: '${_control.pendientes.length}',
                        etiqueta: 'Pendientes',
                        color: AppColors.prestado,
                        onTap: () => setState(() => _pestana = 0),
                      ),
                      const SizedBox(width: 10),
                      if (_esAuxiliar)
                        Indicador(
                          valor: '${_control.reportesAbiertos.length}',
                          etiqueta: 'Reportes abiertos',
                          color: AppColors.danado,
                          onTap: () => setState(() => _pestana = 1),
                        )
                      else
                        Indicador(
                          valor: '${_control.resueltas.length}',
                          etiqueta: 'Respondidas',
                          color: AppColors.disponible,
                          onTap: () => setState(() => _pestana = 0),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_esAuxiliar) ...[
                    PildoraSegmentada(
                      opciones: const [
                        (Icons.event_available_rounded, 'Solicitudes'),
                        (Icons.report_problem_rounded, 'Reportes'),
                      ],
                      seleccion: _pestana,
                      onCambio: (i) => setState(() => _pestana = i),
                    ),
                    const SizedBox(height: 18),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position:
                            Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_pestana),
                      child: _contenido(),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          onReintentar: () => _control.cargar(conReportes: _esAuxiliar),
        );
      case Carga.ok:
        return _pestana == 1 && _esAuxiliar ? _reportes() : _solicitudes();
    }
  }

  Widget _solicitudes() {
    final pendientes = _control.pendientes;
    final resueltas = _control.resueltas;
    if (pendientes.isEmpty && resueltas.isEmpty) {
      return VistaVacia(
        mensaje: 'No hay solicitudes',
        detalle: _esAuxiliar
            ? 'Cuando alguien pida un salón aparecerá aquí.'
            : 'Pide un salón desde la pestaña Salones.',
      );
    }
    var orden = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendientes.isNotEmpty) ...[
          TituloSeccion('Por responder', subtitulo: '${pendientes.length} esperando respuesta'),
          const SizedBox(height: 12),
          for (final s in pendientes) ...[
            Aparecer(
              orden: orden++,
              child: _TarjetaSolicitud(
                solicitud: s,
                esAuxiliar: _esAuxiliar,
                onCambiar: (estado) => _cambiar(s, estado),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
        ],
        if (resueltas.isNotEmpty) ...[
          const TituloSeccion('Historial'),
          const SizedBox(height: 12),
          for (final s in resueltas.take(20)) ...[
            Aparecer(
              orden: orden++,
              child: _TarjetaSolicitud(solicitud: s, esAuxiliar: _esAuxiliar),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
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

Color _colorSolicitud(String estado) => switch (estado) {
      'pendiente' => AppColors.prestado,
      'aprobado' || 'en_uso' => AppColors.disponible,
      'rechazado' => AppColors.danado,
      _ => AppColors.neutro,
    };

String _etiquetaSolicitud(String estado) => switch (estado) {
      'pendiente' => 'Pendiente',
      'aprobado' => 'Aprobada',
      'en_uso' => 'En uso',
      'rechazado' => 'Rechazada',
      'finalizado' => 'Finalizada',
      'cancelado' => 'Cancelada',
      _ => estado,
    };

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({required this.solicitud, required this.esAuxiliar, this.onCambiar});
  final PrestamoSalon solicitud;
  final bool esAuxiliar;
  final ValueChanged<String>? onCambiar;

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final color = _colorSolicitud(s.estado);
    return TarjetaBorde(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppColors.degradado,
                ),
                child: Text(s.salonTexto,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (s.motivo == null || s.motivo!.isEmpty) ? 'Solicitud de salón' : s.motivo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                    Text(
                      esAuxiliar && s.usuarioNombre != null
                          ? s.usuarioNombre!
                          : formatearFechaHora(s.fechaInicio),
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Insignia(texto: _etiquetaSolicitud(s.estado), color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textoTenue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${formatearFechaHora(s.fechaInicio)} → ${formatearHora(s.fechaFin)}',
                  style: const TextStyle(color: AppColors.textoTenue, fontSize: 13),
                ),
              ),
            ],
          ),
          if (onCambiar != null && s.pendiente) ...[
            const SizedBox(height: 12),
            Row(
              children: esAuxiliar
                  ? [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: AppColors.danado,
                            side: const BorderSide(color: AppColors.danado),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => onCambiar!('rechazado'),
                          child: const Text('Rechazar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => onCambiar!('aprobado'),
                          child: const Text('Aprobar'),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => onCambiar!('cancelado'),
                          child: const Text('Cancelar solicitud'),
                        ),
                      ),
                    ],
            ),
          ],
        ],
      ),
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

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../../salones/domain/entities/salon.dart';
import 'solicitudes_controller.dart';
import 'tarjeta_solicitud.dart';

/// Filtros por estado: (valor, etiqueta). En la bandeja, 'todas' pide todas al servidor.
const _filtrosMias = [(null, 'Todas'), ('pendiente', 'Pendientes'), ('aprobado', 'Aprobadas'),
  ('rechazado', 'Rechazadas'), ('cancelado', 'Canceladas')];
const _filtrosBandeja = [('pendiente', 'Por atender'), ('aprobado', 'Aprobadas'),
  ('rechazado', 'Rechazadas'), ('todas', 'Todas')];

/// MIS SOLICITUDES (Estudiante): estado de cada pedido, motivo del rechazo y cancelar las
/// pendientes. Permiso `solicitudes.propias`.
class MisSolicitudesPage extends StatefulWidget {
  const MisSolicitudesPage({super.key, this.controller, this.onIrSalones});

  final SolicitudesController? controller;
  final VoidCallback? onIrSalones;

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
  late final SolicitudesController _c =
      widget.controller ?? sl<SolicitudesController>(instanceName: 'mias');

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: si esta pantalla aparece mientras otra aún se dibuja
    // (cambio de pestaña o de rol en el modo prueba), no se avisa a mitad del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.cargar(silencioso: _c.carga == Carga.ok);
    });
  }

  Future<void> _cancelar(PrestamoSalon s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la solicitud?'),
        content: Text('Se liberará la franja del salón ${s.salonTexto}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _c.cancelar(s);
    if (mounted) mostrarMensaje(context, error ?? 'Solicitud cancelada');
  }

  @override
  Widget build(BuildContext context) {
    return ConPermiso(
      permiso: Permisos.solicitudesPropias,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => _Lista(
          titulo: 'Mis solicitudes',
          subtitulo: 'El estado de los salones que pediste',
          indicadores: [
            ('${_c.contar('pendiente')}', 'Pendientes', AppColors.prestado),
            ('${_c.contar('aprobado')}', 'Aprobadas', AppColors.disponible),
            ('${_c.contar('rechazado')}', 'Rechazadas', AppColors.danado),
          ],
          controller: _c,
          filtros: _filtrosMias,
          seleccion: _c.estado,
          vacio: VistaVacia(
            mensaje: _c.estado == null ? 'Aún no has pedido salones' : 'Nada con este estado',
            detalle: 'Elige un salón por su tipo y equipamiento y pídelo para una franja.',
          ),
          accionVacia: widget.onIrSalones == null
              ? null
              : FilledButton.icon(
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  onPressed: widget.onIrSalones,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Pedir un salón'),
                ),
          tarjeta: (s) => TarjetaSolicitud(
            solicitud: s,
            acciones: s.pendiente
                ? [botonSecundario('Cancelar solicitud', () => _cancelar(s))]
                : const [],
          ),
        ),
      ),
    );
  }
}

/// BANDEJA DE SOLICITUDES (Auditor/Administrador): aprobar con nota opcional o rechazar con
/// motivo, con el conflicto de horario visible. Permiso `solicitudes.gestionar`.
class BandejaSolicitudesPage extends StatefulWidget {
  const BandejaSolicitudesPage({super.key, this.controller});

  final SolicitudesController? controller;

  @override
  State<BandejaSolicitudesPage> createState() => _BandejaSolicitudesPageState();
}

class _BandejaSolicitudesPageState extends State<BandejaSolicitudesPage> {
  late final SolicitudesController _c =
      widget.controller ?? sl<SolicitudesController>(instanceName: 'bandeja');

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: si esta pantalla aparece mientras otra aún se dibuja
    // (cambio de pestaña o de rol en el modo prueba), no se avisa a mitad del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.cargar(silencioso: _c.carga == Carga.ok);
    });
  }

  Future<void> _aprobar(PrestamoSalon s) async {
    final nota = await pedirTexto(context,
        titulo: 'Aprobar ${s.salonTexto}', etiqueta: 'Nota para el estudiante', confirmar: 'Aprobar');
    if (nota == null) return;
    final error = await _c.aprobar(s, nota: nota);
    if (mounted) mostrarMensaje(context, error ?? 'Solicitud aprobada. Le avisamos al estudiante.');
  }

  Future<void> _rechazar(PrestamoSalon s) async {
    final motivo = await pedirTexto(context,
        titulo: 'Rechazar ${s.salonTexto}',
        etiqueta: 'Motivo del rechazo',
        confirmar: 'Rechazar',
        obligatorio: true);
    if (motivo == null) return;
    final error = await _c.rechazar(s, motivo);
    if (mounted) mostrarMensaje(context, error ?? 'Solicitud rechazada. Le avisamos al estudiante.');
  }

  @override
  Widget build(BuildContext context) {
    return ConPermiso(
      permiso: Permisos.solicitudesGestionar,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final pendientes = _c.pendientes;
          final conConflicto = pendientes.where((s) => s.conflicto != null).length;
          return _Lista(
            titulo: 'Solicitudes',
            subtitulo: 'Pedidos de salón de los estudiantes',
            indicadores: [
              if ((_c.estado ?? 'pendiente') == 'pendiente') ...[
                ('${pendientes.length}', 'Por atender', AppColors.prestado),
                ('$conConflicto', 'Con conflicto', AppColors.danado),
              ],
            ],
            controller: _c,
            filtros: _filtrosBandeja,
            seleccion: _c.estado ?? 'pendiente',
            vacio: const VistaVacia(
              mensaje: 'No hay solicitudes aquí',
              detalle: 'Cuando un estudiante pida un salón, aparecerá en esta bandeja.',
            ),
            tarjeta: (s) => TarjetaSolicitud(
              solicitud: s,
              verSolicitante: true,
              acciones: s.pendiente
                  ? [
                      botonSecundario('Rechazar', () => _rechazar(s), color: AppColors.danado),
                      if (s.conflicto == null) botonPrincipal('Aprobar', () => _aprobar(s)),
                    ]
                  : const [],
            ),
          );
        },
      ),
    );
  }
}

/// Esqueleto común: encabezado, indicadores, filtros y la lista con sus estados.
class _Lista extends StatelessWidget {
  const _Lista({
    required this.titulo,
    required this.subtitulo,
    required this.indicadores,
    required this.controller,
    required this.filtros,
    required this.seleccion,
    required this.vacio,
    required this.tarjeta,
    this.accionVacia,
  });

  final String titulo;
  final String subtitulo;
  final List<(String, String, Color)> indicadores;
  final SolicitudesController controller;
  final List<(String?, String)> filtros;
  final String? seleccion;
  final Widget vacio;
  final Widget? accionVacia;
  final Widget Function(PrestamoSalon) tarjeta;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return RefreshIndicator(
      onRefresh: () => c.cargar(silencioso: true),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          EncabezadoDegradado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitulo,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                if (indicadores.isNotEmpty && c.carga == Carga.ok && !c.sinAcceso) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    for (final (i, (valor, etiqueta, color)) in indicadores.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Indicador(valor: valor, etiqueta: etiqueta, color: color),
                    ],
                  ]),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                for (final (valor, etiqueta) in filtros) ...[
                  ChoiceChip(
                    label: Text(etiqueta),
                    selected: seleccion == valor,
                    onSelected: (_) => c.fijarEstado(valor),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _cuerpo(context),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final c = controller;
    if (c.sinAcceso) return const SinAcceso();
    switch (c.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(mensaje: c.error ?? 'No se pudo cargar', onReintentar: c.cargar);
      case Carga.ok:
        final lista = c.visibles;
        if (lista.isEmpty) {
          return Column(children: [
            vacio,
            if (accionVacia != null) accionVacia!,
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, s) in lista.indexed) ...[
              Aparecer(orden: i, child: tarjeta(s)),
              const SizedBox(height: 10),
            ],
          ],
        );
    }
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/recurso.dart';
import 'recursos_controller.dart';

/// Ficha de un equipo fijo: dónde está (salón real), su estado y las acciones de control.
/// Los equipos no se prestan (ADR-0010), así que no hay historial de préstamos.
class RecursoDetallePage extends StatefulWidget {
  const RecursoDetallePage({super.key, required this.recurso});
  final Recurso recurso;

  @override
  State<RecursoDetallePage> createState() => _RecursoDetallePageState();
}

class _RecursoDetallePageState extends State<RecursoDetallePage> {
  final RecursosController _recursos = sl<RecursosController>();
  final AuthController _auth = sl<AuthController>();
  bool _reparando = false;

  @override
  void initState() {
    super.initState();
    // Queda como "Reciente" en el inicio. Se difiere un frame para no notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recursos.marcarReciente(widget.recurso);
    });
  }

  Future<void> _marcarReparado(Recurso r) async {
    setState(() => _reparando = true);
    final error = await _recursos.reportar(
      recursoId: r.id,
      estadoReportado: 'disponible',
      descripcion: 'Reparado y verificado por el auxiliar',
    );
    if (!mounted) return;
    setState(() => _reparando = false);
    mostrarMensaje(context, error ?? 'Equipo marcado como funcionando');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _recursos,
        builder: (context, _) {
          // El estado puede haber cambiado (alguien lo reportó): se toma la versión más reciente.
          final r = _recursos.porId(widget.recurso.id) ?? widget.recurso;
          final color = colorDeEstado(r.estado);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    EncabezadoDegradado(
                      padding: const EdgeInsets.fromLTRB(12, 4, 20, 26),
                      child: Column(
                        children: [
                          const Align(alignment: Alignment.centerLeft, child: BackButton()),
                          Hero(
                            tag: 'recurso-${r.id}',
                            child: FiguraCircular(figura: r.categoria.figura, tamano: 130),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            r.categoria.etiqueta,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(r.serial,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8), fontSize: 15)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xCC111216),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withValues(alpha: 0.5)),
                            ),
                            child: Insignia(texto: r.estado.etiqueta, color: color),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Aparecer(
                            child: TarjetaDestacada(
                              etiqueta: 'Ubicación',
                              titulo: r.edificioTexto == null
                                  ? r.salonTexto
                                  : '${r.edificioTexto} · ${r.salonTexto}',
                              detalle: r.salonUbicacion,
                              datoGrande: r.salonNombre == null ? null : r.salonTexto.split('-').last,
                              datoPequeno: r.salonNombre == null ? null : 'Salón',
                              color: AppColors.primarioClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Aparecer(
                            orden: 1,
                            child: TarjetaBorde(
                              child: Column(
                                children: [
                                  _Dato('Categoría', r.categoria.etiqueta),
                                  const Divider(height: 22),
                                  _Dato('Serial', r.serial),
                                  if (r.descripcion != null && r.descripcion!.isNotEmpty) ...[
                                    const Divider(height: 22),
                                    _Dato('Descripción', r.descripcion!),
                                  ],
                                  const Divider(height: 22),
                                  _Dato('Código interno', '#${r.id}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Aparecer(
                            orden: 2,
                            child: _AvisoEstado(recurso: r),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danado,
                            side: const BorderSide(color: AppColors.danado),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.report_problem_outlined, size: 20),
                          label: const Text('Reportar'),
                          onPressed: () => _mostrarReporte(context, r),
                        ),
                      ),
                      if (_auth.esAdministrador && !r.disponible) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(shape: const StadiumBorder()),
                            onPressed: _reparando ? null : () => _marcarReparado(r),
                            icon: const Icon(Icons.build_circle_outlined),
                            label: const Text('Marcar reparado'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarReporte(BuildContext context, Recurso recurso) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ReporteSheet(recurso: recurso),
      ),
    );
  }
}

/// Mensaje según el estado: qué significa y qué hacer.
class _AvisoEstado extends StatelessWidget {
  const _AvisoEstado({required this.recurso});
  final Recurso recurso;

  @override
  Widget build(BuildContext context) {
    final (icono, titulo, texto) = switch (recurso.estado) {
      EstadoRecurso.disponible => (
          Icons.check_circle_rounded,
          'Funcionando',
          'El equipo está operativo en su salón. Si notas una falla, repórtala.',
        ),
      EstadoRecurso.danado => (
          Icons.error_rounded,
          'Requiere atención',
          'Hay una falla reportada. El auxiliar debe gestionar la reparación.',
        ),
      EstadoRecurso.mantenimiento => (
          Icons.build_rounded,
          'En mantenimiento',
          'El equipo está siendo revisado y vuelve a su salón al terminar.',
        ),
      _ => (Icons.help_rounded, 'Sin estado', 'No hay información del estado.'),
    };
    final color = colorDeEstado(recurso.estado);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.03)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(texto, style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: AppColors.textoSuave, fontSize: 15)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ReporteSheet extends StatefulWidget {
  const _ReporteSheet({required this.recurso});
  final Recurso recurso;

  @override
  State<_ReporteSheet> createState() => _ReporteSheetState();
}

class _ReporteSheetState extends State<_ReporteSheet> {
  final RecursosController _recursos = sl<RecursosController>();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _imgCtrl = TextEditingController();

  String _estado = 'dañado';
  bool _enviando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final error = await _recursos.reportar(
      recursoId: widget.recurso.id,
      estadoReportado: _estado,
      descripcion: _descCtrl.text.trim(),
      imagenUrl: _imgCtrl.text.trim(),
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      Navigator.of(context).pop();
      mostrarMensaje(context, 'Reporte de estado enviado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Reportar novedad',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.recurso.titulo,
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text('Estado a reportar', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'dañado', label: Text('Dañado')),
              ButtonSegment(value: 'mantenimiento', label: Text('Mantenim.')),
              ButtonSegment(value: 'disponible', label: Text('Disponible')),
            ],
            selected: {_estado},
            onSelectionChanged: (set) => setState(() => _estado = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descripción del daño / novedad',
              hintText: 'Ej. No enciende, pantalla parpadea...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imgCtrl,
            decoration: const InputDecoration(
              labelText: 'URL de imagen (opcional)',
              hintText: 'https://ejemplo.com/foto.jpg',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/widgets.dart';
import '../../prestamos/domain/entities/prestamo.dart';
import '../../prestamos/presentation/prestamos_controller.dart';
import '../../prestamos/presentation/solicitar_prestamo_sheet.dart';
import '../domain/entities/recurso.dart';
import 'recursos_controller.dart';

class RecursoDetallePage extends StatefulWidget {
  const RecursoDetallePage({super.key, required this.recurso});
  final Recurso recurso;

  @override
  State<RecursoDetallePage> createState() => _RecursoDetallePageState();
}

class _RecursoDetallePageState extends State<RecursoDetallePage> {
  final RecursosController _recursos = sl<RecursosController>();
  final PrestamosController _prestamos = sl<PrestamosController>();

  @override
  void initState() {
    super.initState();
    // Queda como "Reciente" en el inicio. Se difiere un frame para no notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recursos.marcarReciente(widget.recurso);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del equipo')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_recursos, _prestamos]),
        builder: (context, _) {
          // El estado puede haber cambiado (alguien lo prestó): se toma la versión más reciente.
          final r = _recursos.porId(widget.recurso.id) ?? widget.recurso;
          final historial = _prestamos.historialDeRecurso(r.id);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Center(child: FiguraCircular(figura: r.categoria.figura, tamano: 150)),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        r.categoria.etiqueta,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Insignia(
                        texto: r.estado.etiqueta,
                        color: colorDeEstado(r.estado),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TarjetaBorde(
                      child: Column(
                        children: [
                          _Dato('Serial', r.serial),
                          const Divider(height: 22),
                          _Dato('Salón', r.salonId),
                          const Divider(height: 22),
                          _Dato('Categoría', r.categoria.etiqueta),
                          const Divider(height: 22),
                          _Dato('Código interno', '#${r.id}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Historial de préstamos',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (historial.isEmpty)
                      const Text(
                        'Este equipo todavía no se ha prestado.',
                        style: TextStyle(color: AppColors.textoSuave),
                      )
                    else
                      for (final p in historial.take(6)) _FilaHistorial(prestamo: p),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.report_problem_outlined, size: 20),
                          label: const Text('Reportar'),
                          onPressed: () => _mostrarReporte(context, r),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: r.disponible
                            ? FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => mostrarSolicitudPrestamo(context, r),
                                child: const Text('Solicitar préstamo'),
                              )
                            : FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: null,
                                child: Text('No disponible · ${r.estado.etiqueta}'),
                              ),
                      ),
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

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(etiqueta, style: const TextStyle(color: AppColors.textoSuave, fontSize: 15)),
        const Spacer(),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.prestamo});
  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    final estado = prestamo.estadoEn(DateTime.now());
    final etiqueta = switch (estado) {
      EstadoPrestamo.activo => 'En préstamo',
      EstadoPrestamo.vencido => 'Vencido',
      EstadoPrestamo.devuelto => 'Devuelto',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: colorDePrestamo(estado)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario #${prestamo.usuarioId} · ${formatearFechaHora(prestamo.fechaPrestamo)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  prestamo.devuelto
                      ? 'Devuelto ${formatearFechaHora(prestamo.fechaDevolucionReal!)}'
                      : 'Devolución esperada ${formatearFechaHora(prestamo.fechaDevolucionEsperada)}',
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(etiqueta,
              style: TextStyle(color: colorDePrestamo(estado), fontWeight: FontWeight.w700)),
        ],
      ),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/equipamiento_chips.dart';
import '../../../shared/widgets.dart';
import '../../salones/domain/entities/salon.dart';
import '../domain/disponibilidad.dart';

/// Equipos e historial de UN salón (ADR-0022). Los equipos no se prestan: solo cambia su estado.
class DisponibilidadController extends ChangeNotifier {
  DisponibilidadController(this.repo, this.salonId);

  final DisponibilidadRepository repo;
  final int salonId;

  List<EquipoSalon> _equipos = const [];
  List<EntradaHistorial> _historial = const [];
  Carga _carga = Carga.inicial;
  String? _error;

  List<EquipoSalon> get equipos => _equipos;
  List<EntradaHistorial> get historial => _historial;
  Carga get carga => _carga;
  String? get error => _error;

  Future<void> cargar() async {
    if (_carga != Carga.ok) {
      _carga = Carga.cargando;
      notifyListeners();
    }
    try {
      final r = await Future.wait<Object>([repo.equipos(salonId), repo.historial(salonId)]);
      _equipos = r[0] as List<EquipoSalon>;
      _historial = r[1] as List<EntradaHistorial>;
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      _carga = Carga.error;
      _error = e.mensaje;
    } catch (_) {
      _carga = Carga.error;
      _error = 'No se pudieron cargar los equipos';
    }
    notifyListeners();
  }

  /// Devuelve (resultado, error). Recarga equipos e historial si salió bien.
  Future<(ResultadoEstadoEquipo?, String?)> cambiarEstado(EquipoSalon e, EstadoEquipo estado,
      {int? reporteSalonId}) async {
    try {
      final r = await repo.cambiarEstadoEquipo(e.id, estado, reporteSalonId: reporteSalonId);
      await cargar();
      return (r, null);
    } on ApiException catch (x) {
      return (null, x.mensaje);
    } catch (_) {
      return (null, 'No se pudo cambiar el estado del equipo');
    }
  }

  Future<String?> _accion(Future<void> Function() hacer, String falla) async {
    try {
      await hacer();
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return falla;
    }
  }

  Future<String?> agregar(String categoria, String serial) => _accion(
      () => repo.agregarEquipo(salonId, categoria, serial), 'No se pudo agregar el equipo');

  Future<String?> retirar(EquipoSalon e) =>
      _accion(() => repo.retirarEquipo(e.id), 'No se pudo retirar el equipo');
}

Color colorEstadoEquipo(EstadoEquipo e) => switch (e) {
      EstadoEquipo.operativo => AppColors.disponible,
      EstadoEquipo.danado => AppColors.danado,
      EstadoEquipo.mantenimiento => AppColors.mantenimiento,
    };

// ─── Habilitación ───────────────────────────────────────────────────────────

/// Estado manual del salón: habilitado o deshabilitado con su motivo (no depende solo del color).
class SeccionHabilitacion extends StatelessWidget {
  const SeccionHabilitacion({
    super.key,
    required this.salon,
    required this.onDeshabilitar,
    required this.onHabilitar,
  });

  final Salon salon;
  final VoidCallback onDeshabilitar;
  final VoidCallback onHabilitar;

  @override
  Widget build(BuildContext context) {
    final habilitado = salon.habilitado;
    final color = habilitado ? AppColors.disponible : AppColors.danado;
    return TarjetaBorde(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      // En columna: con texto grande (×1,3) a 360 dp el botón no cabe al lado del motivo.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(habilitado ? Icons.check_circle_rounded : Icons.block_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(habilitado ? 'Habilitado' : 'Deshabilitado',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            habilitado
                ? (salon.ocupadoAhora ? 'Se puede solicitar · ocupado ahora' : 'Se puede solicitar')
                : (salon.avisoDeshabilitado ?? 'No se puede solicitar'),
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
          ),
          const SizedBox(height: 10),
          // El tema da ancho infinito a los botones: aquí se usa uno ajustado al texto.
          Align(
            alignment: Alignment.centerLeft,
            child: habilitado
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: onDeshabilitar,
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Deshabilitar'))
                : FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: onHabilitar,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Habilitar')),
          ),
        ],
      ),
    );
  }
}

/// Hoja para deshabilitar: el motivo es obligatorio (con "Otro" también la nota).
Future<DatosHabilitacion?> pedirDeshabilitacion(BuildContext context, {required String titulo,
    String? detalle}) {
  return showModalBottomSheet<DatosHabilitacion>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaDeshabilitar(titulo: titulo, detalle: detalle),
  );
}

class _HojaDeshabilitar extends StatefulWidget {
  const _HojaDeshabilitar({required this.titulo, this.detalle});
  final String titulo;
  final String? detalle;

  @override
  State<_HojaDeshabilitar> createState() => _HojaDeshabilitarState();
}

class _HojaDeshabilitarState extends State<_HojaDeshabilitar> {
  MotivoDeshabilitacion? _motivo;
  final _nota = TextEditingController();
  DateTime? _reapertura;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  bool get _valido =>
      _motivo != null && (_motivo != MotivoDeshabilitacion.otro || _nota.text.trim().isNotEmpty);

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      initialDate: _reapertura ?? hoy.add(const Duration(days: 7)),
      helpText: 'Reapertura estimada',
    );
    if (f != null) setState(() => _reapertura = f);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (widget.detalle != null) ...[
              const SizedBox(height: 4),
              Text(widget.detalle!, style: const TextStyle(color: AppColors.textoSuave)),
            ],
            const SizedBox(height: 14),
            const Text('Motivo (obligatorio)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in MotivoDeshabilitacion.values)
                  ChoiceChip(
                    label: Text(m.etiqueta),
                    selected: _motivo == m,
                    onSelected: (_) => setState(() => _motivo = m),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nota,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _motivo == MotivoDeshabilitacion.otro ? 'Nota (obligatoria)' : 'Nota (opcional)',
                hintText: 'Ej.: cambio de lámpara del video beam',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.event_rounded),
              label: Text(_reapertura == null
                  ? 'Reapertura estimada (opcional)'
                  : 'Reapertura: ${_reapertura!.day.toString().padLeft(2, '0')}/${_reapertura!.month.toString().padLeft(2, '0')}/${_reapertura!.year}'),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se podrá solicitar. Las solicitudes que ya existen no se cancelan solas: quedan '
              'señaladas para que decidas, y a cada estudiante le llega un aviso.',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danado),
              onPressed: _valido
                  ? () => Navigator.pop(
                        context,
                        DatosHabilitacion(
                          habilitado: false,
                          motivo: _motivo,
                          nota: _nota.text,
                          reapertura: _reapertura,
                        ),
                      )
                  : null,
              child: const Text('Deshabilitar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Equipos ─────────────────────────────────────────────────────────────────

class SeccionEquipos extends StatelessWidget {
  const SeccionEquipos({
    super.key,
    required this.controller,
    required this.onCambiarEstado,
    required this.onRetirar,
    required this.onAgregar,
    required this.onPlantilla,
  });

  final DisponibilidadController controller;
  final void Function(EquipoSalon, EstadoEquipo) onCambiarEstado;
  final ValueChanged<EquipoSalon> onRetirar;
  final VoidCallback onAgregar;
  final VoidCallback onPlantilla;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar equipo')),
            TextButton.icon(
                onPressed: onPlantilla,
                icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 18),
                label: const Text('Aplicar plantilla')),
          ],
        ),
        if (c.carga == Carga.cargando && c.equipos.isEmpty)
          const Padding(
              padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (c.carga == Carga.error)
          Text(c.error ?? 'No se pudieron cargar los equipos',
              style: const TextStyle(color: AppColors.danado))
        else if (c.equipos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Este salón no tiene equipos registrados. Agrega uno o aplica una plantilla.',
                style: TextStyle(color: AppColors.textoSuave)),
          )
        else
          for (final e in c.equipos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TarjetaBorde(
                padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombreCategoria(e.categoria),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(e.serial,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textoTenue, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Selector con texto e ícono además del color (accesible).
                    PopupMenuButton<EstadoEquipo>(
                      tooltip: 'Cambiar estado de ${nombreCategoria(e.categoria)} ${e.serial}',
                      onSelected: (estado) {
                        if (estado != e.estado) onCambiarEstado(e, estado);
                      },
                      itemBuilder: (_) => [
                        for (final s in EstadoEquipo.values)
                          CheckedPopupMenuItem(
                              value: s, checked: s == e.estado, child: Text(s.etiqueta)),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorEstadoEquipo(e.estado).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.estado.etiqueta,
                                style: TextStyle(
                                    color: colorEstadoEquipo(e.estado),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                            Icon(Icons.arrow_drop_down_rounded,
                                color: colorEstadoEquipo(e.estado), size: 20),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Retirar ${nombreCategoria(e.categoria)} ${e.serial}',
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppColors.textoSuave),
                      onPressed: () => onRetirar(e),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// Hoja "Agregar equipo": categoría + serial. Devuelve (categoria, serial) o null.
Future<(String, String)?> pedirEquipoNuevo(BuildContext context, String salon) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaEquipoNuevo(salon: salon),
  );
}

class _HojaEquipoNuevo extends StatefulWidget {
  const _HojaEquipoNuevo({required this.salon});
  final String salon;

  @override
  State<_HojaEquipoNuevo> createState() => _HojaEquipoNuevoState();
}

class _HojaEquipoNuevoState extends State<_HojaEquipoNuevo> {
  String _categoria = 'video_beam';
  final _serial = TextEditingController();

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agregar equipo a ${widget.salon}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de equipo'),
            items: [
              for (final c in categoriasEquipo.keys)
                DropdownMenuItem(value: c, child: Text(nombreCategoria(c))),
            ],
            onChanged: (c) => setState(() => _categoria = c ?? _categoria),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serial,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Serial o placa', helperText: 'Debe ser único en todo el inventario'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _serial.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (_categoria, _serial.text.trim())),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

/// Hoja de plantilla: elegir, VER la vista previa y confirmar. Devuelve el mensaje final.
Future<String?> aplicarPlantilla(BuildContext context, DisponibilidadRepository repo,
    {required List<int> salonIds, required String titulo}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaPlantilla(repo: repo, salonIds: salonIds, titulo: titulo),
  );
}

class _HojaPlantilla extends StatefulWidget {
  const _HojaPlantilla({required this.repo, required this.salonIds, required this.titulo});
  final DisponibilidadRepository repo;
  final List<int> salonIds;
  final String titulo;

  @override
  State<_HojaPlantilla> createState() => _HojaPlantillaState();
}

class _HojaPlantillaState extends State<_HojaPlantilla> {
  String _plantilla = 'aula_estandar';
  int _computadores = 20;
  List<PlantillaPorSalon>? _previa;
  bool _cargando = false;
  String? _error;

  int? get _n => _plantilla == 'laboratorio' ? _computadores : null;

  Future<void> _ir({required bool aplicar}) async {
    setState(() => _cargando = true);
    try {
      final r = await widget.repo
          .plantilla(_plantilla, widget.salonIds, computadores: _n, aplicar: aplicar);
      if (!mounted) return;
      if (aplicar) {
        final total = r.fold<int>(0, (a, p) => a + p.agregar.values.fold(0, (x, y) => x + y));
        Navigator.pop(context, total == 0 ? 'No faltaba nada' : 'Se agregaron $total equipos');
      } else {
        setState(() {
          _previa = r;
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previa = _previa;
    final total =
        previa?.fold<int>(0, (a, p) => a + p.agregar.values.fold(0, (x, y) => x + y)) ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Solo se agrega lo que falta: nada se duplica ni se quita.',
                style: TextStyle(color: AppColors.textoSuave)),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _plantilla,
              onChanged: (v) => setState(() {
                _plantilla = v ?? _plantilla;
                _previa = null;
              }),
              child: const Column(children: [
                RadioListTile(
                  value: 'aula_estandar',
                  title: Text('Aula estándar'),
                  subtitle: Text('1 video beam, 1 aire acondicionado y 1 computador del docente'),
                ),
                RadioListTile(
                  value: 'laboratorio',
                  title: Text('Laboratorio de cómputo'),
                  subtitle: Text('N computadores'),
                ),
              ]),
            ),
            if (_plantilla == 'laboratorio')
              Row(children: [
                const Expanded(child: Text('Computadores')),
                IconButton(
                  tooltip: 'Menos computadores',
                  onPressed: _computadores > 1
                      ? () => setState(() {
                            _computadores--;
                            _previa = null;
                          })
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Text('$_computadores', style: const TextStyle(fontWeight: FontWeight.w800)),
                IconButton(
                  tooltip: 'Más computadores',
                  onPressed: _computadores < 60
                      ? () => setState(() {
                            _computadores++;
                            _previa = null;
                          })
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ]),
            if (previa != null) ...[
              const SizedBox(height: 8),
              TarjetaBorde(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(total == 0 ? 'No falta nada' : 'Se agregarán $total equipos',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    for (final p in previa)
                      Text(
                        '${p.salonNombre}: ${p.agregar.isEmpty ? 'completo' : p.agregar.entries.map((e) => '${e.value} ${nombreCategoria(e.key).toLowerCase()}').join(', ')}',
                        style: const TextStyle(color: AppColors.textoSuave),
                      ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 14),
            if (previa == null)
              FilledButton(
                  onPressed: _cargando ? null : () => _ir(aplicar: false),
                  child: Text(_cargando ? 'Revisando...' : 'Ver vista previa'))
            else
              FilledButton(
                onPressed: _cargando || total == 0 ? null : () => _ir(aplicar: true),
                child: Text(_cargando ? 'Aplicando...' : 'Confirmar: agregar $total'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Historial ───────────────────────────────────────────────────────────────

class SeccionHistorial extends StatelessWidget {
  const SeccionHistorial({super.key, required this.historial});
  final List<EntradaHistorial> historial;

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Sin cambios registrados.', style: TextStyle(color: AppColors.textoSuave)),
      );
    }
    return Column(
      children: [
        for (final h in historial.take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (h.accion) {
                    'deshabilitado' => Icons.block_rounded,
                    'habilitado' => Icons.check_circle_outline_rounded,
                    _ => Icons.build_circle_outlined,
                  },
                  size: 18,
                  color: AppColors.textoSuave,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.descripcion),
                      Text(
                        '${formatearFechaHora(h.creadoEn)}${h.actorNombre == null ? '' : ' · ${h.actorNombre}'}',
                        style: const TextStyle(color: AppColors.textoTenue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Lote y resumen (panel) ──────────────────────────────────────────────────

/// Habilitar o deshabilitar un edificio o un piso completo, con vista previa.
Future<String?> cambiarLote(BuildContext context, DisponibilidadRepository repo,
    {required Map<String, List<int>> pisosPorEdificio}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _HojaLote(repo: repo, pisosPorEdificio: pisosPorEdificio),
  );
}

class _HojaLote extends StatefulWidget {
  const _HojaLote({required this.repo, required this.pisosPorEdificio});
  final DisponibilidadRepository repo;
  final Map<String, List<int>> pisosPorEdificio;

  @override
  State<_HojaLote> createState() => _HojaLoteState();
}

class _HojaLoteState extends State<_HojaLote> {
  late String _edificio = widget.pisosPorEdificio.keys.first;
  int? _piso;
  bool _habilitar = false;
  DatosHabilitacion? _datos;
  VistaPreviaLote? _previa;
  bool _cargando = false;
  String? _error;

  void _limpiar() {
    _previa = null;
    _error = null;
  }

  Future<void> _ver() async {
    var datos = const DatosHabilitacion(habilitado: true);
    if (!_habilitar) {
      final d = await pedirDeshabilitacion(context,
          titulo: 'Motivo para ${_piso == null ? 'el edificio $_edificio' : '$_edificio, piso $_piso'}');
      if (d == null) return;
      datos = d;
    }
    setState(() => _cargando = true);
    try {
      final p = await widget.repo.lote(_edificio, _piso, datos, aplicar: false);
      if (mounted) {
        setState(() {
          _datos = datos;
          _previa = p;
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  Future<void> _aplicar() async {
    setState(() => _cargando = true);
    try {
      final p = await widget.repo.lote(_edificio, _piso, _datos!, aplicar: true);
      if (mounted) {
        Navigator.pop(context,
            '${p.salones.length} salones ${_habilitar ? 'habilitados' : 'deshabilitados'}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previa = _previa;
    final pisos = widget.pisosPorEdificio[_edificio] ?? const <int>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Varios salones a la vez',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Deshabilitar'), icon: Icon(Icons.block_rounded)),
                ButtonSegment(value: true, label: Text('Habilitar'), icon: Icon(Icons.check_rounded)),
              ],
              selected: {_habilitar},
              onSelectionChanged: (v) => setState(() {
                _habilitar = v.first;
                _limpiar();
              }),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _edificio,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Edificio', isDense: true),
                  items: [
                    for (final e in widget.pisosPorEdificio.keys)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (e) => setState(() {
                    _edificio = e ?? _edificio;
                    _piso = null;
                    _limpiar();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(_edificio),
                  initialValue: _piso,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Piso', isDense: true),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                    for (final p in pisos) DropdownMenuItem<int?>(value: p, child: Text('Piso $p')),
                  ],
                  onChanged: (p) => setState(() {
                    _piso = p;
                    _limpiar();
                  }),
                ),
              ),
            ]),
            if (previa != null) ...[
              const SizedBox(height: 12),
              TarjetaBorde(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cambiarán ${previa.salones.length} salones',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (previa.salones.isNotEmpty) Text(previa.salones.join(', ')),
                    if (previa.sinCambio.isNotEmpty)
                      Text('Ya estaban así: ${previa.sinCambio.join(', ')}',
                          style: const TextStyle(color: AppColors.textoSuave)),
                    if (previa.solicitudesAfectadas > 0)
                      Text(
                        '${previa.solicitudesAfectadas} solicitudes quedarán señaladas y se avisará '
                        'a sus estudiantes.',
                        style: const TextStyle(color: AppColors.prestado),
                      ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 14),
            if (previa == null)
              FilledButton(
                  onPressed: _cargando ? null : _ver,
                  child: Text(_cargando ? 'Revisando...' : 'Ver vista previa'))
            else
              FilledButton(
                style: _habilitar ? null : FilledButton.styleFrom(backgroundColor: AppColors.danado),
                onPressed: _cargando || previa.salones.isEmpty ? null : _aplicar,
                child: Text(previa.salones.isEmpty
                    ? 'No hay nada que cambiar'
                    : 'Confirmar: ${_habilitar ? 'habilitar' : 'deshabilitar'} ${previa.salones.length}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Cuántos libres ahora" por edificio y piso (texto, no solo color).
class ResumenPorPiso extends StatelessWidget {
  const ResumenPorPiso({super.key, required this.resumen});
  final List<ResumenPiso> resumen;

  @override
  Widget build(BuildContext context) {
    if (resumen.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: resumen.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = resumen[i];
          return Semantics(
            label: '${r.edificio} piso ${r.piso ?? ''}: ${r.libres} libres de ${r.total}'
                '${r.deshabilitados > 0 ? ', ${r.deshabilitados} deshabilitados' : ''}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.superficieAlta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${r.edificio}${r.piso == null ? '' : ' · piso ${r.piso}'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  Text(
                    '${r.libres}/${r.total} libres${r.deshabilitados > 0 ? ' · ${r.deshabilitados} desh.' : ''}',
                    style: const TextStyle(color: AppColors.textoSuave, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Copia el CSV del catálogo y equipos al portapapeles (sin paquetes nuevos).
Future<String> copiarCatalogoCsv(DisponibilidadRepository repo) async {
  try {
    final csv = await repo.exportarCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    final filas = '\n'.allMatches(csv.trim()).length;
    return 'CSV copiado ($filas salones). Pégalo en una hoja de cálculo.';
  } on ApiException catch (e) {
    return e.mensaje;
  }
}

/// Aviso de "salón deshabilitado" en una solicitud (ícono + texto, no solo color).
class AvisoSalonDeshabilitado extends StatelessWidget {
  const AvisoSalonDeshabilitado({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.prestado, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto,
              style: const TextStyle(
                  color: AppColors.prestado, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

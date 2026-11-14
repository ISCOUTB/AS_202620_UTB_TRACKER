import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/salon.dart';
import 'salon_detalle_page.dart';
import 'salones_controller.dart';

class SalonesPage extends StatefulWidget {
  const SalonesPage({super.key});

  @override
  State<SalonesPage> createState() => _SalonesPageState();
}

class _SalonesPageState extends State<SalonesPage> {
  final SalonesController _salones = sl<SalonesController>();
  final AuthController _auth = sl<AuthController>();
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _salones.cargar(silencioso: _salones.carga == Carga.ok);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _abrirCrearSalon() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        // #4 — al crear un salón se limpia la búsqueda para que el nuevo sea visible
        child: _CrearSalonSheet(
          onExito: () {
            _busquedaCtrl.clear();
            _salones.fijarBusqueda('');
          },
        ),
      ),
    );
  }

  /// Edificio elegido en los chips (null = todos).
  String? _edificio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _auth.esAdministrador
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton(
                tooltip: 'Registrar salón',
                onPressed: _abrirCrearSalon,
                child: const Icon(Icons.add_rounded),
              ),
            )
          : null,
      body: ListenableBuilder(
        listenable: _salones,
        builder: (context, _) {
          final edificios = _salones.todos
              .map((s) => s.edificio)
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final libres = _salones.todos.where((s) => s.disponible).length;
          return RefreshIndicator(
            onRefresh: () => _salones.cargar(silencioso: true),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                EncabezadoDegradado(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text('Salones',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w800)),
                      Text(
                        '$libres libres de ${_salones.todos.length} en el Campus Tecnológico',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _busquedaCtrl,
                        onChanged: _salones.fijarBusqueda,
                        decoration: InputDecoration(
                          hintText: 'Buscar salón o edificio',
                          fillColor: const Color(0x33000000),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _busquedaCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _busquedaCtrl.clear();
                                    _salones.fijarBusqueda('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (edificios.length > 1)
                  SizedBox(
                    height: 58,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      children: [
                        for (final e in [null, ...edificios])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(e ?? 'Todos'),
                              selected: _edificio == e,
                              onSelected: (_) => setState(() => _edificio = e),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _construirCuerpo(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirCuerpo() {
    switch (_salones.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
          mensaje: _salones.error ?? 'No pudimos cargar los salones.',
          onReintentar: _salones.cargar,
        );
      case Carga.ok:
        final lista = _salones.filtrados
            .where((s) => _edificio == null || s.edificio == _edificio)
            .toList();
        if (lista.isEmpty) {
          return const VistaVacia(
            mensaje: 'No hay salones que coincidan',
            detalle: 'Intenta con otro término o edificio.',
          );
        }
        return Column(
          children: [
            for (final (i, s) in lista.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Aparecer(
                  key: ValueKey('${_edificio ?? ''}-${s.id}'),
                  orden: i,
                  child: _FilaSalon(
                    salon: s,
                    puedeSolicitar: !_auth.esAdministrador && s.disponible,
                    onSolicitar: () => _abrirSolicitud(s),
                  ),
                ),
              ),
          ],
        );
    }
  }

  void _abrirSolicitud(Salon salon) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _SolicitudSalonSheet(salon: salon),
    );
  }
}

class _FilaSalon extends StatelessWidget {
  const _FilaSalon({
    required this.salon,
    required this.puedeSolicitar,
    required this.onSolicitar,
  });
  final Salon salon;
  final bool puedeSolicitar;
  final VoidCallback onSolicitar;

  @override
  Widget build(BuildContext context) {
    final disponible = salon.disponible;
    final color = disponible ? AppColors.disponible : AppColors.danado;
    return TarjetaBorde(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SalonDetallePage(salon: salon)),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: disponible
                  ? AppColors.degradado
                  : LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.30),
                        color.withValues(alpha: 0.10)
                      ],
                    ),
            ),
            child: Text(
              salon.nombre,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.ubicacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (salon.edificio != null) 'Ed. ${salon.edificio}',
                    if (salon.piso != null) 'Piso ${salon.piso}',
                    '${salon.capacidad} personas',
                  ].join(' · '),
                  style: const TextStyle(
                      color: AppColors.textoSuave, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Insignia(
                  texto: disponible ? 'Libre' : _estadoLegible(salon.estado),
                  color: color,
                ),
              ],
            ),
          ),
          if (puedeSolicitar)
            IconButton.filled(
              tooltip: 'Solicitar',
              style: IconButton.styleFrom(backgroundColor: AppColors.primario),
              onPressed: onSolicitar,
              icon: const Icon(Icons.add_rounded),
            )
          else
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textoTenue),
        ],
      ),
    );
  }

  static String _estadoLegible(String e) => switch (e.toLowerCase()) {
        'mantenimiento' => 'Mantenimiento',
        'fuera_servicio' => 'Fuera de servicio',
        'ocupado' => 'Ocupado',
        _ => e,
      };
}

class _SolicitudSalonSheet extends StatefulWidget {
  const _SolicitudSalonSheet({required this.salon});
  final Salon salon;

  @override
  State<_SolicitudSalonSheet> createState() => _SolicitudSalonSheetState();
}

class _SolicitudSalonSheetState extends State<_SolicitudSalonSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final _motivo = TextEditingController();
  DateTime _inicio = DateTime.now().add(const Duration(hours: 1));
  DateTime _fin = DateTime.now().add(const Duration(hours: 2));
  bool _enviando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _seleccionar(bool inicio) async {
    final actual = inicio ? _inicio : _fin;
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: actual,
    );
    if (!mounted || fecha == null) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
    );
    if (!mounted || hora == null) return;
    final resultado = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    setState(() {
      if (inicio) {
        _inicio = resultado;
        if (!_fin.isAfter(_inicio)) {
          _fin = _inicio.add(const Duration(hours: 1));
        }
      } else {
        _fin = resultado;
      }
    });
  }

  Future<void> _enviar() async {
    if (!_fin.isAfter(_inicio)) {
      mostrarMensaje(context, 'La hora final debe ser posterior a la inicial');
      return;
    }
    setState(() => _enviando = true);
    final error = await _salones.solicitarPrestamo(
      salonId: widget.salon.id,
      fechaInicio: _inicio,
      fechaFin: _fin,
      motivo: _motivo.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      mostrarMensaje(context, error);
      return;
    }
    Navigator.pop(context);
    mostrarMensaje(context, 'Solicitud enviada correctamente');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Solicitar ${widget.salon.nombre}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inicio'),
            subtitle: Text(formatearFechaHora(_inicio)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _seleccionar(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fin'),
            subtitle: Text(formatearFechaHora(_fin)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _seleccionar(false),
          ),
          TextField(
            controller: _motivo,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: const Icon(Icons.send_outlined),
            label: Text(_enviando ? 'Enviando...' : 'Enviar solicitud'),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Crear nuevo salón ─────────────────────────────────────────────────

class _CrearSalonSheet extends StatefulWidget {
  const _CrearSalonSheet({required this.onExito});
  // #4 — callback para limpiar el buscador tras crear exitosamente
  final VoidCallback onExito;

  @override
  State<_CrearSalonSheet> createState() => _CrearSalonSheetState();
}

class _CrearSalonSheetState extends State<_CrearSalonSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _ubicacionCtrl = TextEditingController();
  final TextEditingController _edificioCtrl = TextEditingController();
  final TextEditingController _pisoCtrl = TextEditingController();
  final TextEditingController _capacidadCtrl =
      TextEditingController(text: '30');

  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _edificioCtrl.dispose();
    _pisoCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final capacidad = int.tryParse(_capacidadCtrl.text.trim()) ?? 0;

    if (nombre.isEmpty || ubicacion.isEmpty || capacidad <= 0) {
      mostrarMensaje(context, 'Completa los campos obligatorios');
      return;
    }

    setState(() => _enviando = true);
    final error = await _salones.crear(
      nombre: nombre,
      ubicacion: ubicacion,
      edificio: _edificioCtrl.text.trim(),
      piso: int.tryParse(_pisoCtrl.text.trim()),
      capacidad: capacidad,
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      Navigator.of(context).pop();
      // #4 — notificar al padre para limpiar búsqueda y mostrar el nuevo salón
      widget.onExito();
      mostrarMensaje(context, 'Salón creado exitosamente');
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
                'Nuevo Salón / Aula',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del salón *',
              hintText: 'Ej. A-301, Lab Sistemas 1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ubicacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Ubicación *',
              hintText: 'Ej. Edificio A, Piso 3',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _edificioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Edificio (opc.)',
                    hintText: 'Ej. A, B, C',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pisoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Piso (opc.)',
                    hintText: 'Ej. 3',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacidad de personas *',
              hintText: 'Ej. 35',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enviando ? null : _guardar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Registrar salón'),
          ),
        ],
      ),
    );
  }
}

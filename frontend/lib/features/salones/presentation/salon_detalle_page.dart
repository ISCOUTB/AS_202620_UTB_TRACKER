import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/salon.dart';
import 'salones_controller.dart';

class SalonDetallePage extends StatefulWidget {
  const SalonDetallePage({super.key, required this.salon});
  final Salon salon;

  @override
  State<SalonDetallePage> createState() => _SalonDetallePageState();
}

class _SalonDetallePageState extends State<SalonDetallePage> {
  final SalonesController _salones = sl<SalonesController>();
  final AuthController _auth = sl<AuthController>();

  // Estado actual del salón (se refresca al entrar a la página)
  late Salon _salonActual;

  int _diaSeleccionado = 1; // 1 = Lunes
  List<FranjaDisponible> _franjas = [];
  List<Horario> _horarios = [];
  List<PrestamoSalon> _misSolicitudesPendientes = [];
  bool _cargandoDatos = true;
  String? _errorDatos;

  final List<String> _diasNombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  @override
  void initState() {
    super.initState();
    _salonActual = widget.salon;
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargandoDatos = true;
      _errorDatos = null;
    });

    // Refresca el estado actual del salón desde el backend
    final salonActualizado = await _salones.obtenerSalonPorId(_salonActual.id);

    final (franjas, errFranjas) = await _salones.obtenerDisponibilidad(
      _salonActual.id,
      diaSemana: _diaSeleccionado,
    );
    final (horarios, errHorarios) =
        await _salones.obtenerHorarios(_salonActual.id);

    // Carga los préstamos pendientes del usuario actual para este salón
    List<PrestamoSalon> pendientes = [];
    if (!_auth.esAdministrador) {
      final usuario = _auth.usuario;
      if (usuario != null) {
        final (todos, _) =
            await _salones.obtenerPrestamosSalon(_salonActual.id);
        pendientes = todos
            .where((p) => p.usuarioId == usuario.id && p.estado == 'pendiente')
            .toList();
      }
    }

    if (mounted) {
      setState(() {
        if (salonActualizado != null) _salonActual = salonActualizado;
        _franjas = franjas;
        _horarios = horarios;
        _misSolicitudesPendientes = pendientes;
        _errorDatos = errFranjas ?? errHorarios;
        _cargandoDatos = false;
      });
    }
  }

  Future<void> _cambiarDia(int dia) async {
    setState(() {
      _diaSeleccionado = dia;
      _cargandoDatos = true;
    });
    final (franjas, _) = await _salones.obtenerDisponibilidad(
      _salonActual.id,
      diaSemana: dia,
    );
    if (mounted) {
      setState(() {
        _franjas = franjas;
        _cargandoDatos = false;
      });
    }
  }

  /// Abre el sheet de préstamo, opcionalmente pre-llenando una franja libre.
  void _abrirSolicitudPrestamo({TimeOfDay? horaInicio, TimeOfDay? horaFin}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _SolicitarPrestamoSalonSheet(
          salon: _salonActual,
          onExito: _cargarTodo,
          horaInicioInicial: horaInicio,
          horaFinInicial: horaFin,
        ),
      ),
    );
  }

  void _abrirAgregarHorario() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AgregarHorarioSheet(
          salon: _salonActual,
          onExito: _cargarTodo,
        ),
      ),
    );
  }

  Future<void> _cancelarSolicitud(PrestamoSalon prestamo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text('¿Deseas cancelar esta solicitud del salón?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danado),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final error = await _salones.cancelarPrestamoSalon(prestamo.id);
    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      mostrarMensaje(context, 'Solicitud cancelada');
      _cargarTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _salonActual;
    // El salón solo acepta préstamos si está disponible
    final puedePrestar = s.disponible;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          EncabezadoDegradado(
            padding: const EdgeInsets.fromLTRB(12, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BackButton(),
                    const Spacer(),
                    if (_auth.esAdministrador)
                      IconButton(
                        icon: const Icon(Icons.more_time_rounded),
                        tooltip: 'Configurar horario de clase',
                        onPressed: _abrirAgregarHorario,
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (s.edificio != null)
                            'ED. ${s.edificio!.toUpperCase()}',
                          if (s.piso != null) 'PISO ${s.piso}'
                        ].join(' · '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(s.nombre,
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w800)),
                      Text(s.ubicacion,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Indicador(
                            valor: '${s.capacidad}',
                            etiqueta: 'Personas',
                            color: AppColors.indigoClaro,
                          ),
                          const SizedBox(width: 10),
                          Indicador(
                            valor: s.disponible ? 'Libre' : 'No',
                            etiqueta: s.disponible ? 'Disponible' : s.estado,
                            color: s.disponible
                                ? AppColors.disponible
                                : AppColors.danado,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección: mis solicitudes pendientes (solo usuarios regulares)
                if (_misSolicitudesPendientes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Mis solicitudes pendientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  for (final p in _misSolicitudesPendientes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TarjetaBorde(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions_rounded,
                                color: AppColors.textoSuave, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatFecha(p.fechaInicio)} · ${_formatHora(p.fechaInicio)} – ${_formatHora(p.fechaFin)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  if (p.motivo != null && p.motivo!.isNotEmpty)
                                    Text(p.motivo!,
                                        style: const TextStyle(
                                            color: AppColors.textoSuave,
                                            fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _cancelarSolicitud(p),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danado),
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // Sección de Disponibilidad para Préstamos
                Row(
                  children: [
                    const Text(
                      'Horarios libres',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_cargandoDatos)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textoSuave),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 1; i <= 6; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_diasNombres[i - 1]),
                            selected: _diaSeleccionado == i,
                            onSelected: (_) => _cambiarDia(i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Error de carga (si ocurrió)
                if (_errorDatos != null && !_cargandoDatos)
                  TarjetaBorde(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danado, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorDatos!,
                              style: const TextStyle(
                                  color: AppColors.danado, fontSize: 13)),
                        ),
                      ],
                    ),
                  )
                // Franjas libres — al tocar una se pre-llena el formulario
                else if (_franjas.isEmpty && !_cargandoDatos)
                  const TarjetaBorde(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay franjas libres este día (completamente ocupado por clases).',
                      style: TextStyle(color: AppColors.textoSuave),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in _franjas)
                        ActionChip(
                          avatar: const Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.disponible),
                          label: Text(
                            '${f.horaInicio.substring(0, 5)} – ${f.horaFin.substring(0, 5)} libre',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          backgroundColor: AppColors.superficieAlta,
                          side: BorderSide(
                              color:
                                  AppColors.disponible.withValues(alpha: 0.5)),
                          tooltip: 'Solicitar el salón en esta franja',
                          // pre-llena fecha y horas al tocar la franja
                          onPressed: puedePrestar
                              ? () {
                                  final partes = f.horaInicio.split(':');
                                  final partesF = f.horaFin.split(':');
                                  _abrirSolicitudPrestamo(
                                    horaInicio: TimeOfDay(
                                      hour: int.parse(partes[0]),
                                      minute: int.parse(partes[1]),
                                    ),
                                    horaFin: TimeOfDay(
                                      hour: int.parse(partesF[0]),
                                      minute: int.parse(partesF[1]),
                                    ),
                                  );
                                }
                              : null,
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Botón deshabilitado si el salón no está disponible
                if (!puedePrestar)
                  TarjetaBorde(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.block_rounded,
                            color: AppColors.danado, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Este salón no se puede solicitar ahora (estado: ${s.estado})',
                            style: const TextStyle(
                                color: AppColors.danado, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Solicitar este salón'),
                    onPressed: _abrirSolicitudPrestamo,
                  ),

                const SizedBox(height: 30),

                // Sección de Horarios Académicos
                Row(
                  children: [
                    const Text(
                      'Horarios Académicos (Clases)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${_horarios.length} registrados',
                        style: const TextStyle(color: AppColors.textoSuave)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_horarios.isEmpty)
                  const TarjetaBorde(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aún no hay horarios de clases configurados para este salón.',
                      style: TextStyle(color: AppColors.textoSuave),
                    ),
                  )
                else
                  for (final h in _horarios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TarjetaBorde(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.superficieAlta,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                h.diaNombre.substring(0, 3).toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.materia ?? 'Clase regular',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    h.profesor != null
                                        ? 'Prof. ${h.profesor}'
                                        : 'Sin docente asignado',
                                    style: const TextStyle(
                                        color: AppColors.textoSuave,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${h.horaInicio.substring(0, 5)} - ${h.horaFin.substring(0, 5)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Sheet: Solicitar préstamo de salón ────────────────────────────────────────

class _SolicitarPrestamoSalonSheet extends StatefulWidget {
  const _SolicitarPrestamoSalonSheet({
    required this.salon,
    required this.onExito,
    this.horaInicioInicial,
    this.horaFinInicial,
  });

  final Salon salon;
  final VoidCallback onExito;
  final TimeOfDay? horaInicioInicial;
  final TimeOfDay? horaFinInicial;

  @override
  State<_SolicitarPrestamoSalonSheet> createState() =>
      _SolicitarPrestamoSalonSheetState();
}

class _SolicitarPrestamoSalonSheetState
    extends State<_SolicitarPrestamoSalonSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final TextEditingController _motivoCtrl = TextEditingController();

  late DateTime _fecha;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;
  bool _enviando = false;

  // Duración mínima y máxima definidas en el backend
  static const _minMinutos = 30;
  static const _maxMinutos = 240; // 4 horas

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
    _horaInicio =
        widget.horaInicioInicial ?? const TimeOfDay(hour: 8, minute: 0);
    _horaFin = widget.horaFinInicial ?? const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  /// Advertencia de duración mostrada en tiempo real bajo los pickers.
  String? get _advertenciaDuracion {
    final dtInicio = _dtInicio;
    final dtFin = _dtFin;
    if (!dtFin.isAfter(dtInicio)) return null; // validación separada
    final minutos = dtFin.difference(dtInicio).inMinutes;
    if (minutos < _minMinutos) {
      return 'Duración mínima: $_minMinutos minutos (actual: ${minutos}min)';
    }
    if (minutos > _maxMinutos) {
      return 'Duración máxima: ${_maxMinutos ~/ 60} horas (actual: ${minutos}min)';
    }
    return null;
  }

  DateTime get _dtInicio => DateTime(_fecha.year, _fecha.month, _fecha.day,
      _horaInicio.hour, _horaInicio.minute);
  DateTime get _dtFin => DateTime(
      _fecha.year, _fecha.month, _fecha.day, _horaFin.hour, _horaFin.minute);

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _elegirHoraInicio() async {
    final picked =
        await showTimePicker(context: context, initialTime: _horaInicio);
    if (picked != null) setState(() => _horaInicio = picked);
  }

  Future<void> _elegirHoraFin() async {
    final picked =
        await showTimePicker(context: context, initialTime: _horaFin);
    if (picked != null) setState(() => _horaFin = picked);
  }

  Future<void> _enviar() async {
    final dtInicio = _dtInicio;
    final dtFin = _dtFin;

    // Validar que no sea en el pasado
    if (dtInicio.isBefore(DateTime.now())) {
      mostrarMensaje(context, 'No puedes solicitar el salón en el pasado');
      return;
    }

    if (!dtFin.isAfter(dtInicio)) {
      mostrarMensaje(
          context, 'La hora de fin debe ser posterior a la de inicio');
      return;
    }

    // Bloquear envío si la duración está fuera de rango
    final minutos = dtFin.difference(dtInicio).inMinutes;
    if (minutos < _minMinutos) {
      mostrarMensaje(context, 'La duración mínima es $_minMinutos minutos');
      return;
    }
    if (minutos > _maxMinutos) {
      mostrarMensaje(
          context, 'La duración máxima es ${_maxMinutos ~/ 60} horas');
      return;
    }

    setState(() => _enviando = true);
    final error = await _salones.solicitarPrestamo(
      salonId: widget.salon.id,
      fechaInicio: dtInicio,
      fechaFin: dtFin,
      motivo: _motivoCtrl.text.trim(),
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      Navigator.of(context).pop();
      widget.onExito();
      mostrarMensaje(context, 'Solicitud enviada. El auxiliar te confirmará');
    }
  }

  @override
  Widget build(BuildContext context) {
    final advertencia = _advertenciaDuracion;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Prestar ${widget.salon.nombre}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppColors.superficieAlta,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Fecha de uso'),
            subtitle: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: _elegirFecha,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  tileColor: AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.schedule),
                  title: const Text('Inicio', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaInicio.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: _elegirHoraInicio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  tileColor: AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.schedule),
                  title: const Text('Fin', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaFin.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: _elegirHoraFin,
                ),
              ),
            ],
          ),
          // Advertencia de duración en tiempo real
          if (advertencia != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.danado),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    advertencia,
                    style:
                        const TextStyle(color: AppColors.danado, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _motivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Ej. Grupo de estudio, monitoría...',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            // Deshabilitar si hay advertencia de duración
            onPressed: (_enviando || advertencia != null) ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: Agregar horario académico ─────────────────────────────────────────

class _AgregarHorarioSheet extends StatefulWidget {
  const _AgregarHorarioSheet({required this.salon, required this.onExito});
  final Salon salon;
  final VoidCallback onExito;

  @override
  State<_AgregarHorarioSheet> createState() => _AgregarHorarioSheetState();
}

class _AgregarHorarioSheetState extends State<_AgregarHorarioSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final TextEditingController _materiaCtrl = TextEditingController();
  final TextEditingController _profesorCtrl = TextEditingController();
  final TextEditingController _semestreCtrl =
      TextEditingController(text: '2026-2');

  int _diaSemana = 1;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);
  bool _enviando = false;

  @override
  void dispose() {
    _materiaCtrl.dispose();
    _profesorCtrl.dispose();
    _semestreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Validar que horaFin > horaInicio antes de llamar al backend
    final inicioEnMinutos = _horaInicio.hour * 60 + _horaInicio.minute;
    final finEnMinutos = _horaFin.hour * 60 + _horaFin.minute;
    if (finEnMinutos <= inicioEnMinutos) {
      mostrarMensaje(
          context, 'La hora de fin debe ser posterior a la hora de inicio');
      return;
    }

    final horaInicioStr =
        '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}:00';
    final horaFinStr =
        '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}:00';

    setState(() => _enviando = true);
    final error = await _salones.agregarHorario(
      salonId: widget.salon.id,
      diaSemana: _diaSemana,
      horaInicio: horaInicioStr,
      horaFin: horaFinStr,
      materia: _materiaCtrl.text.trim(),
      profesor: _profesorCtrl.text.trim(),
      semestre: _semestreCtrl.text.trim(),
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      Navigator.of(context).pop();
      widget.onExito();
      mostrarMensaje(context, 'Horario de clase guardado');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Indicador visual de que fin <= inicio
    final finInvalido = (_horaFin.hour * 60 + _horaFin.minute) <=
        (_horaInicio.hour * 60 + _horaInicio.minute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Horario para ${widget.salon.nombre}',
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _diaSemana,
            decoration: const InputDecoration(labelText: 'Día de la semana'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Lunes')),
              DropdownMenuItem(value: 2, child: Text('Martes')),
              DropdownMenuItem(value: 3, child: Text('Miércoles')),
              DropdownMenuItem(value: 4, child: Text('Jueves')),
              DropdownMenuItem(value: 5, child: Text('Viernes')),
              DropdownMenuItem(value: 6, child: Text('Sábado')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _diaSemana = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  tileColor: AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  title:
                      const Text('Hora Inicio', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaInicio.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _horaInicio);
                    if (picked != null) setState(() => _horaInicio = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  tileColor: finInvalido
                      ? AppColors.danado.withValues(alpha: 0.12)
                      : AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: finInvalido
                        ? const BorderSide(color: AppColors.danado, width: 1)
                        : BorderSide.none,
                  ),
                  title: const Text('Hora Fin', style: TextStyle(fontSize: 12)),
                  subtitle: Text(
                    _horaFin.format(context),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: finInvalido ? AppColors.danado : null,
                    ),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _horaFin);
                    if (picked != null) setState(() => _horaFin = picked);
                  },
                ),
              ),
            ],
          ),
          // Mensaje de error inline si fin <= inicio
          if (finInvalido) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.danado),
                SizedBox(width: 6),
                Text(
                  'La hora de fin debe ser posterior a la de inicio',
                  style: TextStyle(color: AppColors.danado, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _materiaCtrl,
            decoration: const InputDecoration(
              labelText: 'Materia / Asignatura',
              hintText: 'Ej. Arquitectura de Software',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _profesorCtrl,
            decoration: const InputDecoration(
              labelText: 'Docente / Profesor',
              hintText: 'Ej. Dr. Martínez',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            // Deshabilitar si las horas son inválidas
            onPressed: (_enviando || finInvalido) ? null : _guardar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar horario'),
          ),
        ],
      ),
    );
  }
}

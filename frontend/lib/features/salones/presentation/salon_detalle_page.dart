import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
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

  int _diaSeleccionado = 1; // 1 = Lunes
  List<FranjaDisponible> _franjas = [];
  List<Horario> _horarios = [];
  bool _cargandoDatos = true;

  final List<String> _diasNombres = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
  ];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargandoDatos = true);
    final franjas = await _salones.obtenerDisponibilidad(
      widget.salon.id,
      diaSemana: _diaSeleccionado,
    );
    final horarios = await _salones.obtenerHorarios(widget.salon.id);
    if (mounted) {
      setState(() {
        _franjas = franjas;
        _horarios = horarios;
        _cargandoDatos = false;
      });
    }
  }

  Future<void> _cambiarDia(int dia) async {
    setState(() {
      _diaSeleccionado = dia;
      _cargandoDatos = true;
    });
    final franjas = await _salones.obtenerDisponibilidad(
      widget.salon.id,
      diaSemana: dia,
    );
    if (mounted) {
      setState(() {
        _franjas = franjas;
        _cargandoDatos = false;
      });
    }
  }

  void _abrirSolicitudPrestamo() {
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
          salon: widget.salon,
          onExito: _cargarTodo,
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
          salon: widget.salon,
          onExito: _cargarTodo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.salon;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.nombre),
        actions: [
          if (_auth.esAdministrador)
            IconButton(
              icon: const Icon(Icons.more_time_rounded),
              tooltip: 'Configurar horario de clase',
              onPressed: _abrirAgregarHorario,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          TarjetaBorde(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.superficieAlta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.meeting_room_rounded, size: 30, color: AppColors.texto),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(s.detalleUbicacion, style: const TextStyle(color: AppColors.textoSuave)),
                        ],
                      ),
                    ),
                    Insignia(
                      texto: s.estado.toUpperCase(),
                      color: s.disponible ? AppColors.disponible : AppColors.danado,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(icono: Icons.people_alt_outlined, titulo: 'Capacidad', valor: '${s.capacidad} est.'),
                    _InfoItem(icono: Icons.stairs_outlined, titulo: 'Piso', valor: s.piso?.toString() ?? 'N/A'),
                    _InfoItem(icono: Icons.apartment_outlined, titulo: 'Edificio', valor: s.edificio ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Disponibilidad para Préstamos
          Row(
            children: [
              const Text(
                'Disponibilidad para Préstamo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_cargandoDatos)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textoSuave),
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
          if (_franjas.isEmpty && !_cargandoDatos)
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
                  Chip(
                    avatar: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.disponible),
                    label: Text(
                      '${f.horaInicio.substring(0, 5)} - ${f.horaFin.substring(0, 5)} libre',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    backgroundColor: AppColors.superficieAlta,
                    side: BorderSide(color: AppColors.disponible.withOpacity(0.5)),
                  ),
              ],
            ),

          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.event_available_rounded),
            label: const Text('Solicitar préstamo de este salón'),
            onPressed: _abrirSolicitudPrestamo,
          ),

          const SizedBox(height: 30),

          // Sección de Horarios Académicos
          Row(
            children: [
              const Text(
                'Horarios Académicos (Clases)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${_horarios.length} registrados', style: const TextStyle(color: AppColors.textoSuave)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.superficieAlta,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          h.diaNombre.substring(0, 3).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.materia ?? 'Clase regular',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              h.profesor != null ? 'Prof. ${h.profesor}' : 'Sin docente asignado',
                              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${h.horaInicio.substring(0, 5)} - ${h.horaFin.substring(0, 5)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icono, required this.titulo, required this.valor});
  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: AppColors.textoSuave, size: 20),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(color: AppColors.textoSuave, fontSize: 11)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _SolicitarPrestamoSalonSheet extends StatefulWidget {
  const _SolicitarPrestamoSalonSheet({required this.salon, required this.onExito});
  final Salon salon;
  final VoidCallback onExito;

  @override
  State<_SolicitarPrestamoSalonSheet> createState() => _SolicitarPrestamoSalonSheetState();
}

class _SolicitarPrestamoSalonSheetState extends State<_SolicitarPrestamoSalonSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final TextEditingController _motivoCtrl = TextEditingController();

  DateTime _fecha = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 10, minute: 0);
  bool _enviando = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

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
    final picked = await showTimePicker(context: context, initialTime: _horaInicio);
    if (picked != null) setState(() => _horaInicio = picked);
  }

  Future<void> _elegirHoraFin() async {
    final picked = await showTimePicker(context: context, initialTime: _horaFin);
    if (picked != null) setState(() => _horaFin = picked);
  }

  Future<void> _enviar() async {
    final dtInicio = DateTime(_fecha.year, _fecha.month, _fecha.day, _horaInicio.hour, _horaInicio.minute);
    final dtFin = DateTime(_fecha.year, _fecha.month, _fecha.day, _horaFin.hour, _horaFin.minute);

    if (!dtFin.isAfter(dtInicio)) {
      mostrarMensaje(context, 'La hora de fin debe ser posterior a la de inicio');
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
      mostrarMensaje(context, 'Solicitud de préstamo registrada con éxito');
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
              Text(
                'Prestar ${widget.salon.nombre}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppColors.superficieAlta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Fecha del préstamo'),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.schedule),
                  title: const Text('Inicio', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaInicio.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: _elegirHoraInicio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  tileColor: AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.schedule),
                  title: const Text('Fin', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaFin.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: _elegirHoraFin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo del préstamo (opcional)',
              hintText: 'Ej. Grupo de estudio, monitoría...',
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
                : const Text('Confirmar préstamo'),
          ),
        ],
      ),
    );
  }
}

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
  final TextEditingController _semestreCtrl = TextEditingController(text: '2026-2');

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
    final horaInicioStr =
        '${_horaInicio.hour.toString().padLeft(2, "0")}:${_horaInicio.minute.toString().padLeft(2, "0")}:00';
    final horaFinStr =
        '${_horaFin.hour.toString().padLeft(2, "0")}:${_horaFin.minute.toString().padLeft(2, "0")}:00';

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
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _diaSemana,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text('Hora Inicio', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaInicio.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _horaInicio);
                    if (picked != null) setState(() => _horaInicio = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  tileColor: AppColors.superficieAlta,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text('Hora Fin', style: TextStyle(fontSize: 12)),
                  subtitle: Text(_horaFin.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _horaFin);
                    if (picked != null) setState(() => _horaFin = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _materiaCtrl,
            decoration: const InputDecoration(labelText: 'Materia / Asignatura', hintText: 'Ej. Arquitectura de Software'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _profesorCtrl,
            decoration: const InputDecoration(labelText: 'Docente / Profesor', hintText: 'Ej. Dr. Martínez'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _enviando ? null : _guardar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Guardar horario'),
          ),
        ],
      ),
    );
  }
}

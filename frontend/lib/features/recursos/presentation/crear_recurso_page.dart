import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../salones/presentation/salones_controller.dart';
import '../domain/entities/recurso.dart';
import 'recursos_controller.dart';

/// Registro de un equipo nuevo (solo auxiliares). POST /recursos.
class CrearRecursoPage extends StatefulWidget {
  const CrearRecursoPage({super.key});

  @override
  State<CrearRecursoPage> createState() => _CrearRecursoPageState();
}

class _CrearRecursoPageState extends State<CrearRecursoPage> {
  final _form = GlobalKey<FormState>();
  final _serial = TextEditingController();
  final RecursosController _recursos = sl<RecursosController>();
  final SalonesController _salones = sl<SalonesController>();

  int? _salonIdSeleccionado;
  CategoriaRecurso _categoria = CategoriaRecurso.videoBeam;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _salones.cargar(silencioso: true);
  }

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await _recursos.crear(
      categoria: _categoria.codigo,
      salonId: _salonIdSeleccionado,
      serial: _serial.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      mostrarMensaje(context, 'Equipo registrado: ${_serial.text.trim()}');
    } else {
      // 409 → "Ya existe un recurso con ese serial"
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar equipo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Categoría', style: TextStyle(color: AppColors.textoSuave)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in CategoriaRecurso.creables)
                      InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () => setState(() => _categoria = c),
                        child: Container(
                          width: 92,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _categoria == c ? AppColors.texto : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              FiguraCircular(figura: c.figura, tamano: 64),
                              const SizedBox(height: 6),
                              Text(c.etiqueta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                ListenableBuilder(
                  listenable: _salones,
                  builder: (context, _) {
                    final salones = _salones.todos;
                    final estaCargando =
                        _salones.carga == Carga.cargando && salones.isEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _salonIdSeleccionado,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Salón',
                            hintText: estaCargando
                                ? 'Cargando salones...'
                                : 'Selecciona un salón',
                            suffixIcon: estaCargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Padding(
                                      padding: EdgeInsets.all(14),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textoSuave,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          dropdownColor: AppColors.superficie,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textoSuave,
                          ),
                          items: [
                            for (final s in salones)
                              DropdownMenuItem<int>(
                                value: s.id,
                                child: Text(
                                  '${s.nombre} · ${s.ubicacion}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                          ],
                          onChanged: estaCargando
                              ? null
                              : (val) {
                                  setState(() => _salonIdSeleccionado = val);
                                },
                          validator: (v) =>
                              v == null ? 'Selecciona un salón' : null,
                        ),
                        if (salones.isEmpty && _salones.carga == Carga.ok)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'No hay salones disponibles. Registra un salón primero.',
                              style: TextStyle(
                                color: AppColors.prestado,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _serial,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  onFieldSubmitted: (_) => _guardar(),
                  decoration: const InputDecoration(
                    labelText: 'Serial',
                    hintText: 'VB-DEMO-01',
                    helperText: 'No puede repetirse',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Indica el serial' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.danado)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Text('Guardar equipo'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nace como "Disponible". El estado se gestiona con los préstamos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textoTenue, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

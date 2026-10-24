import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
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
  final _salon = TextEditingController();
  final _serial = TextEditingController();
  final RecursosController _recursos = sl<RecursosController>();

  CategoriaRecurso _categoria = CategoriaRecurso.videoBeam;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _salon.dispose();
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
      salonId: _salon.text,
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
                TextFormField(
                  controller: _salon,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Salón',
                    hintText: 'A1-304',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Indica el salón' : null,
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

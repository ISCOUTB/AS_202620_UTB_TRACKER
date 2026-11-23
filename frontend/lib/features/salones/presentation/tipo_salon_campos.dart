import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/equipamiento_chips.dart';
import '../../../shared/uber_widgets.dart';
import '../domain/entities/salon.dart';
import 'salones_controller.dart';

/// Selector de tipo + descripción (máx. 500) + "Sugerido: … [Usar]" (ADR-0017).
/// Lo usan el formulario de crear salón y el de editar.
class CamposTipoSalon extends StatelessWidget {
  const CamposTipoSalon({
    super.key,
    required this.tipo,
    required this.onTipo,
    required this.descripcion,
    this.sugerido,
  });

  final TipoSalon tipo;
  final ValueChanged<TipoSalon> onTipo;
  final TextEditingController descripcion;
  final TipoSalon? sugerido;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<TipoSalon>(
          initialValue: tipo,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de salón'),
          items: [
            for (final t in TipoSalon.values) DropdownMenuItem(value: t, child: Text(t.etiqueta)),
          ],
          onChanged: (t) {
            if (t != null) onTipo(t);
          },
        ),
        if (sugerido != null && sugerido != tipo) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            decoration: BoxDecoration(
              color: AppColors.seleccion,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.indigoClaro),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Sugerido por su equipamiento: ${sugerido!.etiqueta}',
                      style: const TextStyle(fontSize: 12.5)),
                ),
                TextButton(onPressed: () => onTipo(sugerido!), child: const Text('Usar')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: descripcion,
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            hintText: 'Ej. Tablero inteligente, cortinas oscuras…',
          ),
        ),
      ],
    );
  }
}

/// Hoja para que el auxiliar cambie tipo y descripción de un salón existente.
Future<Salon?> mostrarEditarTipoSalon(BuildContext context, Salon salon) {
  return showModalBottomSheet<Salon>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditarTipoSheet(salon: salon),
  );
}

class _EditarTipoSheet extends StatefulWidget {
  const _EditarTipoSheet({required this.salon});
  final Salon salon;

  @override
  State<_EditarTipoSheet> createState() => _EditarTipoSheetState();
}

class _EditarTipoSheetState extends State<_EditarTipoSheet> {
  late TipoSalon _tipo = widget.salon.tipo;
  late final _descripcion = TextEditingController(text: widget.salon.descripcion ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final salones = sl<SalonesController>();
    final error = await salones.actualizarTipoYDescripcion(widget.salon.id, _tipo, _descripcion.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context, salones.porId(widget.salon.id));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Editar ${widget.salon.nombre}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Equipamiento (se calcula de los equipos del salón)',
              style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
          const SizedBox(height: 6),
          EquipamientoChips(equipamiento: widget.salon.equipamiento),
          const SizedBox(height: 14),
          CamposTipoSalon(
            tipo: _tipo,
            onTipo: (t) => setState(() => _tipo = t),
            descripcion: _descripcion,
            sugerido: widget.salon.tipoSugerido,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ),
          const SizedBox(height: 10),
          BotonPildora(texto: 'Guardar', cargando: _guardando, onPressed: _guardar),
        ],
      ),
    );
  }
}

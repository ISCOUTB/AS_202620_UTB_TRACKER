import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/entities/recurso.dart';
import 'recursos_controller.dart';

/// Valor especial para "quitar el filtro de salón".
const String kTodosLosSalones = '__todos__';

/// Hoja de filtros (categoría, estado, salón). Aplica sobre el controlador al pulsar "Aplicar".
/// Devuelve true si el usuario aplicó los filtros.
Future<bool?> mostrarFiltros(BuildContext context, RecursosController recursos) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FiltrosSheet(recursos: recursos),
  );
}

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({required this.recursos});
  final RecursosController recursos;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late CategoriaRecurso? _categoria = widget.recursos.categoria;
  late EstadoRecurso? _estado = widget.recursos.estado;
  late String? _salon = widget.recursos.salon;

  @override
  Widget build(BuildContext context) {
    final salones = widget.recursos.salones;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filtros',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _categoria = null;
                      _estado = null;
                      _salon = null;
                    }),
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _Subtitulo('Categoría'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in CategoriaRecurso.creables)
                    ChoiceChip(
                      label: Text(c.etiqueta),
                      selected: _categoria == c,
                      onSelected: (v) => setState(() => _categoria = v ? c : null),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _Subtitulo('Estado'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in EstadoRecurso.values.where((x) => x != EstadoRecurso.desconocido))
                    ChoiceChip(
                      label: Text(e.etiqueta),
                      selected: _estado == e,
                      onSelected: (v) => setState(() => _estado = v ? e : null),
                    ),
                ],
              ),
              if (salones.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _Subtitulo('Salón'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in salones)
                      ChoiceChip(
                        label: Text(s),
                        selected: _salon == s,
                        onSelected: (v) => setState(() => _salon = v ? s : null),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  widget.recursos
                    ..fijarCategoria(_categoria)
                    ..fijarEstado(_estado)
                    ..fijarSalon(_salon);
                  Navigator.of(context).pop(true);
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: const TextStyle(color: AppColors.textoSuave, fontSize: 14)),
      );
}

/// Selector rápido de salón (la "ubicación actual" de la cabecera del inicio).
/// Devuelve el salón elegido, [kTodosLosSalones] o null si se cerró sin elegir.
Future<String?> mostrarSelectorSalon(
  BuildContext context, {
  required List<String> salones,
  required String? actual,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('¿En qué salón estás?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.apartment_rounded),
            title: const Text('Todos los salones'),
            trailing: actual == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(kTodosLosSalones),
          ),
          for (final s in salones)
            ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: Text('Salón $s'),
              trailing: actual == s ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(s),
            ),
          if (salones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aún no hay salones con equipos registrados.',
                style: TextStyle(color: AppColors.textoSuave),
              ),
            ),
        ],
      ),
    ),
  );
}

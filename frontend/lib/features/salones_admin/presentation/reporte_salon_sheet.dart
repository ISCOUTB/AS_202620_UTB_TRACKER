import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import '../domain/entities/ocupacion.dart';
import 'salones_admin_estilos.dart';

/// Hoja inferior para reportar una novedad del salón.
/// [onEnviar] devuelve un mensaje de error o null si todo salió bien (la hoja se cierra sola).
Future<bool?> mostrarReporteSalonSheet(
  BuildContext context, {
  required String salon,
  required Future<String?> Function(TipoReporteSalon tipo, String descripcion) onEnviar,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _ReporteSalonSheet(salon: salon, onEnviar: onEnviar),
  );
}

class _ReporteSalonSheet extends StatefulWidget {
  const _ReporteSalonSheet({required this.salon, required this.onEnviar});

  final String salon;
  final Future<String?> Function(TipoReporteSalon tipo, String descripcion) onEnviar;

  @override
  State<_ReporteSalonSheet> createState() => _ReporteSalonSheetState();
}

class _ReporteSalonSheetState extends State<_ReporteSalonSheet> {
  final _descripcion = TextEditingController();
  TipoReporteSalon _tipo = TipoReporteSalon.equipo;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _descripcion.text.trim();
    if (texto.length < 3) {
      setState(() => _error = 'Cuéntanos qué pasó (mínimo 3 caracteres).');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await widget.onEnviar(_tipo, texto);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _enviando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AsaHoja(),
              Text(
                'Reportar novedad',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Salón ${widget.salon}',
                style: const TextStyle(color: AppColors.textoSuave),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in TipoReporteSalon.values)
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        iconoDeTipoReporte(t),
                        size: 18,
                        color: _tipo == t ? Colors.black : AppColors.texto,
                      ),
                      label: Text(t.etiqueta),
                      selected: _tipo == t,
                      onSelected: _enviando ? null : (_) => setState(() => _tipo = t),
                      selectedColor: AppColors.texto,
                      backgroundColor: AppColors.superficieAlta,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _tipo == t ? Colors.black : AppColors.texto,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descripcion,
                enabled: !_enviando,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '¿Qué pasó?',
                  hintText: 'Ej. El video beam no enciende',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: AppColors.danado)),
              ],
              const SizedBox(height: 14),
              BotonPildora(
                texto: 'Enviar reporte',
                icono: Icons.flag_rounded,
                cargando: _enviando,
                onPressed: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import 'mantenimiento_controller.dart';
import 'recurso_detalle_page.dart';
import 'recursos_controller.dart';

class MantenimientoPage extends StatefulWidget {
  const MantenimientoPage({super.key});

  @override
  State<MantenimientoPage> createState() => _MantenimientoPageState();
}

class _MantenimientoPageState extends State<MantenimientoPage> {
  final RecursosController _recursos = sl<RecursosController>();
  final MantenimientoController _mantenimiento = sl<MantenimientoController>();

  @override
  void initState() {
    super.initState();
    _recursos.cargar(silencioso: true);
    _mantenimiento.cargar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mantenimiento')),
        body: ListenableBuilder(
          listenable: Listenable.merge([_recursos, _mantenimiento]),
          builder: (context, _) {
            final recursos = {for (final r in _recursos.todos) r.id: r};
            final items = _mantenimiento.items;
            if ((_recursos.carga == Carga.cargando ||
                    _mantenimiento.cargando) &&
                items.isEmpty) {
              return const VistaCargando();
            }
            if (_mantenimiento.error != null && items.isEmpty) {
              return VistaError(
                mensaje: _mantenimiento.error!,
                onReintentar: _mantenimiento.cargar,
              );
            }
            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: AppColors.texto,
              onRefresh: () async {
                await Future.wait([
                  _recursos.cargar(silencioso: true),
                  _mantenimiento.cargar(),
                ]);
              },
              child: items.isEmpty
                  ? ListView(children: const [
                      SizedBox(
                        height: 300,
                        child: VistaVacia(
                          mensaje: 'Sin equipos pendientes',
                          detalle:
                              'Los reportes de daño y mantenimiento aparecerán aquí.',
                        ),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final orden = items[index];
                        final recurso = recursos[orden.recursoId];
                        return TarjetaBorde(
                          onTap: recurso == null
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecursoDetallePage(recurso: recurso),
                                    ),
                                  ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.build_outlined,
                                color: AppColors.mantenimiento,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        recurso?.titulo ??
                                            'Recurso #${orden.recursoId}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text('Estado: ${orden.estado}',
                                        style: const TextStyle(
                                            color: AppColors.textoSuave)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (estado) async {
                                  final error = await _mantenimiento.actualizar(
                                      orden.id, estado);
                                  if (error != null && context.mounted) {
                                    mostrarMensaje(context, error);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'en_proceso',
                                    child: Text('En proceso'),
                                  ),
                                  PopupMenuItem(
                                    value: 'completado',
                                    child: Text('Completar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      );
}

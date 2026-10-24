import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/recurso.dart';
import 'crear_recurso_page.dart';
import 'filtros_sheet.dart';
import 'recurso_detalle_page.dart';
import 'recursos_controller.dart';

/// Catálogo de equipos con búsqueda y filtros (pestaña "Equipos").
class EquiposPage extends StatefulWidget {
  const EquiposPage({super.key});

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final RecursosController _recursos = sl<RecursosController>();
  final AuthController _auth = sl<AuthController>();
  final TextEditingController _buscar = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recursos.addListener(_sincronizarBuscador);
  }

  @override
  void dispose() {
    _recursos.removeListener(_sincronizarBuscador);
    _buscar.dispose();
    super.dispose();
  }

  /// Si otro lado (el inicio) fija la búsqueda, el campo de texto la refleja.
  void _sincronizarBuscador() {
    if (_buscar.text.trim() != _recursos.busqueda) {
      _buscar.text = _recursos.busqueda;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_recursos, _auth]),
        builder: (context, _) {
          final lista = _recursos.filtrados;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Equipos',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    ),
                    if (_auth.esAdministrador)
                      IconButton.filledTonal(
                        tooltip: 'Registrar equipo',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const CrearRecursoPage()),
                        ),
                        icon: const Icon(Icons.add),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  controller: _buscar,
                  onChanged: _recursos.fijarBusqueda,
                  decoration: InputDecoration(
                    hintText: 'Serial, salón o categoría',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Filtros',
                      icon: Icon(
                        Icons.tune_rounded,
                        color: (_recursos.categoria != null ||
                                _recursos.estado != null ||
                                _recursos.salon != null)
                            ? AppColors.disponible
                            : null,
                      ),
                      onPressed: () => mostrarFiltros(context, _recursos),
                    ),
                  ),
                ),
              ),
              _ChipsActivos(recursos: _recursos),
              Expanded(child: _cuerpo(lista)),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo(List<Recurso> lista) {
    switch (_recursos.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
          mensaje: _recursos.error ?? 'No pudimos cargar los equipos.',
          onReintentar: _recursos.cargar,
        );
      case Carga.ok:
        if (lista.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _recursos.cargar(silencioso: true),
            child: ListView(
              children: [
                SizedBox(
                  height: 320,
                  child: VistaVacia(
                    mensaje: _recursos.hayFiltros
                        ? 'Ningún equipo coincide'
                        : 'Todavía no hay equipos',
                    detalle: _recursos.hayFiltros
                        ? 'Prueba quitando algún filtro.'
                        : _auth.esAdministrador
                            ? 'Registra el primero con el botón +.'
                            : 'Un auxiliar debe registrarlos primero.',
                  ),
                ),
                if (_recursos.hayFiltros)
                  Center(
                    child: TextButton(
                      onPressed: _recursos.limpiarFiltros,
                      child: const Text('Quitar filtros'),
                    ),
                  ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: Colors.black,
          backgroundColor: AppColors.texto,
          onRefresh: () => _recursos.cargar(silencioso: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _FilaRecurso(
              recurso: lista[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecursoDetallePage(recurso: lista[i]),
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _ChipsActivos extends StatelessWidget {
  const _ChipsActivos({required this.recursos});
  final RecursosController recursos;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (recursos.categoria != null)
        InputChip(
          label: Text(recursos.categoria!.etiqueta),
          onDeleted: () => recursos.fijarCategoria(null),
        ),
      if (recursos.estado != null)
        InputChip(
          label: Text(recursos.estado!.etiqueta),
          onDeleted: () => recursos.fijarEstado(null),
        ),
      if (recursos.salon != null)
        InputChip(
          label: Text('Salón ${recursos.salon}'),
          onDeleted: () => recursos.fijarSalon(null),
        ),
    ];
    if (chips.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _FilaRecurso extends StatelessWidget {
  const _FilaRecurso({required this.recurso, required this.onTap});
  final Recurso recurso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaBorde(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FiguraCircular(figura: recurso.categoria.figura, tamano: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recurso.categoria.etiqueta,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${recurso.serial} · Salón ${recurso.salonId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Insignia(texto: recurso.estado.etiqueta, color: colorDeEstado(recurso.estado)),
        ],
      ),
    );
  }
}

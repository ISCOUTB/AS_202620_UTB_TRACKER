import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/recurso.dart';
import 'crear_recurso_page.dart';
import 'filtros_sheet.dart';
import 'recurso_detalle_page.dart';
import 'recursos_controller.dart';

/// Inventario de equipos fijos, agrupado por salón. Los equipos no se prestan (ADR-0010):
/// aquí solo se controla su estado.
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
    if (_recursos.carga == Carga.inicial) _recursos.cargar();
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

  void _filtrarEstado(EstadoRecurso e) =>
      _recursos.fijarEstado(_recursos.estado == e ? null : e);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([_recursos, _auth]),
        builder: (context, _) => RefreshIndicator(
          onRefresh: () => _recursos.cargar(silencioso: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _encabezado(context)),
              SliverToBoxAdapter(child: _ChipsActivos(recursos: _recursos)),
              ..._cuerpo(),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context) {
    final todos = _recursos.todos;
    int cuenta(EstadoRecurso e) => todos.where((r) => r.estado == e).length;
    return EncabezadoDegradado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.of(context).canPop())
                      const BackButton(),
                    const Text('Inventario',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                    Text(
                      '${todos.length} equipos fijos en ${_recursos.salones.length} salones',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
                    ),
                  ],
                ),
              ),
              if (_auth.esAdministrador)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                  ),
                  tooltip: 'Registrar equipo',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CrearRecursoPage()),
                  ),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Indicador(
                valor: '${cuenta(EstadoRecurso.disponible)}',
                etiqueta: 'Funcionando',
                color: AppColors.disponible,
                onTap: () => _filtrarEstado(EstadoRecurso.disponible),
              ),
              const SizedBox(width: 10),
              Indicador(
                valor: '${cuenta(EstadoRecurso.danado)}',
                etiqueta: 'Dañados',
                color: AppColors.danado,
                onTap: () => _filtrarEstado(EstadoRecurso.danado),
              ),
              const SizedBox(width: 10),
              Indicador(
                valor: '${cuenta(EstadoRecurso.mantenimiento)}',
                etiqueta: 'Mantenimiento',
                color: AppColors.mantenimiento,
                onTap: () => _filtrarEstado(EstadoRecurso.mantenimiento),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _buscar,
            onChanged: _recursos.fijarBusqueda,
            decoration: InputDecoration(
              hintText: 'Serial, salón o edificio',
              fillColor: const Color(0x33000000),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Filtros',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => mostrarFiltros(context, _recursos),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cuerpo() {
    switch (_recursos.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const [SliverToBoxAdapter(child: VistaCargando())];
      case Carga.error:
        return [
          SliverToBoxAdapter(
            child: VistaError(
              mensaje: _recursos.error ?? 'No pudimos cargar los equipos.',
              onReintentar: _recursos.cargar,
            ),
          ),
        ];
      case Carga.ok:
        final grupos = _recursos.porSalon;
        if (grupos.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  VistaVacia(
                    mensaje: _recursos.hayFiltros
                        ? 'Ningún equipo coincide'
                        : 'Todavía no hay equipos',
                    detalle: _recursos.hayFiltros ? 'Prueba quitando algún filtro.' : null,
                  ),
                  if (_recursos.hayFiltros)
                    TextButton(
                      onPressed: _recursos.limpiarFiltros,
                      child: const Text('Quitar filtros'),
                    ),
                ],
              ),
            ),
          ];
        }
        var orden = 0;
        return [
          for (final g in grupos.entries)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
                children: [
                  Aparecer(orden: orden++, child: _CabeceraSalon(codigo: g.key, equipos: g.value)),
                  const SizedBox(height: 10),
                  for (final r in g.value) ...[
                    Aparecer(
                      orden: orden++,
                      child: _FilaRecurso(
                        recurso: r,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => RecursoDetallePage(recurso: r)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ];
    }
  }
}

class _CabeceraSalon extends StatelessWidget {
  const _CabeceraSalon({required this.codigo, required this.equipos});
  final String codigo;
  final List<Recurso> equipos;

  @override
  Widget build(BuildContext context) {
    final conNovedad = equipos.where((r) => !r.disponible).length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.degradado,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(codigo,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            equipos.first.edificioTexto ?? '',
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 14),
          ),
        ),
        Text(
          conNovedad == 0
              ? '${equipos.length} equipos'
              : '$conNovedad con novedad',
          style: TextStyle(
            color: conNovedad == 0 ? AppColors.textoTenue : AppColors.danado,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
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
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
          Hero(
            tag: 'recurso-${recurso.id}',
            child: FiguraCircular(figura: recurso.categoria.figura, tamano: 56),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recurso.categoria.etiqueta,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  recurso.serial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5),
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

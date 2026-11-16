import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../../salones/domain/entities/salon.dart';
import '../../salones/presentation/salones_controller.dart';
import '../domain/catalogo.dart';

/// CATÁLOGO DE SALONES (solo Administrador, ADR-0021): crear uno con validación en vivo, crear
/// varios por rango con vista previa, ver los que no siguen la regla y desactivar (nunca borrar).
class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key, this.repo, this.salones});
  final CatalogoRepository? repo;
  final SalonesController? salones;

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  late final CatalogoRepository _repo = widget.repo ?? sl<CatalogoRepository>();
  late final SalonesController _salones = widget.salones ?? sl<SalonesController>();

  List<SalonFueraCatalogo> _fuera = const [];
  String? _errorFuera;
  String? _edificio;
  int? _piso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recargar();
    });
  }

  Future<void> _recargar() async {
    await _salones.cargar(silencioso: _salones.todos.isNotEmpty);
    try {
      final fuera = await _repo.fueraDelCatalogo();
      if (mounted) setState(() { _fuera = fuera; _errorFuera = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorFuera = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _errorFuera = 'No se pudo revisar el catálogo.');
    }
  }

  Future<void> _abrir(Widget hoja) async {
    final mensaje = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => hoja,
    );
    if (mensaje != null && mounted) {
      mostrarMensaje(context, mensaje);
      _recargar();
    }
  }

  Future<void> _desactivar(Salon s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Desactivar ${s.nombre}?'),
        content: const Text(
            'Deja de aparecer en la app y no se puede solicitar. No se borra: su historial de '
            'clases y solicitudes se conserva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danado),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.desactivar(s.id);
      if (mounted) mostrarMensaje(context, '${s.nombre} desactivado');
      _recargar();
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConPermiso(
        permiso: Permisos.salonesCrearCatalogo,
        child: ListenableBuilder(
          listenable: _salones,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                EncabezadoDegradado(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('Catálogo de salones',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 0, 12),
                        child: Text(
                          'Código A1-101 = edificio A1, piso 1, salón 01. Lista provisional: '
                          'pendiente de confirmar con Planta Física.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _abrir(const _HojaCrearUno()),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Crear uno'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _abrir(_HojaCrearVarios(repo: _repo)),
                              icon: const Icon(Icons.playlist_add_rounded),
                              label: const Text('Crear varios'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _cuerpo()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    switch (_salones.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
            mensaje: _salones.error ?? 'No se pudieron cargar los salones.',
            onReintentar: _recargar);
      case Carga.ok:
        break;
    }
    final todos = [..._salones.todos]..sort((a, b) => compararCodigos(a.nombre, b.nombre));
    final edificios = {for (final s in todos) if (s.edificio != null) s.edificio!}.toList()
      ..sort();
    final pisos = {
      for (final s in todos)
        if (s.piso != null && (_edificio == null || s.edificio == _edificio)) s.piso!
    }.toList()
      ..sort();
    final lista = todos
        .where((s) => _edificio == null || s.edificio == _edificio)
        .where((s) => _piso == null || s.piso == _piso)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorFuera != null)
          Text(_errorFuera!, style: const TextStyle(color: AppColors.danado))
        else if (_fuera.isNotEmpty)
          _TarjetaFuera(fuera: _fuera),
        const SizedBox(height: 8),
        FiltroEdificioPiso(
          edificios: edificios,
          pisos: pisos,
          edificio: _edificio,
          piso: _piso,
          onEdificio: (e) => setState(() { _edificio = e; _piso = null; }),
          onPiso: (p) => setState(() => _piso = p),
        ),
        const SizedBox(height: 8),
        Text('${lista.length} salones', style: const TextStyle(color: AppColors.textoSuave)),
        const SizedBox(height: 8),
        if (lista.isEmpty)
          const VistaVacia(
            mensaje: 'Todavía no hay salones aquí',
            detalle: 'Usa "Crear varios" para cargar un piso completo.',
          )
        else
          for (final s in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TarjetaBorde(
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nombre,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            '${s.tipo.etiqueta} · ${s.capacidad} puestos'
                            '${s.capacidadEstimada ? ' (estimado)' : ''}',
                            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Desactivar ${s.nombre}',
                      icon: const Icon(Icons.block_rounded, color: AppColors.textoSuave),
                      onPressed: () => _desactivar(s),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// Chips de edificio y, si hay uno elegido, de piso. Se usa en el catálogo, en el panel del
/// auditor y en la pantalla del estudiante (mismos filtros en todas).
class FiltroEdificioPiso extends StatelessWidget {
  const FiltroEdificioPiso({
    super.key,
    required this.edificios,
    required this.pisos,
    required this.edificio,
    required this.piso,
    required this.onEdificio,
    required this.onPiso,
  });

  final List<String> edificios;
  final List<int> pisos;
  final String? edificio;
  final int? piso;
  final ValueChanged<String?> onEdificio;
  final ValueChanged<int?> onPiso;

  Widget _chip(String texto, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          showCheckmark: false,
          label: Text(texto),
          selected: sel,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primario,
          backgroundColor: AppColors.superficieAlta,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (edificios.length < 2 && pisos.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (edificios.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('Todos', edificio == null, () => onEdificio(null)),
              for (final e in edificios) _chip(e, edificio == e, () => onEdificio(e)),
            ]),
          ),
        if (edificio != null && pisos.length > 1) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('Todos los pisos', piso == null, () => onPiso(null)),
              for (final p in pisos) _chip('Piso $p', piso == p, () => onPiso(p)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _TarjetaFuera extends StatelessWidget {
  const _TarjetaFuera({required this.fuera});
  final List<SalonFueraCatalogo> fuera;

  @override
  Widget build(BuildContext context) {
    return TarjetaBorde(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.rule_rounded, color: AppColors.prestado),
        title: Text('${fuera.length} fuera del catálogo',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('No siguen la regla o no están en la lista. Nada se borra solo.',
            style: TextStyle(fontSize: 12.5)),
        children: [
          for (final f in fuera)
            ListTile(
              dense: true,
              title: Text(f.nombre + (f.tieneHistorial ? ' · tiene historial' : ''),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${f.problema}\nPropuesta: ${f.propuesta}'),
            ),
        ],
      ),
    );
  }
}

// ─── Crear uno (validación en vivo) ─────────────────────────────────────────

class _HojaCrearUno extends StatefulWidget {
  const _HojaCrearUno();

  @override
  State<_HojaCrearUno> createState() => _HojaCrearUnoState();
}

class _HojaCrearUnoState extends State<_HojaCrearUno> {
  final _codigo = TextEditingController();
  final _capacidad = TextEditingController();
  TipoSalon _tipo = TipoSalon.aula;
  bool _enviando = false;
  String? _errorServidor;

  @override
  void dispose() {
    _codigo.dispose();
    _capacidad.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final p = partesCodigo(_codigo.text);
    if (p == null || errorCodigo(_codigo.text) != null) return;
    final capacidad = int.tryParse(_capacidad.text.trim());
    setState(() { _enviando = true; _errorServidor = null; });
    final error = await sl<SalonesController>().crear(
      nombre: normalizarCodigo(_codigo.text),
      ubicacion: ubicacionDe(p.edificio, p.piso),
      edificio: p.edificio,
      piso: p.piso,
      capacidad: capacidad ?? 40,
      tipo: _tipo,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, '${normalizarCodigo(_codigo.text)} creado');
    } else {
      setState(() { _enviando = false; _errorServidor = error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = _codigo.text;
    final error = texto.isEmpty ? null : errorCodigo(texto);
    final partes = error == null ? partesCodigo(texto) : null;
    final capacidad = int.tryParse(_capacidad.text.trim());
    final capacidadMala = _capacidad.text.trim().isNotEmpty && (capacidad == null || capacidad < 1);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Crear un salón',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _codigo,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() => _errorServidor = null),
              decoration: InputDecoration(
                labelText: 'Código',
                hintText: 'A1-101',
                errorText: error,
                helperMaxLines: 2,
                errorMaxLines: 3,
                helperText: partes == null
                    ? 'A + edificio + guion + piso + salón'
                    : 'Edificio ${partes.edificio}, piso ${partes.piso}, salón '
                        '${partes.numero.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _capacidad,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Capacidad (opcional)',
                hintText: '40',
                errorText: capacidadMala ? 'Escribe un número mayor que 0' : null,
                helperText: 'Si no la sabes, queda 40.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoSalon>(
              initialValue: _tipo,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in TipoSalon.values)
                  DropdownMenuItem(value: t, child: Text(t.etiqueta)),
              ],
              onChanged: (t) => setState(() => _tipo = t ?? TipoSalon.aula),
            ),
            if (_errorServidor != null) ...[
              const SizedBox(height: 10),
              Text(_errorServidor!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: partes == null || capacidadMala || _enviando ? null : _crear,
              child: Text(_enviando ? 'Creando...' : 'Crear salón'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Crear varios por rango (vista previa + confirmación) ───────────────────

class _HojaCrearVarios extends StatefulWidget {
  const _HojaCrearVarios({required this.repo});
  final CatalogoRepository repo;

  @override
  State<_HojaCrearVarios> createState() => _HojaCrearVariosState();
}

class _HojaCrearVariosState extends State<_HojaCrearVarios> {
  int _edificio = 1;
  int _piso = 1;
  int _desde = 1;
  int _hasta = 5;
  VistaPreviaRango? _previa;
  bool _cargando = false;
  String? _error;

  void _cambio(VoidCallback f) => setState(() {
        f();
        _previa = null;
        _error = null;
      });

  Future<void> _verPrevia() async {
    setState(() => _cargando = true);
    try {
      final p = await widget.repo.vistaPrevia(_edificio, _piso, _desde, _hasta);
      if (mounted) setState(() { _previa = p; _cargando = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.mensaje; _cargando = false; });
    }
  }

  Future<void> _crear() async {
    setState(() => _cargando = true);
    try {
      final r = await widget.repo.crearRango(_edificio, _piso, _desde, _hasta);
      if (mounted) Navigator.pop(context, '${r.creados.length} salones creados');
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.mensaje; _cargando = false; });
    }
  }

  Widget _selector(String titulo, int valor, int min, int max, ValueChanged<int> cambiar) =>
      Expanded(
        child: DropdownButtonFormField<int>(
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(labelText: titulo, isDense: true),
          items: [
            for (var i = min; i <= max; i++)
              DropdownMenuItem(value: i, child: Text(i.toString().padLeft(titulo == 'Edificio' || titulo == 'Piso' ? 1 : 2, '0'))),
          ],
          onChanged: (v) => _cambio(() => cambiar(v ?? valor)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final rangoMalo = _desde > _hasta;
    final codigos = rangoMalo ? const <String>[] : codigosDeRango(_edificio, _piso, _desde, _hasta);
    final previa = _previa;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Crear varios salones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Los que ya existen no se tocan.',
                style: TextStyle(color: AppColors.textoSuave)),
            const SizedBox(height: 12),
            Row(children: [
              _selector('Edificio', _edificio, 1, 9, (v) => _edificio = v),
              const SizedBox(width: 8),
              _selector('Piso', _piso, 1, 9, (v) => _piso = v),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _selector('Desde', _desde, 1, 30, (v) => _desde = v),
              const SizedBox(width: 8),
              _selector('Hasta', _hasta, 1, 30, (v) => _hasta = v),
            ]),
            const SizedBox(height: 10),
            Text(
              rangoMalo
                  ? '"Desde" debe ser menor o igual que "Hasta".'
                  : '${codigos.first} a ${codigos.last} (${codigos.length})',
              style: TextStyle(color: rangoMalo ? AppColors.danado : AppColors.textoSuave),
            ),
            if (previa != null) ...[
              const SizedBox(height: 12),
              TarjetaBorde(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Se crearán ${previa.nuevos.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (previa.nuevos.isNotEmpty) Text(previa.nuevos.join(', ')),
                    if (previa.existentes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Ya existen (no se tocan): ${previa.existentes.join(', ')}',
                          style: const TextStyle(color: AppColors.textoSuave)),
                    ],
                    const SizedBox(height: 6),
                    Text('${previa.edificio}, piso ${previa.piso} · capacidad 40 (estimada)',
                        style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 16),
            if (previa == null)
              FilledButton(
                onPressed: rangoMalo || _cargando ? null : _verPrevia,
                child: Text(_cargando ? 'Revisando...' : 'Ver vista previa'),
              )
            else
              FilledButton(
                onPressed: previa.nuevos.isEmpty || _cargando ? null : _crear,
                child: Text(_cargando
                    ? 'Creando...'
                    : previa.nuevos.isEmpty
                        ? 'No hay nada que crear'
                        : 'Confirmar: crear ${previa.nuevos.length}'),
              ),
          ],
        ),
      ),
    );
  }
}

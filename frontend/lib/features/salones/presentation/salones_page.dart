import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/salon.dart';
import 'salon_detalle_page.dart';
import 'salones_controller.dart';

class SalonesPage extends StatefulWidget {
  const SalonesPage({super.key});

  @override
  State<SalonesPage> createState() => _SalonesPageState();
}

class _SalonesPageState extends State<SalonesPage> {
  final SalonesController _salones = sl<SalonesController>();
  final AuthController _auth = sl<AuthController>();
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _salones.cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _abrirCrearSalon() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CrearSalonSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salones y Aulas'),
        actions: [
          if (_auth.esAdministrador)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Registrar salón',
              onPressed: _abrirCrearSalon,
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _salones,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _busquedaCtrl,
                  onChanged: _salones.fijarBusqueda,
                  decoration: InputDecoration(
                    hintText: 'Buscar salón, edificio o aula...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _busquedaCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _busquedaCtrl.clear();
                              _salones.fijarBusqueda('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: _construirCuerpo(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirCuerpo() {
    switch (_salones.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
          mensaje: _salones.error ?? 'No pudimos cargar los salones.',
          onReintentar: _salones.cargar,
        );
      case Carga.ok:
        final lista = _salones.filtrados;
        if (lista.isEmpty) {
          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: AppColors.texto,
            onRefresh: () => _salones.cargar(silencioso: true),
            child: ListView(
              children: const [
                SizedBox(
                  height: 300,
                  child: VistaVacia(
                    mensaje: 'No hay salones que coincidan',
                    detalle: 'Intenta con otro término o crea un nuevo salón.',
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: Colors.black,
          backgroundColor: AppColors.texto,
          onRefresh: () => _salones.cargar(silencioso: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = lista[i];
              return _FilaSalon(salon: s);
            },
          ),
        );
    }
  }
}

class _FilaSalon extends StatelessWidget {
  const _FilaSalon({required this.salon});
  final Salon salon;

  @override
  Widget build(BuildContext context) {
    final disponible = salon.disponible;
    return TarjetaBorde(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SalonDetallePage(salon: salon),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.superficieAlta,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: AppColors.texto,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.nombre,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  salon.detalleUbicacion,
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  'Capacidad: ${salon.capacidad} personas',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Insignia(
            texto: salon.estado.toUpperCase(),
            color: disponible ? AppColors.disponible : AppColors.danado,
          ),
        ],
      ),
    );
  }
}

class _CrearSalonSheet extends StatefulWidget {
  const _CrearSalonSheet();

  @override
  State<_CrearSalonSheet> createState() => _CrearSalonSheetState();
}

class _CrearSalonSheetState extends State<_CrearSalonSheet> {
  final SalonesController _salones = sl<SalonesController>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _ubicacionCtrl = TextEditingController();
  final TextEditingController _edificioCtrl = TextEditingController();
  final TextEditingController _pisoCtrl = TextEditingController();
  final TextEditingController _capacidadCtrl = TextEditingController(text: '30');

  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _edificioCtrl.dispose();
    _pisoCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final capacidad = int.tryParse(_capacidadCtrl.text.trim()) ?? 0;

    if (nombre.isEmpty || ubicacion.isEmpty || capacidad <= 0) {
      mostrarMensaje(context, 'Completa los campos obligatorios');
      return;
    }

    setState(() => _enviando = true);
    final error = await _salones.crear(
      nombre: nombre,
      ubicacion: ubicacion,
      edificio: _edificioCtrl.text.trim(),
      piso: int.tryParse(_pisoCtrl.text.trim()),
      capacidad: capacidad,
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    if (error != null) {
      mostrarMensaje(context, error);
    } else {
      Navigator.of(context).pop();
      mostrarMensaje(context, 'Salón creado exitosamente');
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
              const Text(
                'Nuevo Salón / Aula',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del salón *',
              hintText: 'Ej. A-301, Lab Sistemas 1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ubicacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Ubicación *',
              hintText: 'Ej. Edificio A, Piso 3',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _edificioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Edificio (opc.)',
                    hintText: 'Ej. A, B, C',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pisoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Piso (opc.)',
                    hintText: 'Ej. 3',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacidad de personas *',
              hintText: 'Ej. 35',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enviando ? null : _guardar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Registrar salón'),
          ),
        ],
      ),
    );
  }
}

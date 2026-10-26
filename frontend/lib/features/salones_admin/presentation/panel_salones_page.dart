import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/entities/ocupacion.dart';
import 'plano_salones.dart';
import 'salon_control_page.dart';
import 'salones_admin_controller.dart';
import 'salones_admin_estilos.dart';

/// Pantalla principal del auxiliar: el plano del campus arriba y, abajo, una hoja que se
/// arrastra con la lista de salones (la misma idea que el mapa y la hoja de viajes de Uber).
class PanelSalonesPage extends StatefulWidget {
  const PanelSalonesPage({super.key});

  @override
  State<PanelSalonesPage> createState() => _PanelSalonesPageState();
}

class _PanelSalonesPageState extends State<PanelSalonesPage> {
  final SalonesAdminController _c = sl<SalonesAdminController>();
  final AuthController _auth = sl<AuthController>();
  Timer? _refresco;
  DateTime? _actualizado;

  @override
  void initState() {
    super.initState();
    _cargar();
    // El estado de un salón cambia durante el día: se refresca solo cada medio minuto.
    _refresco = Timer.periodic(const Duration(seconds: 30), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _refresco?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    await _c.cargar(silencioso: silencioso);
    if (mounted && _c.carga == Carga.ok) setState(() => _actualizado = DateTime.now());
  }

  Future<void> _abrir(OcupacionSalon o) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => SalonControlPage(salonId: o.salon.id)),
    );
    _cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecera(
                nombre: _auth.usuario?.nombre ?? '',
                actualizado: _actualizado,
                onBuscar: _c.fijarBusqueda,
                onRefrescar: () => _cargar(),
              ),
              _Filtros(controller: _c),
              const SizedBox(height: 8),
              Expanded(child: _cuerpo()),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo() {
    if (_c.carga == Carga.cargando && _c.todos.isEmpty) return const VistaCargando();
    if (_c.carga == Carga.error && _c.todos.isEmpty) {
      return VistaError(mensaje: _c.error ?? 'Error', onReintentar: _cargar);
    }
    final visibles = _c.visibles;
    return LayoutBuilder(
      builder: (context, caja) {
        return Stack(
          children: [
            Positioned.fill(
              bottom: caja.maxHeight * 0.38,
              child: PlanoSalones(salones: visibles, onTap: _abrir),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.46,
              minChildSize: 0.22,
              maxChildSize: 0.96,
              snap: true,
              snapSizes: const [0.46],
              builder: (context, scroll) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                    border: Border(top: BorderSide(color: AppColors.borde)),
                  ),
                  child: RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: AppColors.texto,
                    onRefresh: () => _cargar(silencioso: true),
                    child: ListView(
                      controller: scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: [
                        const AsaHoja(),
                        _Resumen(controller: _c),
                        const SizedBox(height: 14),
                        if (visibles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: VistaVacia(
                              mensaje: 'Ningún salón coincide',
                              detalle: 'Prueba con otro filtro o búsqueda.',
                            ),
                          )
                        else
                          for (final o in visibles)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TarjetaSalonAdmin(ocupacion: o, onTap: () => _abrir(o)),
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.actualizado,
    required this.onBuscar,
    required this.onRefrescar,
  });

  final String nombre;
  final DateTime? actualizado;
  final ValueChanged<String> onBuscar;
  final VoidCallback onRefrescar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre.isEmpty ? 'Salones' : 'Hola, ${nombre.split(' ').first}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actualizado == null
                          ? 'Estado de los salones en vivo'
                          : 'Actualizado ${formatearHora(actualizado!)}',
                      style: const TextStyle(color: AppColors.textoSuave),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Actualizar',
                onPressed: onRefrescar,
                style: IconButton.styleFrom(backgroundColor: AppColors.superficieAlta),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onBuscar,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Salón, profesor o usuario',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.superficieAlta,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppColors.texto, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.controller});
  final SalonesAdminController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final f in FiltroPanel.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text('${f.etiqueta} · ${controller.contar(f)}'),
                selected: controller.filtro == f,
                onSelected: (_) => controller.fijarFiltro(f),
                selectedColor: AppColors.texto,
                backgroundColor: AppColors.superficieAlta,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: controller.filtro == f ? Colors.black : AppColors.texto,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.controller});
  final SalonesAdminController controller;

  @override
  Widget build(BuildContext context) {
    final pendientes = controller.totalPendientes;
    final reportes = controller.totalReportes;
    final sinConfirmar = controller.todos
        .where((o) => o.situacion == SituacionSalon.claseSinConfirmar)
        .length;

    final avisos = <String>[
      if (sinConfirmar > 0) '$sinConfirmar profesor${sinConfirmar == 1 ? '' : 'es'} sin confirmar',
      if (pendientes > 0) '$pendientes solicitud${pendientes == 1 ? '' : 'es'} pendiente${pendientes == 1 ? '' : 's'}',
      if (reportes > 0) '$reportes reporte${reportes == 1 ? '' : 's'} abierto${reportes == 1 ? '' : 's'}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          avisos.isEmpty ? 'Todo en orden' : 'Por atender',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          avisos.isEmpty ? 'No hay nada pendiente en los salones.' : avisos.join(' · '),
          style: const TextStyle(color: AppColors.textoSuave),
        ),
      ],
    );
  }
}

/// Tarjeta de un salón en la lista: quién lo tiene y qué requiere atención.
class TarjetaSalonAdmin extends StatelessWidget {
  const TarjetaSalonAdmin({super.key, required this.ocupacion, required this.onTap});

  final OcupacionSalon ocupacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = ocupacion.situacion;
    final color = colorDeSituacion(s);
    final nombrePersona = switch (ocupacion.ocupante) {
      Ocupante.clase => ocupacion.clase?.profesor,
      Ocupante.prestamo => ocupacion.prestamo?.usuarioNombre,
      Ocupante.libre => null,
    };

    return TarjetaBorde(
      onTap: onTap,
      child: Row(
        children: [
          nombrePersona != null && nombrePersona.isNotEmpty
              ? AvatarIniciales(nombre: nombrePersona, color: color)
              : Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: color),
                  ),
                  child: Icon(
                    s == SituacionSalon.libre ? Icons.check_rounded : Icons.block_rounded,
                    color: color,
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ocupacion.salon.nombre,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Insignia(texto: etiquetaDeSituacion(s), color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ocupacion.titular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  ocupacion.subtitular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                ),
                if (ocupacion.solicitudesPendientes > 0 || ocupacion.reportesAbiertos > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (ocupacion.solicitudesPendientes > 0)
                        _Aviso(
                          icono: Icons.inbox_rounded,
                          texto: '${ocupacion.solicitudesPendientes} solicitud(es)',
                        ),
                      if (ocupacion.reportesAbiertos > 0)
                        _Aviso(
                          icono: Icons.flag_rounded,
                          texto: '${ocupacion.reportesAbiertos} reporte(s)',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textoTenue),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: AppColors.prestado),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12.5, color: AppColors.prestado)),
      ],
    );
  }
}

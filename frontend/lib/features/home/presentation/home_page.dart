import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/assets/figuras.dart';
import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../prestamos/domain/entities/prestamo.dart';
import '../../prestamos/presentation/prestamos_controller.dart';
import '../../recursos/domain/entities/recurso.dart';
import '../../recursos/presentation/filtros_sheet.dart';
import '../../recursos/presentation/recurso_detalle_page.dart';
import '../../recursos/presentation/recursos_controller.dart';

typedef VerEquipos = void Function({
  CategoriaRecurso? categoria,
  EstadoRecurso? estado,
  String? busqueda,
});

/// Pantalla de inicio: selector de salón, pestañas, buscador, tarjeta "Reciente",
/// accesos rápidos por categoría ("Para ti") y carrusel de atajos.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onVerEquipos,
    required this.onIrAEquipos,
    required this.onVerActividad,
  });

  /// Va a Equipos aplicando (y reemplazando) filtros.
  final VerEquipos onVerEquipos;

  /// Va a Equipos sin tocar los filtros que ya dejó el controlador.
  final VoidCallback onIrAEquipos;
  final void Function({int filtro}) onVerActividad;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RecursosController _recursos = sl<RecursosController>();
  final PrestamosController _prestamos = sl<PrestamosController>();
  final AuthController _auth = sl<AuthController>();
  final TextEditingController _buscar = TextEditingController();

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _refrescar() async {
    await Future.wait([_recursos.cargar(silencioso: true), _prestamos.cargar(silencioso: true)]);
  }

  /// Préstamos que le importan a quien mira: el auxiliar ve todos; el usuario, solo los suyos.
  List<Prestamo> _alcance() {
    final u = _auth.usuario;
    if (u == null) return const [];
    return u.esAdministrador ? _prestamos.todos : _prestamos.deUsuario(u.id);
  }

  Future<void> _elegirSalon() async {
    final elegido = await mostrarSelectorSalon(
      context,
      salones: _recursos.salones,
      actual: _recursos.salon,
    );
    if (elegido == null) return; // cerró sin elegir
    _recursos.fijarSalon(elegido == kTodosLosSalones ? null : elegido);
    widget.onIrAEquipos();
  }

  Future<void> _abrirFiltros() async {
    // mostrarFiltros deja los filtros elegidos en el controlador y devuelve true si se aplicaron.
    final aplicado = await mostrarFiltros(context, _recursos);
    if (aplicado == true) widget.onIrAEquipos();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_recursos, _prestamos, _auth]),
        builder: (context, _) {
          final vencidos = _prestamos.vencidos(_alcance());
          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: AppColors.texto,
            onRefresh: _refrescar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
              children: [
                _Cabecera(
                  salon: _recursos.salon,
                  vencidos: vencidos,
                  onSalon: _elegirSalon,
                  onAvisos: () => widget.onVerActividad(filtro: 1),
                ),
                const SizedBox(height: 14),
                _Pestanas(onPrestamos: () => widget.onVerActividad()),
                const Divider(height: 1),
                const SizedBox(height: 22),
                _Buscador(
                  controlador: _buscar,
                  onEnviar: (t) => widget.onVerEquipos(busqueda: t),
                  onFiltros: _abrirFiltros,
                ),
                const SizedBox(height: 14),
                _TarjetaReciente(
                  recursos: _recursos,
                  onAbrir: (r) => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => RecursoDetallePage(recurso: r)),
                  ),
                ),
                const SizedBox(height: 26),
                SeccionTitulo('Para ti', accion: () => widget.onVerEquipos()),
                const SizedBox(height: 16),
                _Categorias(
                  recursos: _recursos,
                  onTap: (c) => widget.onVerEquipos(categoria: c),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Planifica tu próximo préstamo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _Carrusel(
                  tarjetas: [
                    _DatosTarjeta(
                      figura: Figuras.tarjetaPrestar,
                      titulo: 'Presta en segundos',
                      detalle: 'Equipos disponibles ahora mismo',
                      onTap: () => widget.onVerEquipos(estado: EstadoRecurso.disponible),
                    ),
                    _DatosTarjeta(
                      figura: Figuras.tarjetaDevolver,
                      titulo: 'Controla las devoluciones',
                      detalle: vencidos == 0
                          ? 'Nada vencido, vas al día'
                          : '$vencidos con plazo vencido',
                      onTap: () => widget.onVerActividad(),
                    ),
                    _DatosTarjeta(
                      figura: Figuras.tarjetaMantenimiento,
                      titulo: 'Equipos dañados',
                      detalle: 'Mira qué necesita mantenimiento',
                      onTap: () => widget.onVerEquipos(estado: EstadoRecurso.danado),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.salon,
    required this.vencidos,
    required this.onSalon,
    required this.onAvisos,
  });

  final String? salon;
  final int vencidos;
  final VoidCallback onSalon;
  final VoidCallback onAvisos;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onSalon,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F8CFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      salon == null ? 'Todos los salones' : 'Salón $salon',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textoSuave),
                ],
              ),
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onAvisos,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: vencidos > 0,
                  backgroundColor: AppColors.danado,
                  label: Text('$vencidos'),
                  child: const Icon(Icons.notifications_none_rounded, size: 26),
                ),
                const SizedBox(width: 8),
                const Text('Avisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Equipos | Préstamos" con subrayado, como las pestañas de la propuesta.
class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.onPrestamos});
  final VoidCallback onPrestamos;

  @override
  Widget build(BuildContext context) {
    Widget pestana(String texto, String figura, bool activa, VoidCallback? onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(figura, height: 34),
                  const SizedBox(width: 10),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: activa ? FontWeight.w800 : FontWeight.w500,
                      color: activa ? AppColors.texto : AppColors.textoSuave,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 3,
                width: 120,
                color: activa ? AppColors.texto : Colors.transparent,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        pestana('Equipos', Figuras.computador, true, null),
        pestana('Préstamos', Figuras.otros, false, onPrestamos),
      ],
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controlador,
    required this.onEnviar,
    required this.onFiltros,
  });

  final TextEditingController controlador;
  final ValueChanged<String> onEnviar;
  final VoidCallback onFiltros;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.borde, width: 1.5),
        color: AppColors.superficie,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controlador,
              textInputAction: TextInputAction.search,
              onSubmitted: onEnviar,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: '¿Qué equipo buscas?',
                hintStyle: TextStyle(fontSize: 20, color: AppColors.textoSuave),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onFiltros,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('Filtros', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Equivale a la tarjeta de dirección reciente: último equipo consultado o, si no hay, un resumen.
class _TarjetaReciente extends StatelessWidget {
  const _TarjetaReciente({required this.recursos, required this.onAbrir});
  final RecursosController recursos;
  final void Function(Recurso) onAbrir;

  @override
  Widget build(BuildContext context) {
    final r = recursos.reciente;
    final String titulo;
    final String detalle;
    final IconData icono;
    VoidCallback? onTap;

    if (r != null) {
      titulo = r.titulo;
      detalle = 'Salón ${r.salonId} · ${r.estado.etiqueta}';
      icono = Icons.history_rounded;
      onTap = () => onAbrir(r);
    } else {
      titulo = '${recursos.totalDisponibles} equipos disponibles';
      detalle = recursos.carga == Carga.ok
          ? '${recursos.totalFueraDeServicio} fuera de servicio de ${recursos.todos.length}'
          : 'Cargando inventario…';
      icono = Icons.inventory_2_outlined;
    }

    return TarjetaBorde(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, color: AppColors.textoSuave),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textoSuave),
        ],
      ),
    );
  }
}

class _Categorias extends StatelessWidget {
  const _Categorias({required this.recursos, required this.onTap});
  final RecursosController recursos;
  final ValueChanged<CategoriaRecurso> onTap;

  @override
  Widget build(BuildContext context) {
    final categorias = CategoriaRecurso.creables;
    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = categorias[i];
          final libres = recursos.disponiblesDe(c);
          return InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => onTap(c),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  FiguraCircular(figura: c.figura, tamano: 84),
                  const SizedBox(height: 10),
                  Text(
                    c.etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    recursos.carga == Carga.ok ? '$libres libres' : '—',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatosTarjeta {
  const _DatosTarjeta({
    required this.figura,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });
  final String figura;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
}

class _Carrusel extends StatelessWidget {
  const _Carrusel({required this.tarjetas});
  final List<_DatosTarjeta> tarjetas;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tarjetas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final t = tarjetas[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: t.onTap,
            child: SizedBox(
              width: 290,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 150,
                      width: 290,
                      child: SvgPicture.asset(t.figura, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: AppColors.textoSuave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../recursos/presentation/equipos_page.dart';
import '../../recursos/presentation/recursos_controller.dart';
import '../../salones/domain/entities/salon.dart';
import '../../salones/presentation/salon_detalle_page.dart';
import '../../salones/presentation/salones_controller.dart';
import '../../salones_admin/domain/entities/ocupacion.dart';
import '../../salones_admin/presentation/salon_control_page.dart';
import '../../salones_admin/presentation/salones_admin_controller.dart';
import '../../salones_admin/presentation/salones_admin_estilos.dart';

/// Inicio, al estilo de UTB App: encabezado en degradado con saludo, una tarjeta destacada con
/// lo más importante del momento y, debajo, lo que hay que atender. Cambia según el rol:
/// el auxiliar ve el estado del campus; el usuario UTB, los salones que puede pedir.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onIrSalones, required this.onIrControl});

  /// Abre la pestaña Salones (el auxiliar puede llegar con un filtro aplicado).
  final ValueChanged<FiltroPanel?> onIrSalones;
  final VoidCallback onIrControl;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _auth = sl<AuthController>();
  final SalonesAdminController _panel = sl<SalonesAdminController>();
  final SalonesController _salones = sl<SalonesController>();
  final RecursosController _recursos = sl<RecursosController>();

  bool get _esAuxiliar => _auth.esAdministrador;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  /// Si ya hay datos (al volver a la pestaña) se recarga en silencio, sin mostrar "Cargando".
  Future<void> _refrescar() async {
    if (_esAuxiliar) {
      await Future.wait([
        _panel.cargar(silencioso: _panel.carga == Carga.ok),
        _recursos.cargar(silencioso: _recursos.carga == Carga.ok),
      ]);
    } else {
      await _salones.cargar(silencioso: _salones.carga == Carga.ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_auth, _panel, _salones, _recursos]),
      builder: (context, _) => RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            _Encabezado(
              nombre: _auth.usuario?.nombre ?? '',
              destacada: _esAuxiliar ? _destacadaAuxiliar() : _destacadaUsuario(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _esAuxiliar ? _cuerpoAuxiliar(context) : _cuerpoUsuario(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auxiliar / administrador ───────────────────────────────────────────

  Widget _destacadaAuxiliar() {
    if (_panel.carga != Carga.ok) {
      return TarjetaDestacada(
        etiqueta: 'Ahora en el campus',
        titulo: _panel.carga == Carga.error ? 'Sin conexión' : 'Cargando salones…',
        detalle: _panel.error,
        color: AppColors.neutro,
      );
    }
    final enClase = _panel.contar(FiltroPanel.clases);
    final sinConfirmar = _panel.todos
        .where((o) => o.situacion == SituacionSalon.claseSinConfirmar)
        .length;
    return TarjetaDestacada(
      etiqueta: 'Ahora en el campus',
      titulo: enClase == 1 ? '1 clase en curso' : '$enClase clases en curso',
      detalle: sinConfirmar == 0
          ? 'Todos los profesores confirmados'
          : '$sinConfirmar sin confirmar profesor · ${_panel.totalReportes} reportes abiertos',
      datoGrande: '${_panel.todos.length - _panel.contar(FiltroPanel.libres)}',
      datoPequeno: 'en uso',
      color: sinConfirmar > 0 ? AppColors.prestado : AppColors.disponible,
      onTap: () => widget.onIrSalones(FiltroPanel.atencion),
    );
  }

  List<Widget> _cuerpoAuxiliar(BuildContext context) {
    final atencion = _panel.todos.where((o) => o.requiereAtencion).toList()
      ..sort((a, b) => a.salon.nombre.compareTo(b.salon.nombre));
    final clases = _panel.todos.where((o) => o.clase != null).toList()
      ..sort((a, b) => a.clase!.horaInicio.compareTo(b.clase!.horaInicio));
    final conNovedad = _recursos.totalFueraDeServicio;
    void abrir(OcupacionSalon o) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SalonControlPage(salonId: o.salon.id)),
        );

    return [
      Aparecer(
        child: Row(
          children: [
            Indicador(
              valor: '${_panel.contar(FiltroPanel.libres)}',
              etiqueta: 'Libres',
              color: AppColors.disponible,
              onTap: () => widget.onIrSalones(FiltroPanel.libres),
            ),
            const SizedBox(width: 10),
            Indicador(
              valor: '${_panel.contar(FiltroPanel.clases)}',
              etiqueta: 'En clase',
              color: AppColors.mantenimiento,
              onTap: () => widget.onIrSalones(FiltroPanel.clases),
            ),
            const SizedBox(width: 10),
            Indicador(
              valor: '${_panel.contar(FiltroPanel.atencion)}',
              etiqueta: 'Por atender',
              color: AppColors.danado,
              onTap: () => widget.onIrSalones(FiltroPanel.atencion),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Aparecer(
        orden: 1,
        child: TarjetaPromo(
          etiqueta: 'Inventario',
          titulo: 'Equipos de los salones',
          detalle: conNovedad == 0
              ? 'Todos los equipos funcionan'
              : '$conNovedad equipos dañados o en mantenimiento',
          accion: 'Ver inventario',
          icono: Icons.devices_other_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EquiposPage()),
          ),
        ),
      ),
      const SizedBox(height: 28),
      TituloSeccion(
        'Por atender',
        subtitulo: atencion.isEmpty
            ? 'Nada pendiente, todo en orden'
            : 'Profesores sin confirmar, reportes y solicitudes',
        onVerTodo: () => widget.onIrSalones(FiltroPanel.atencion),
      ),
      const SizedBox(height: 12),
      for (final (i, o) in atencion.take(4).indexed) ...[
        Aparecer(orden: i + 2, child: _FilaAtencion(ocupacion: o, onTap: () => abrir(o))),
        const SizedBox(height: 10),
      ],
      if (clases.isNotEmpty) ...[
        const SizedBox(height: 18),
        TituloSeccion('Clases en curso', subtitulo: '${clases.length} salones con clase ahora'),
        const SizedBox(height: 14),
        for (final (i, o) in clases.indexed)
          Aparecer(
            orden: i + 4,
            child: FilaLineaTiempo(
              hora: o.clase!.horaInicio.substring(0, 5),
              color: colorDeSituacion(o.situacion),
              ultimo: i == clases.length - 1,
              child: _TarjetaClase(ocupacion: o, onTap: () => abrir(o)),
            ),
          ),
      ],
    ];
  }

  // ── Usuario UTB ────────────────────────────────────────────────────────

  List<Salon> get _libres => _salones.todos.where((s) => s.disponible).toList()
    ..sort((a, b) => a.nombre.compareTo(b.nombre));

  Widget _destacadaUsuario() {
    final libres = _libres.length;
    return TarjetaDestacada(
      etiqueta: 'Salones libres',
      titulo: _salones.carga == Carga.ok
          ? (libres == 0 ? 'No hay salones libres' : 'Puedes pedir un salón')
          : 'Cargando salones…',
      detalle: 'Para estudiar, exponer o reunirte con tu grupo',
      datoGrande: _salones.carga == Carga.ok ? '$libres' : null,
      datoPequeno: 'libres',
      color: libres > 0 ? AppColors.disponible : AppColors.prestado,
      onTap: () => widget.onIrSalones(null),
    );
  }

  List<Widget> _cuerpoUsuario(BuildContext context) {
    final libres = _libres;
    return [
      Aparecer(
        child: TarjetaPromo(
          etiqueta: 'Solicitud',
          titulo: 'Solicita un salón',
          detalle: 'Elige el salón, la hora y el motivo. El auxiliar te confirma.',
          accion: 'Ver salones',
          onTap: () => widget.onIrSalones(null),
        ),
      ),
      const SizedBox(height: 16),
      Aparecer(
        orden: 1,
        child: TarjetaPromo(
          etiqueta: 'Mis solicitudes',
          titulo: 'Sigue tus pedidos',
          detalle: 'Mira si tus salones fueron aprobados y tus reportes atendidos.',
          accion: 'Abrir control',
          icono: Icons.fact_check_rounded,
          onTap: widget.onIrControl,
        ),
      ),
      const SizedBox(height: 28),
      TituloSeccion('Libres ahora',
          subtitulo: 'Salones disponibles en el campus', onVerTodo: () => widget.onIrSalones(null)),
      const SizedBox(height: 12),
      for (final (i, s) in libres.take(6).indexed) ...[
        Aparecer(
          orden: i + 2,
          child: TarjetaBorde(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SalonDetallePage(salon: s)),
            ),
            child: Row(
              children: [
                _CodigoSalon(codigo: s.nombre),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.detalleUbicacion,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 14)),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textoTenue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.nombre, required this.destacada});
  final String nombre;
  final Widget destacada;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
    return EncabezadoDegradado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fechaLarga(ahora),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: '${saludo(ahora)}, ',
                        style: const TextStyle(color: AppColors.indigoClaro),
                        children: [
                          TextSpan(
                            text: primerNombre,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 16)],
                ),
                child: AvatarIniciales(nombre: nombre, tamano: 62, color: AppColors.primario),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Aparecer(child: destacada),
        ],
      ),
    );
  }
}

class _CodigoSalon extends StatelessWidget {
  const _CodigoSalon({required this.codigo, this.color});
  final String codigo;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: color == null
            ? AppColors.degradado
            : LinearGradient(colors: [color!.withValues(alpha: 0.35), color!.withValues(alpha: 0.12)]),
      ),
      child: Text(
        codigo,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
      ),
    );
  }
}

class _FilaAtencion extends StatelessWidget {
  const _FilaAtencion({required this.ocupacion, required this.onTap});
  final OcupacionSalon ocupacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = ocupacion;
    final color = colorDeSituacion(o.situacion);
    final motivos = <String>[
      if (o.situacion == SituacionSalon.claseSinConfirmar) 'Confirmar profesor',
      if (o.situacion == SituacionSalon.claseSinProfesor) 'Profesor ausente',
      if (o.reportesAbiertos > 0)
        o.reportesAbiertos == 1 ? '1 reporte' : '${o.reportesAbiertos} reportes',
      if (o.solicitudesPendientes > 0)
        o.solicitudesPendientes == 1 ? '1 solicitud' : '${o.solicitudesPendientes} solicitudes',
    ];
    return TarjetaBorde(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _CodigoSalon(codigo: o.salon.nombre, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.titular,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(motivos.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textoTenue),
        ],
      ),
    );
  }
}

class _TarjetaClase extends StatelessWidget {
  const _TarjetaClase({required this.ocupacion, required this.onTap});
  final OcupacionSalon ocupacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ocupacion.clase!;
    final color = colorDeSituacion(ocupacion.situacion);
    return TarjetaBorde(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Insignia(texto: ocupacion.salon.nombre, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textoTenue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(c.nombreProfesor,
                    style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5)),
              ),
              Text(c.rango,
                  style: const TextStyle(color: AppColors.textoTenue, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

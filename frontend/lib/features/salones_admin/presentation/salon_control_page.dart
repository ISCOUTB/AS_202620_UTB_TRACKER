import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/auth_domain.dart';
import '../../salones/domain/entities/salon.dart';
import '../domain/entities/ocupacion.dart';
import '../domain/repositories/salones_admin_repository.dart';
import 'reporte_salon_sheet.dart';
import 'salon_control_controller.dart';
import 'salones_admin_estilos.dart';

/// Control de un salón: quién lo tiene, si el profesor llegó, solicitudes y reportes.
class SalonControlPage extends StatefulWidget {
  const SalonControlPage({super.key, required this.salonId});

  final int salonId;

  @override
  State<SalonControlPage> createState() => _SalonControlPageState();
}

class _SalonControlPageState extends State<SalonControlPage> {
  late final SalonControlController _c;

  @override
  void initState() {
    super.initState();
    _c = SalonControlController(
      sl<SalonesAdminRepository>(),
      sl<AuthRepository>(),
      widget.salonId,
    )..cargar();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Ejecuta una acción del controlador y avisa el resultado.
  Future<void> _ejecutar(Future<String?> Function() accion, String exito) async {
    final error = await accion();
    if (!mounted) return;
    mostrarMensaje(context, error ?? exito);
  }

  Future<bool> _confirmar(String titulo, String texto, String boton) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(boton, style: const TextStyle(color: AppColors.danado)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _reportar(OcupacionSalon o) async {
    final enviado = await mostrarReporteSalonSheet(
      context,
      salon: o.salon.nombre,
      onEnviar: _c.reportar,
    );
    if (enviado == true && mounted) mostrarMensaje(context, 'Reporte enviado');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final o = _c.ocupacion;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _c.cargar(silencioso: true),
              ),
            ],
          ),
          body: _cuerpo(o),
          bottomNavigationBar: o == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: BotonPildora(
                      texto: 'Reportar novedad',
                      icono: Icons.flag_rounded,
                      estilo: EstiloBoton.secundario,
                      onPressed: () => _reportar(o),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _cuerpo(OcupacionSalon? o) {
    if (_c.carga == Carga.cargando && o == null) return const VistaCargando();
    if (o == null) {
      return VistaError(mensaje: _c.error ?? 'Error', onReintentar: _c.cargar);
    }
    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: AppColors.texto,
      onRefresh: () => _c.cargar(silencioso: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _Encabezado(ocupacion: o),
          const SizedBox(height: 22),
          const _Titulo('Quién tiene el salón'),
          const SizedBox(height: 10),
          _TarjetaOcupante(ocupacion: o),
          if (o.clase != null) ...[
            const SizedBox(height: 12),
            _TarjetaProfesor(
              ocupacion: o,
              onConfirmar: (presente) => _ejecutar(
                () => _c.confirmarProfesor(presente: presente),
                presente ? 'Profesor confirmado' : 'Marcado como ausente',
              ),
            ),
          ],
          if (_c.pendientes.isNotEmpty) ...[
            const SizedBox(height: 26),
            _Titulo('Solicitudes por decidir', cantidad: _c.pendientes.length),
            const SizedBox(height: 10),
            for (final s in _c.pendientes)
              _TarjetaSolicitud(
                solicitud: s,
                nombre: _c.nombreDe(s.usuarioId),
                acciones: [
                  BotonPildora(
                    texto: 'Aprobar',
                    compacto: true,
                    onPressed: () => _ejecutar(
                      () => _c.decidirSolicitud(s.id, 'aprobado'),
                      'Solicitud aprobada',
                    ),
                  ),
                  BotonPildora(
                    texto: 'Rechazar',
                    compacto: true,
                    estilo: EstiloBoton.peligro,
                    onPressed: () async {
                      final ok = await _confirmar(
                        'Rechazar solicitud',
                        'La solicitud de ${_c.nombreDe(s.usuarioId)} quedará rechazada.',
                        'Rechazar',
                      );
                      if (ok) {
                        await _ejecutar(
                          () => _c.decidirSolicitud(s.id, 'rechazado'),
                          'Solicitud rechazada',
                        );
                      }
                    },
                  ),
                ],
              ),
          ],
          if (_c.vigentes.isNotEmpty) ...[
            const SizedBox(height: 26),
            _Titulo('Préstamos programados', cantidad: _c.vigentes.length),
            const SizedBox(height: 10),
            for (final s in _c.vigentes)
              _TarjetaSolicitud(
                solicitud: s,
                nombre: _c.nombreDe(s.usuarioId),
                acciones: s.estado == 'aprobado'
                    ? [
                        BotonPildora(
                          texto: 'Entregar salón',
                          compacto: true,
                          onPressed: () => _ejecutar(
                            () => _c.decidirSolicitud(s.id, 'en_uso'),
                            'Salón entregado',
                          ),
                        ),
                        BotonPildora(
                          texto: 'Cancelar',
                          compacto: true,
                          estilo: EstiloBoton.peligro,
                          onPressed: () async {
                            final ok = await _confirmar(
                              'Cancelar préstamo',
                              'Se cancelará el préstamo de ${_c.nombreDe(s.usuarioId)}.',
                              'Cancelar préstamo',
                            );
                            if (ok) {
                              await _ejecutar(
                                () => _c.decidirSolicitud(s.id, 'cancelado'),
                                'Préstamo cancelado',
                              );
                            }
                          },
                        ),
                      ]
                    : [
                        BotonPildora(
                          texto: 'Finalizar uso',
                          compacto: true,
                          onPressed: () => _ejecutar(
                            () => _c.decidirSolicitud(s.id, 'finalizado'),
                            'Uso finalizado',
                          ),
                        ),
                      ],
              ),
          ],
          const SizedBox(height: 26),
          _Titulo('Reportes', cantidad: _c.reportesAbiertos.length),
          const SizedBox(height: 10),
          if (_c.reportes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin reportes. Usa "Reportar novedad" si algo anda mal en el salón.',
                style: TextStyle(color: AppColors.textoSuave),
              ),
            )
          else
            for (final r in _c.reportes)
              _TarjetaReporte(
                reporte: r,
                autor: _c.nombreDe(r.usuarioId),
                onResolver: () => _ejecutar(
                  () => _c.resolverReporte(r.id, resuelto: r.abierto),
                  r.abierto ? 'Reporte resuelto' : 'Reporte reabierto',
                ),
              ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {this.cantidad});
  final String texto;
  final int? cantidad;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(texto, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        if (cantidad != null && cantidad! > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.texto,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cantidad',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.ocupacion});
  final OcupacionSalon ocupacion;

  @override
  Widget build(BuildContext context) {
    final s = ocupacion.situacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ocupacion.salon.nombre,
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: 6),
        Text(
          '${ocupacion.salon.detalleUbicacion} · ${ocupacion.salon.capacidad} personas',
          style: const TextStyle(color: AppColors.textoSuave, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Insignia(texto: etiquetaDeSituacion(s), color: colorDeSituacion(s)),
      ],
    );
  }
}

class _TarjetaOcupante extends StatelessWidget {
  const _TarjetaOcupante({required this.ocupacion});
  final OcupacionSalon ocupacion;

  @override
  Widget build(BuildContext context) {
    final s = ocupacion.situacion;
    final color = colorDeSituacion(s);
    final nombre = switch (ocupacion.ocupante) {
      Ocupante.clase => ocupacion.clase?.profesor,
      Ocupante.prestamo => ocupacion.prestamo?.usuarioNombre,
      Ocupante.libre => null,
    };
    final detalle = <String>[
      if (ocupacion.clase != null) ocupacion.clase!.rango,
      if (ocupacion.ocupante == Ocupante.prestamo && ocupacion.prestamo != null)
        '${formatearHora(ocupacion.prestamo!.fechaInicio)} – ${formatearHora(ocupacion.prestamo!.fechaFin)}',
    ];

    return TarjetaBorde(
      child: Row(
        children: [
          if (nombre != null && nombre.isNotEmpty)
            AvatarIniciales(nombre: nombre, tamano: 58, color: color)
          else
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(
                s == SituacionSalon.libre ? Icons.event_available_rounded : Icons.build_circle_outlined,
                color: color,
                size: 28,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ocupacion.titular,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  ocupacion.subtitular,
                  style: const TextStyle(color: AppColors.textoSuave),
                ),
                if (detalle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textoSuave),
                      const SizedBox(width: 6),
                      Text(detalle.join(' · '), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaProfesor extends StatelessWidget {
  const _TarjetaProfesor({required this.ocupacion, required this.onConfirmar});

  final OcupacionSalon ocupacion;
  final void Function(bool presente) onConfirmar;

  @override
  Widget build(BuildContext context) {
    final presente = ocupacion.profesorPresente;
    final (titulo, color) = switch (presente) {
      true => ('El profesor está en el salón', AppColors.disponible),
      false => ('El profesor no ha llegado', AppColors.danado),
      null => ('¿Ya llegó el profesor?', AppColors.prestado),
    };

    return TarjetaBorde(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                presente == true ? Icons.verified_rounded : Icons.person_search_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Clase: ${ocupacion.clase!.titulo} · ${ocupacion.clase!.rango}',
            style: const TextStyle(color: AppColors.textoSuave),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BotonPildora(
                  texto: 'Sí, llegó',
                  icono: Icons.check_rounded,
                  estilo: presente == true ? EstiloBoton.secundario : EstiloBoton.principal,
                  onPressed: presente == true ? null : () => onConfirmar(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BotonPildora(
                  texto: 'No ha llegado',
                  icono: Icons.close_rounded,
                  estilo: presente == false ? EstiloBoton.secundario : EstiloBoton.peligro,
                  onPressed: presente == false ? null : () => onConfirmar(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _colorDeSolicitud(String estado) => switch (estado) {
      'pendiente' => AppColors.prestado,
      'aprobado' => AppColors.mantenimiento,
      'en_uso' => const Color(0xFFB892FF),
      'finalizado' => AppColors.disponible,
      'rechazado' => AppColors.danado,
      _ => AppColors.neutro,
    };

String _etiquetaDeSolicitud(String estado) => switch (estado) {
      'pendiente' => 'Pendiente',
      'aprobado' => 'Aprobado',
      'en_uso' => 'En uso',
      'finalizado' => 'Finalizado',
      'rechazado' => 'Rechazado',
      'cancelado' => 'Cancelado',
      _ => estado,
    };

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({
    required this.solicitud,
    required this.nombre,
    required this.acciones,
  });

  final PrestamoSalon solicitud;
  final String nombre;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TarjetaBorde(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarIniciales(nombre: nombre, tamano: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${formatearFechaHora(solicitud.fechaInicio)} → ${formatearHora(solicitud.fechaFin)}',
                        style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Insignia(
                  texto: _etiquetaDeSolicitud(solicitud.estado),
                  color: _colorDeSolicitud(solicitud.estado),
                ),
              ],
            ),
            if (solicitud.motivo != null && solicitud.motivo!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(solicitud.motivo!, style: const TextStyle(color: AppColors.textoSuave)),
            ],
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < acciones.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: acciones[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({
    required this.reporte,
    required this.autor,
    required this.onResolver,
  });

  final ReporteSalon reporte;
  final String autor;
  final VoidCallback onResolver;

  @override
  Widget build(BuildContext context) {
    final color = reporte.abierto ? AppColors.prestado : AppColors.disponible;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: reporte.abierto ? 1 : 0.6,
        child: TarjetaBorde(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconoDeTipoReporte(reporte.tipo), color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reporte.tipo.etiqueta,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Insignia(texto: reporte.abierto ? 'Abierto' : 'Resuelto', color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(reporte.descripcion),
              const SizedBox(height: 6),
              Text(
                '$autor · ${haceCuanto(reporte.creadoEn)}',
                style: const TextStyle(color: AppColors.textoTenue, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              BotonPildora(
                texto: reporte.abierto ? 'Marcar como resuelto' : 'Reabrir',
                compacto: true,
                estilo: reporte.abierto ? EstiloBoton.principal : EstiloBoton.secundario,
                onPressed: onResolver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

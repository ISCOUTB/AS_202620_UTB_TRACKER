import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../../salones/domain/entities/salon.dart';
import '../data/admin_data.dart';
import 'admin_controllers.dart';

const _estados = {
  'pendiente': ('Pendientes', AppColors.prestado),
  'aprobado': ('Aprobadas', AppColors.disponible),
  'rechazado': ('Rechazadas', AppColors.danado),
  'cancelado': ('Canceladas', AppColors.neutro),
  'en_uso': ('En uso', AppColors.mantenimiento),
  'finalizado': ('Finalizadas', AppColors.neutro),
};

/// ESTADÍSTICAS (solo Administrador, ADR-0018): uso de salones, solicitudes por estado,
/// reportes y usuarios por rol. Solo datos reales del servidor (`GET /stats/admin`).
class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key, this.controller});
  final EstadisticasController? controller;

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  late final EstadisticasController _c = widget.controller ?? sl<EstadisticasController>();

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: si esta pantalla aparece mientras otra aún se dibuja
    // (cambio de pestaña o de rol en el modo prueba), no se avisa a mitad del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConPermiso(
        permiso: Permisos.estadisticasVer,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _c.cargar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                EncabezadoDegradado(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('Estadísticas',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 0, 10),
                        child: Text('Uso de los salones en los últimos ${_c.dias} días',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final d in const [7, 30, 90])
                            ChoiceChip(
                              label: Text('$d días'),
                              selected: _c.dias == d,
                              onSelected: (_) => _c.fijarDias(d),
                            ),
                        ],
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
    if (_c.sinAcceso) return const SinAcceso();
    switch (_c.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(mensaje: _c.error ?? 'Error', onReintentar: _c.cargar);
      case Carga.ok:
        final d = _c.datos!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TituloSeccion('Solicitudes de salón', subtitulo: '${d.totalSolicitudes} en el periodo'),
            const SizedBox(height: 8),
            if (d.totalSolicitudes == 0)
              const VistaVacia(mensaje: 'Sin solicitudes en este periodo')
            else
              for (final e in d.solicitudesPorEstado.entries)
                _Barra(
                  etiqueta: _estados[e.key]?.$1 ?? e.key,
                  valor: e.value,
                  maximo: d.totalSolicitudes,
                  color: _estados[e.key]?.$2 ?? AppColors.neutro,
                ),
            const SizedBox(height: 16),
            const TituloSeccion('Salones más pedidos'),
            const SizedBox(height: 8),
            if (d.salonesMasSolicitados.isEmpty)
              const VistaVacia(mensaje: 'Nadie ha pedido salones en este periodo')
            else
              for (final (salon, total) in d.salonesMasSolicitados)
                _Barra(
                  etiqueta: salon,
                  valor: total,
                  maximo: d.salonesMasSolicitados.first.$2,
                  color: AppColors.primarioClaro,
                ),
            const SizedBox(height: 16),
            _Resumen(datos: d),
          ],
        );
    }
  }
}

/// Barra horizontal con la cifra escrita (no depende solo del largo ni del color).
class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
    required this.color,
  });

  final String etiqueta;
  final int valor;
  final int maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maximo == 0 ? 0 : valor / maximo,
                  minHeight: 10,
                  color: color,
                  backgroundColor: AppColors.superficieAlta,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 34,
              child: Text('$valor',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.datos});
  final EstadisticasAdmin datos;

  @override
  Widget build(BuildContext context) {
    final d = datos;
    String lista(Map<String, int> m, String Function(String) nombre) => m.isEmpty
        ? 'Ninguno'
        : (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => '${nombre(e.key)}: ${e.value}')
            .join(' · ');
    String tipoSalon(String t) => TipoSalon.desdeApi(t).etiqueta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Personas y espacios'),
        const SizedBox(height: 8),
        _Dato(
          icono: Icons.group_rounded,
          titulo: 'Usuarios activos',
          texto: [for (final (rol, total) in d.usuariosPorRol) '$rol: $total'].join(' · ') +
              (d.usuariosInactivos > 0 ? ' · ${d.usuariosInactivos} desactivados' : ''),
        ),
        _Dato(
          icono: Icons.meeting_room_rounded,
          titulo: 'Salones por tipo',
          texto: lista(d.salonesPorTipo, tipoSalon),
        ),
        _Dato(
          icono: Icons.report_problem_rounded,
          titulo: 'Reportes de salones',
          texto: '${lista(d.reportesPorEstado, (e) => e == 'abierto' ? 'Abiertos' : 'Resueltos')}'
              '\nPor tipo: ${lista(d.reportesPorTipo, (t) => t[0].toUpperCase() + t.substring(1))}',
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.titulo, required this.texto});
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TarjetaBorde(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: AppColors.primarioClaro, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(texto, style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

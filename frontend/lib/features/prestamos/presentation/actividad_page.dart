import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../recursos/domain/entities/recurso.dart';
import '../../recursos/presentation/recurso_detalle_page.dart';
import '../../recursos/presentation/recursos_controller.dart';
import '../domain/entities/prestamo.dart';
import 'prestamos_controller.dart';

/// Pestaña "Actividad": préstamos activos, vencidos y devueltos.
/// El auxiliar ve todos; el usuario UTB solo los suyos.
class ActividadPage extends StatefulWidget {
  const ActividadPage({super.key, this.filtroInicial = 0});

  /// 0 = Activos, 1 = Vencidos, 2 = Devueltos.
  final int filtroInicial;

  @override
  State<ActividadPage> createState() => _ActividadPageState();
}

class _ActividadPageState extends State<ActividadPage> {
  final PrestamosController _prestamos = sl<PrestamosController>();
  final RecursosController _recursos = sl<RecursosController>();
  final AuthController _auth = sl<AuthController>();

  late int _filtro = widget.filtroInicial;

  static const _estados = [
    EstadoPrestamo.activo,
    EstadoPrestamo.vencido,
    EstadoPrestamo.devuelto,
  ];
  static const _titulos = ['Activos', 'Vencidos', 'Devueltos'];

  @override
  void didUpdateWidget(covariant ActividadPage old) {
    super.didUpdateWidget(old);
    if (old.filtroInicial != widget.filtroInicial) _filtro = widget.filtroInicial;
  }

  List<Prestamo> _alcance() {
    final u = _auth.usuario;
    if (u == null) return const [];
    return u.esAdministrador ? _prestamos.todos : _prestamos.deUsuario(u.id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([_prestamos, _recursos, _auth]),
        builder: (context, _) {
          final ahora = DateTime.now();
          final base = _alcance();
          final lista = _prestamos.filtrarPorEstado(base, _estados[_filtro], ahora: ahora);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  _auth.esAdministrador ? 'Actividad del campus' : 'Mis préstamos',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _estados.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final n = _prestamos.filtrarPorEstado(base, _estados[i], ahora: ahora).length;
                    return ChoiceChip(
                      label: Text('${_titulos[i]} · $n'),
                      selected: _filtro == i,
                      onSelected: (_) => setState(() => _filtro = i),
                    );
                  },
                ),
              ),
              Expanded(child: _cuerpo(lista, ahora)),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo(List<Prestamo> lista, DateTime ahora) {
    switch (_prestamos.carga) {
      case Carga.inicial:
      case Carga.cargando:
        return const VistaCargando();
      case Carga.error:
        return VistaError(
          mensaje: _prestamos.error ?? 'No pudimos cargar los préstamos.',
          onReintentar: _prestamos.cargar,
        );
      case Carga.ok:
        return RefreshIndicator(
          color: Colors.black,
          backgroundColor: AppColors.texto,
          onRefresh: () async {
            await Future.wait([
              _prestamos.cargar(silencioso: true),
              _recursos.cargar(silencioso: true),
            ]);
          },
          child: lista.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: 340,
                      child: VistaVacia(
                        mensaje: switch (_estados[_filtro]) {
                          EstadoPrestamo.activo => 'No hay préstamos activos',
                          EstadoPrestamo.vencido => 'Nada vencido',
                          EstadoPrestamo.devuelto => 'Aún no hay devoluciones',
                        },
                        detalle: _estados[_filtro] == EstadoPrestamo.devuelto
                            ? 'Las devoluciones aparecerán aquí cuando el servidor las registre.'
                            : 'Desliza hacia abajo para actualizar.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _FilaPrestamo(
                    prestamo: lista[i],
                    recurso: _recursos.porId(lista[i].recursoId),
                    verUsuario: _auth.esAdministrador,
                    ahora: ahora,
                  ),
                ),
        );
    }
  }
}

class _FilaPrestamo extends StatelessWidget {
  const _FilaPrestamo({
    required this.prestamo,
    required this.recurso,
    required this.verUsuario,
    required this.ahora,
  });

  final Prestamo prestamo;
  final Recurso? recurso;
  final bool verUsuario;
  final DateTime ahora;

  void _confirmarDevolucion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: const Text('Devolver equipo'),
        content: Text(
          '¿Confirmas la devolución de ${recurso?.titulo ?? "Equipo #${prestamo.recursoId}"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSuave)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.disponible),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final ok = await sl<PrestamosController>().devolver(prestamo.id);
              if (ok) {
                await sl<RecursosController>().cargar(silencioso: true);
                if (context.mounted) {
                  mostrarMensaje(context, 'Equipo devuelto correctamente');
                }
              }
            },
            child: const Text(
              'Confirmar devolución',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = prestamo.estadoEn(ahora);
    final etiquetaEstado = switch (estado) {
      EstadoPrestamo.activo => 'Activo',
      EstadoPrestamo.vencido => 'Vencido',
      EstadoPrestamo.devuelto => 'Devuelto',
    };
    final plazo = prestamo.devuelto
        ? 'Devuelto ${formatearFechaHora(prestamo.fechaDevolucionReal!)}'
        : '${describirPlazo(prestamo.fechaDevolucionEsperada, ahora: ahora)} · '
            '${formatearFechaHora(prestamo.fechaDevolucionEsperada)}';

    return TarjetaBorde(
      padding: const EdgeInsets.all(12),
      onTap: recurso == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecursoDetallePage(recurso: recurso!),
                ),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FiguraCircular(
                figura: (recurso?.categoria ?? CategoriaRecurso.otro).figura,
                tamano: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurso?.titulo ?? 'Equipo #${prestamo.recursoId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verUsuario
                          ? 'Usuario #${prestamo.usuarioId} · desde ${formatearFechaHora(prestamo.fechaPrestamo)}'
                          : 'Desde ${formatearFechaHora(prestamo.fechaPrestamo)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plazo,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: estado == EstadoPrestamo.vencido
                            ? AppColors.danado
                            : AppColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Insignia(texto: etiquetaEstado, color: colorDePrestamo(estado)),
            ],
          ),
          if (!prestamo.devuelto) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.disponible,
                    side: const BorderSide(color: AppColors.disponible),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Devolver equipo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _confirmarDevolucion(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

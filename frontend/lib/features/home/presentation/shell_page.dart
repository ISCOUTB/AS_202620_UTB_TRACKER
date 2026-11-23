import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../control/presentation/control_page.dart';
import '../../cuenta/presentation/cuenta_page.dart';
import '../../recursos/presentation/equipos_page.dart';
import '../../salones/presentation/salones_page.dart';
import '../../salones_admin/presentation/panel_salones_page.dart';
import '../../salones_admin/presentation/salones_admin_controller.dart';
import '../../solicitudes/presentation/solicitudes_pages.dart';
import 'home_page.dart';

/// Pestañas posibles de la barra inferior.
enum Pestana {
  inicio(Icons.home_rounded, 'Inicio'),
  salones(Icons.meeting_room_rounded, 'Salones'),
  solicitudes(Icons.event_available_rounded, 'Solicitudes'),
  control(Icons.fact_check_rounded, 'Control'),
  equipos(Icons.devices_other_rounded, 'Equipos'),
  perfil(Icons.account_circle_rounded, 'Perfil');

  const Pestana(this.icono, this.etiqueta);
  final IconData icono;
  final String etiqueta;
}

/// Pestañas según los PERMISOS (ADR-0018), nunca según el texto del rol:
/// - Estudiante: Inicio · Salones · Solicitudes (las suyas) · Perfil.
/// - Auditor: Inicio · Salones (panel) · Solicitudes (bandeja) · Control · Equipos · Perfil.
/// - Administrador: lo del Auditor; Usuarios, Bitácora y Estadísticas van en Perfil e Inicio.
List<Pestana> pestanasPara(Permisos p) => [
      Pestana.inicio,
      if (p.puede(Permisos.salonesVer)) Pestana.salones,
      if (p.puede(Permisos.solicitudesGestionar) || p.puede(Permisos.solicitudesPropias))
        Pestana.solicitudes,
      if (p.puede(Permisos.reportesGestionar)) Pestana.control,
      if (p.puede(Permisos.equiposGestionar)) Pestana.equipos,
      Pestana.perfil,
    ];

/// Contenedor con la barra inferior flotante. Si los permisos cambian (otro rol, modo prueba)
/// la barra se recalcula y, si la pestaña abierta ya no existe, vuelve a Inicio.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final AuthController _auth = sl<AuthController>();

  // Pestaña inicial según la preferencia guardada en el servidor (ADR-0016).
  late Pestana _actual = switch (_auth.usuario?.preferencias.pantallaInicio) {
    'salones' => Pestana.salones,
    'control' => Pestana.control,
    _ => Pestana.inicio,
  };

  void _ir(Pestana p) => setState(() => _actual = p);

  void _irSalones(FiltroPanel? filtro) {
    if (filtro != null) sl<SalonesAdminController>().fijarFiltro(filtro);
    _ir(Pestana.salones);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final permisos = _auth.permisos;
        final pestanas = pestanasPara(permisos);
        final actual = pestanas.contains(_actual) ? _actual : Pestana.inicio;
        return Scaffold(
          extendBody: true,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: 0.985, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              // La vista cambia también con el rol que se está viendo (modo prueba).
              key: ValueKey('$actual-${_auth.vistaComo}'),
              child: _pagina(actual, permisos),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_auth.vistaComo != null) _FranjaModoPrueba(auth: _auth),
              BarraInferior(pestanas: pestanas, actual: actual, onTap: _ir),
            ],
          ),
        );
      },
    );
  }

  Widget _pagina(Pestana p, Permisos permisos) => switch (p) {
        Pestana.inicio => HomePage(
            onIrSalones: _irSalones,
            onIrSolicitudes: () => _ir(Pestana.solicitudes),
          ),
        // Quien administra ve el panel con el plano; el estudiante consulta y pide.
        Pestana.salones => permisos.opera ? const PanelSalonesPage() : const SalonesPage(),
        Pestana.solicitudes => permisos.puede(Permisos.solicitudesGestionar)
            ? const BandejaSolicitudesPage()
            : MisSolicitudesPage(onIrSalones: () => _ir(Pestana.salones)),
        Pestana.control => const ControlPage(),
        Pestana.equipos => const EquiposPage(),
        Pestana.perfil => const CuentaPage(),
      };
}

/// "Viendo como Estudiante · Salir": siempre visible en el modo prueba, para no confundirse.
class _FranjaModoPrueba extends StatelessWidget {
  const _FranjaModoPrueba({required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final rol = auth.etiquetaDe(auth.vistaComo ?? '');
    return Semantics(
      liveRegion: true,
      label: 'Modo prueba: viendo la app como $rol',
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.prestado.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.prestado),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_rounded, size: 18, color: AppColors.prestado),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Viendo como $rol',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            TextButton(onPressed: () => auth.verComo(null), child: const Text('Salir')),
          ],
        ),
      ),
    );
  }
}

class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.pestanas,
    required this.actual,
    required this.onTap,
  });

  final List<Pestana> pestanas;
  final Pestana actual;
  final ValueChanged<Pestana> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          // Vidrio esmerilado: se difumina lo que pasa por detrás.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.superficie.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  for (final p in pestanas)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: p == actual,
                        label: p.etiqueta,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(p),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // La pestaña activa se enciende como la baldosa del logo.
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 40,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: p == actual ? AppColors.degradado : null,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: p == actual
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primario.withValues(alpha: 0.5),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  p.icono,
                                  size: 19,
                                  color: p == actual ? Colors.white : AppColors.textoTenue,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Con 6 pestañas o texto grande a 360 dp, la etiqueta se achica
                              // (a lo ancho y a lo alto) en vez de desbordarse.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    p.etiqueta,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: p == actual ? FontWeight.w800 : FontWeight.w500,
                                      color: p == actual ? AppColors.texto : AppColors.textoTenue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

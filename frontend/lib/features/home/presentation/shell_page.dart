import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../control/presentation/control_page.dart';
import '../../cuenta/presentation/cuenta_page.dart';
import '../../salones/presentation/salones_page.dart';
import '../../salones_admin/presentation/panel_salones_page.dart';
import '../../salones_admin/presentation/salones_admin_controller.dart';
import 'home_page.dart';

/// Contenedor con la barra inferior flotante (Inicio · Salones · Control · Perfil), como la de
/// UTB App. Los equipos no tienen pestaña propia: se ven por salón o desde el inventario.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _indice = 0;

  void _ir(int i) => setState(() => _indice = i);

  void _irSalones(FiltroPanel? filtro) {
    if (filtro != null) sl<SalonesAdminController>().fijarFiltro(filtro);
    _ir(1);
  }

  @override
  Widget build(BuildContext context) {
    final esAuxiliar = sl<AuthController>().esAdministrador;
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
          key: ValueKey(_indice),
          child: switch (_indice) {
            0 => HomePage(onIrSalones: _irSalones, onIrControl: () => _ir(2)),
            // El auxiliar/admin administra los salones; el usuario UTB los consulta y pide.
            1 => esAuxiliar ? const PanelSalonesPage() : const SalonesPage(),
            2 => const ControlPage(),
            _ => const CuentaPage(),
          },
        ),
      ),
      bottomNavigationBar: _BarraInferior(indice: _indice, onTap: _ir),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.indice, required this.onTap});
  final int indice;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.meeting_room_rounded, 'Salones'),
    (Icons.fact_check_rounded, 'Control'),
    (Icons.account_circle_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          // Vidrio esmerilado: se difumina lo que pasa por detrás.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 74,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.superficieAlta.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            gradient: i == indice
                                ? LinearGradient(colors: [
                                    AppColors.primario.withValues(alpha: 0.45),
                                    AppColors.indigo.withValues(alpha: 0.30),
                                  ])
                                : null,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 220),
                                scale: i == indice ? 1.12 : 1,
                                child: Icon(
                                  _items[i].$1,
                                  size: 24,
                                  color: i == indice ? AppColors.indigoClaro : AppColors.textoSuave,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _items[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: i == indice ? FontWeight.w800 : FontWeight.w500,
                                  color: i == indice ? AppColors.texto : AppColors.textoSuave,
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

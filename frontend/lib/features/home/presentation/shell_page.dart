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

/// Contenedor con la barra inferior flotante (Inicio · Salones · Control · Perfil). Los equipos no tienen pestaña propia: se ven por salón o desde el inventario.
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
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          // Vidrio esmerilado: se difumina lo que pasa por detrás.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.superficie.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // La pestaña activa se enciende como la baldosa del logo.
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 44,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: i == indice ? AppColors.degradado : null,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: i == indice
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primario.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                _items[i].$1,
                                size: 19,
                                color: i == indice ? Colors.white : AppColors.textoTenue,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _items[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: i == indice ? FontWeight.w800 : FontWeight.w500,
                                color: i == indice ? AppColors.texto : AppColors.textoTenue,
                              ),
                            ),
                          ],
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

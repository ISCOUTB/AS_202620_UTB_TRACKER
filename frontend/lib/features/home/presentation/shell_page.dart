import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../cuenta/presentation/cuenta_page.dart';
import '../../prestamos/presentation/actividad_page.dart';
import '../../prestamos/presentation/prestamos_controller.dart';
import '../../recursos/domain/entities/recurso.dart';
import '../../recursos/presentation/equipos_page.dart';
import '../../recursos/presentation/recursos_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../salones/presentation/salones_page.dart';
import '../../salones_admin/presentation/panel_salones_page.dart';
import 'home_page.dart';

/// Contenedor con la barra inferior flotante en forma de píldora (Inicio · Equipos · Salones · Actividad · Cuenta).
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final RecursosController _recursos = sl<RecursosController>();
  final PrestamosController _prestamos = sl<PrestamosController>();

  int _indice = 0;

  /// Filtro inicial que la pestaña Actividad debe mostrar al abrirse desde el inicio.
  int _filtroActividad = 0;

  @override
  void initState() {
    super.initState();
    _recursos.cargar();
    _prestamos.cargar();
  }

  void _ir(int i) => setState(() => _indice = i);

  void _verEquipos({
    CategoriaRecurso? categoria,
    EstadoRecurso? estado,
    String? busqueda,
  }) {
    _recursos.limpiarFiltros();
    if (categoria != null) _recursos.fijarCategoria(categoria);
    if (estado != null) _recursos.fijarEstado(estado);
    if (busqueda != null) _recursos.fijarBusqueda(busqueda);
    _ir(1);
  }

  void _verActividad({int filtro = 0}) {
    setState(() {
      _filtroActividad = filtro;
      _indice = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _indice,
        children: [
          HomePage(
            onVerEquipos: _verEquipos,
            onIrAEquipos: () => _ir(1),
            onVerActividad: _verActividad,
          ),
          const EquiposPage(),
          // El auxiliar administra los salones; el usuario UTB los consulta y solicita.
          sl<AuthController>().esAdministrador
              ? const PanelSalonesPage()
              : const SalonesPage(),
          ActividadPage(filtroInicial: _filtroActividad),
          const CuentaPage(),
        ],
      ),
      bottomNavigationBar: _BarraPildora(indice: _indice, onTap: _ir),
    );
  }
}

class _BarraPildora extends StatelessWidget {
  const _BarraPildora({required this.indice, required this.onTap});
  final int indice;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.devices_other_rounded, 'Equipos'),
    (Icons.meeting_room_rounded, 'Salones'),
    (Icons.receipt_long_rounded, 'Actividad'),
    (Icons.person_rounded, 'Cuenta'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 74,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.fondo.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: i == indice ? AppColors.superficieAlta : Colors.transparent,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _items[i].$1,
                            size: 24,
                            color: i == indice ? AppColors.texto : AppColors.textoSuave,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
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
    );
  }
}

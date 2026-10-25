import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../admin/presentation/panel_administrativo_page.dart';
import '../../auth/presentation/auth_controller.dart';

class CuentaPage extends StatefulWidget {
  const CuentaPage({super.key});

  @override
  State<CuentaPage> createState() => _CuentaPageState();
}

class _CuentaPageState extends State<CuentaPage> {
  final AuthController _auth = sl<AuthController>();

  @override
  void initState() {
    super.initState();
    _auth.comprobarServidor();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final u = _auth.usuario;
          if (u == null) return const SizedBox.shrink();
          final inicial = u.nombre.isEmpty ? '?' : u.nombre.substring(0, 1).toUpperCase();
          final ok = _auth.servidorOk;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
            children: [
              const Text('Cuenta',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.superficieAlta,
                    child: Text(inicial,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text(u.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textoSuave)),
                        const SizedBox(height: 8),
                        Insignia(
                          texto: u.rolLegible,
                          color: u.esAdministrador
                              ? AppColors.mantenimiento
                              : AppColors.neutro,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (u.esAdministrador) ...[
                TarjetaBorde(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PanelAdministrativoPage(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.mantenimiento.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.mantenimiento,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Administrativo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gestionar usuarios y asignación de roles',
                              style: TextStyle(
                                color: AppColors.textoSuave,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textoSuave),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TarjetaBorde(
                onTap: _auth.comprobarServidor,
                child: Row(
                  children: [
                    Icon(
                      ok == true ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                      color: ok == null
                          ? AppColors.neutro
                          : ok
                              ? AppColors.disponible
                              : AppColors.danado,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ok == null
                                ? 'Comprobando servidor…'
                                : ok
                                    ? 'Servidor conectado'
                                    : 'Sin respuesta del servidor',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(ApiConfig.baseUrl,
                              style: const TextStyle(
                                  color: AppColors.textoSuave, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.refresh, color: AppColors.textoSuave),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.superficie,
                    title: const Text('¿Cerrar sesión?'),
                    content: const Text('Tendrás que iniciar sesión de nuevo.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _auth.cerrarSesion();
                        },
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('UTB Tracker · v1.0.0',
                    style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }
}

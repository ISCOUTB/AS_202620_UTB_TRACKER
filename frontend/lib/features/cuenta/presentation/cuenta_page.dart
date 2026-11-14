import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../admin/presentation/panel_administrativo_page.dart';
import '../../auditoria/auditoria_page.dart';
import '../../auth/domain/auth_domain.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../recursos/presentation/equipos_page.dart';
import '../../recursos/presentation/mantenimiento_page.dart';

/// Perfil: credencial digital (como el carnet de UTB App) y accesos según el rol.
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

  void _abrir(Widget pagina) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final u = _auth.usuario;
        if (u == null) return const SizedBox.shrink();
        final ok = _auth.servidorOk;
        var orden = 0;
        return ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            EncabezadoDegradado(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text('Perfil',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  Aparecer(child: _Credencial(usuario: u)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (u.esAdministrador) ...[
                    const TituloSeccion('Herramientas', subtitulo: 'Control del campus'),
                    const SizedBox(height: 12),
                    Aparecer(
                      orden: orden++,
                      child: _Opcion(
                        icono: Icons.devices_other_rounded,
                        color: AppColors.primarioClaro,
                        titulo: 'Inventario de equipos',
                        detalle: 'Equipos fijos de cada salón y su estado',
                        onTap: () => _abrir(const EquiposPage()),
                      ),
                    ),
                    Aparecer(
                      orden: orden++,
                      child: _Opcion(
                        icono: Icons.build_rounded,
                        color: AppColors.mantenimiento,
                        titulo: 'Mantenimiento',
                        detalle: 'Órdenes de reparación de equipos',
                        onTap: () => _abrir(const MantenimientoPage()),
                      ),
                    ),
                    Aparecer(
                      orden: orden++,
                      child: _Opcion(
                        icono: Icons.history_rounded,
                        color: AppColors.prestado,
                        titulo: 'Auditoría',
                        detalle: 'Quién hizo qué y cuándo',
                        onTap: () => _abrir(const AuditoriaPage()),
                      ),
                    ),
                    Aparecer(
                      orden: orden++,
                      child: _Opcion(
                        icono: Icons.admin_panel_settings_rounded,
                        color: AppColors.indigoClaro,
                        titulo: 'Usuarios y roles',
                        detalle: 'Gestionar cuentas y asignar roles',
                        onTap: () => _abrir(const PanelAdministrativoPage()),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const TituloSeccion('Cuenta'),
                  const SizedBox(height: 12),
                  Aparecer(
                    orden: orden++,
                    child: _Opcion(
                      icono: ok == true ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: ok == null
                          ? AppColors.neutro
                          : ok
                              ? AppColors.disponible
                              : AppColors.danado,
                      titulo: ok == null
                          ? 'Comprobando servidor…'
                          : ok
                              ? 'Servidor conectado'
                              : 'Sin respuesta del servidor',
                      detalle: ApiConfig.baseUrl,
                      onTap: _auth.comprobarServidor,
                    ),
                  ),
                  Aparecer(
                    orden: orden++,
                    child: _Opcion(
                      icono: Icons.sync_rounded,
                      color: AppColors.textoSuave,
                      titulo: 'Actualizar datos',
                      detalle: 'Vuelve a leer tu perfil del servidor',
                      onTap: () async {
                        final listo = await _auth.actualizarPerfil();
                        if (!context.mounted) return;
                        if (listo) mostrarMensaje(context, 'Perfil actualizado');
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  BotonPildora(
                    texto: 'Cerrar sesión',
                    icono: Icons.logout_rounded,
                    estilo: EstiloBoton.peligro,
                    onPressed: () => _confirmarSalida(context),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text('UTB Tracker · Campus Tecnológico',
                        style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarSalida(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que iniciar sesión de nuevo.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _auth.cerrarSesion();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

/// Credencial digital, inspirada en el carnet de UTB App: tarjeta clara inclinada levemente,
/// con avatar, nombre, correo y franja del rol.
class _Credencial extends StatelessWidget {
  const _Credencial({required this.usuario});
  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.025,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF1FF), Color(0xFFC9D8FF)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: 74,
                  height: 88,
                  decoration: const BoxDecoration(gradient: AppColors.degradado),
                  alignment: Alignment.center,
                  child: Text(
                    AvatarIniciales.iniciales(usuario.nombre),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.esAdministrador ? 'CREDENCIAL DE PERSONAL' : 'CREDENCIAL UTB',
                    style: const TextStyle(
                      color: Color(0xFF1B2D86),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    usuario.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F1B4D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    usuario.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF3B4A7A), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2D86),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      usuario.rolLegible.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TarjetaBorde(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.08)],
                ),
              ),
              child: Icon(icono, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textoTenue),
          ],
        ),
      ),
    );
  }
}

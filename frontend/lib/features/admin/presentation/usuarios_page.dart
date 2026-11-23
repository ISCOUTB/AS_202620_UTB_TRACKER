import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/foto_perfil.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../salones_admin/presentation/salones_admin_estilos.dart';
import '../data/admin_data.dart';
import 'admin_controllers.dart';

Color colorDeRol(String rol) => switch (rol) {
      RolUsuario.administrador => AppColors.indigoClaro,
      RolUsuario.auditor => AppColors.mantenimiento,
      _ => AppColors.textoSuave,
    };

/// USUARIOS (solo Administrador, ADR-0018): buscar, filtrar por rol, cambiar el rol con
/// confirmación, activar/desactivar y ver la última actividad.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key, this.controller});
  final UsuariosController? controller;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late final UsuariosController _c = widget.controller ?? sl<UsuariosController>();

  int? get _miId => sl.isRegistered<AuthController>() ? sl<AuthController>().usuario?.id : null;

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: si esta pantalla aparece mientras otra aún se dibuja
    // (cambio de pestaña o de rol en el modo prueba), no se avisa a mitad del build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.cargar();
    });
  }

  Future<void> _abrir(UsuarioAdmin u) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaUsuario(usuario: u, controller: _c, esYo: u.id == _miId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConPermiso(
        permiso: Permisos.usuariosGestionar,
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
                        child: Text('Usuarios',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 0, 12),
                        child: Text('Roles y acceso de cada cuenta',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onSubmitted: _c.buscar,
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Buscar por nombre o correo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      for (final (valor, etiqueta) in [
                        (null, 'Todos'),
                        for (final r in sl<AuthController>().roles) (r.valor, r.etiqueta),
                      ]) ...[
                        ChoiceChip(
                          label: Text(etiqueta),
                          selected: _c.rol == valor,
                          onSelected: (_) => _c.filtrarRol(valor),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _cuerpo()),
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
        if (_c.usuarios.isEmpty) {
          return const VistaVacia(
              mensaje: 'Nadie coincide', detalle: 'Prueba con otro nombre, correo o rol.');
        }
        return Column(
          children: [
            for (final u in _c.usuarios) ...[
              _FilaUsuario(usuario: u, esYo: u.id == _miId, onTap: () => _abrir(u)),
              const SizedBox(height: 8),
            ],
          ],
        );
    }
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario, required this.esYo, required this.onTap});
  final UsuarioAdmin usuario;
  final bool esYo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    final actividad = u.ultimaActividad == null
        ? 'Sin actividad registrada'
        : 'Activo ${haceCuanto(u.ultimaActividad!)}';
    return Semantics(
      button: true,
      label: '${u.nombreVisible}, ${u.rolEtiqueta}${u.activo ? '' : ', desactivado'}',
      child: TarjetaBorde(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            FotoOIniciales(
              usuarioId: u.id,
              fotoVersion: u.fotoVersion,
              tamano: 38,
              respaldo: CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.superficieAlta,
                child: Text(u.nombreVisible.isEmpty ? '?' : u.nombreVisible[0].toUpperCase(),
                    style: TextStyle(color: colorDeRol(u.rol), fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(esYo ? '${u.nombreVisible} (tú)' : u.nombreVisible,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: u.activo ? AppColors.texto : AppColors.textoTenue)),
                  Text(u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5)),
                  Text(u.activo ? actividad : 'Desactivado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: u.activo ? AppColors.textoTenue : AppColors.danado,
                          fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Insignia(texto: u.rolEtiqueta, color: colorDeRol(u.rol)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HojaUsuario extends StatelessWidget {
  const _HojaUsuario({required this.usuario, required this.controller, required this.esYo});
  final UsuarioAdmin usuario;
  final UsuariosController controller;
  final bool esYo;

  Future<void> _cambiarRol(BuildContext context, String rol) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Hacer ${sl<AuthController>().etiquetaDe(rol)} a ${usuario.nombreVisible}?'),
        content: Text('${sl<AuthController>().descripcionDe(rol)}. Queda como rol manual (la lista de roles '
            'por correo no lo cambia) y se cerrarán sus sesiones abiertas para que aplique ya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: const Text('Cambiar rol')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await controller.cambiarRol(usuario, rol);
    if (!context.mounted) return;
    Navigator.pop(context);
    mostrarMensaje(context, error ?? 'Ahora es ${sl<AuthController>().etiquetaDe(rol)}');
  }

  Future<void> _cambiarEstado(BuildContext context) async {
    final activar = !usuario.activo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activar ? '¿Activar la cuenta?' : '¿Desactivar la cuenta?'),
        content: Text(activar
            ? '${usuario.nombreVisible} podrá volver a entrar.'
            : '${usuario.nombreVisible} no podrá entrar y sus sesiones se cerrarán. '
                'Sus datos se conservan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(activar ? 'Activar' : 'Desactivar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await controller.cambiarEstado(usuario, activo: activar);
    if (!context.mounted) return;
    Navigator.pop(context);
    mostrarMensaje(context, error ?? (activar ? 'Cuenta activada' : 'Cuenta desactivada'));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(usuario.nombreVisible,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(usuario.email, style: const TextStyle(color: AppColors.textoSuave)),
            if (usuario.dependencia != null)
              Text(usuario.dependencia!, style: const TextStyle(color: AppColors.textoTenue)),
            const SizedBox(height: 14),
            if (esYo)
              const Text(
                'Es tu cuenta: tu rol y tu estado los cambia otro administrador (así nunca '
                'queda la app sin administrador).',
                style: TextStyle(color: AppColors.textoSuave),
              )
            else ...[
              const Text('Rol', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final rol in sl<AuthController>().roles.map((r) => r.valor))
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      rol == usuario.rol
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: rol == usuario.rol ? AppColors.primarioClaro : AppColors.textoTenue,
                    ),
                    title: Text(sl<AuthController>().etiquetaDe(rol)),
                    subtitle: Text(sl<AuthController>().descripcionDe(rol)),
                    onTap: rol == usuario.rol ? null : () => _cambiarRol(context, rol),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: usuario.activo ? AppColors.danado : AppColors.disponible,
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => _cambiarEstado(context),
                icon: Icon(usuario.activo ? Icons.block_rounded : Icons.check_circle_rounded),
                label: Text(usuario.activo ? 'Desactivar cuenta' : 'Activar cuenta'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

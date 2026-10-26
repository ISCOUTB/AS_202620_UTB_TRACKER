import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/auth_domain.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_usuarios_controller.dart';

class PanelAdministrativoPage extends StatefulWidget {
  const PanelAdministrativoPage({super.key});

  @override
  State<PanelAdministrativoPage> createState() => _PanelAdministrativoPageState();
}

class _PanelAdministrativoPageState extends State<PanelAdministrativoPage> {
  final AdminUsuariosController _controller = sl<AdminUsuariosController>();
  final AuthController _auth = sl<AuthController>();
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirCambiarRol(Usuario usuario) async {
    String rolSeleccionado = usuario.esAdministrador ? 'administrador' : 'usuario_utb';
    final esUsuarioActual = usuario.id == _auth.usuario?.id;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borde,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Asignar Rol a ${usuario.nombre}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
                    ),
                    if (esUsuarioActual) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.prestado.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.prestado.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.prestado, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estás modificando tu propio rol en el sistema.',
                                style: TextStyle(color: AppColors.prestado, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Selecciona el nuevo rol:',
                        style: TextStyle(color: AppColors.textoSuave)),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'usuario_utb',
                          label: Text('Usuario UTB'),
                        ),
                        ButtonSegment(
                          value: 'administrador',
                          label: Text('Auxiliar / Admin'),
                        ),
                      ],
                      selected: {rolSeleccionado},
                      onSelectionChanged: (s) =>
                          setModalState(() => rolSeleccionado = s.first),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final exito = await _controller.cambiarRol(
                          usuarioId: usuario.id,
                          nuevoRol: rolSeleccionado,
                        );
                        if (!mounted) return;
                        if (exito) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rol de ${usuario.nombre} actualizado a '
                                '${rolSeleccionado == 'administrador' ? 'Auxiliar' : 'Usuario UTB'}.',
                              ),
                            ),
                          );
                          // Si modificó su propia cuenta, actualizar auth controller
                          if (esUsuarioActual) {
                            await _auth.restaurarSesion();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danado,
                              content: Text(
                                _controller.error ?? 'Error al actualizar rol',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final usuarios = _controller.filtrados;
            final cargando = _controller.cargando;
            final error = _controller.error;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    controller: _busquedaCtrl,
                    onChanged: _controller.fijarBusqueda,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o correo…',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textoSuave),
                      suffixIcon: _busquedaCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textoSuave),
                              onPressed: () {
                                _busquedaCtrl.clear();
                                _controller.fijarBusqueda('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
                          selected: _controller.filtroRol == null,
                          onSelected: (_) => _controller.fijarFiltroRol(null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Usuarios UTB'),
                          selected: _controller.filtroRol == 'usuario_utb',
                          onSelected: (_) => _controller.fijarFiltroRol('usuario_utb'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Auxiliares / Admin'),
                          selected: _controller.filtroRol == 'auxiliar',
                          onSelected: (_) => _controller.fijarFiltroRol('auxiliar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _controller.cargar,
                    child: cargando && usuarios.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : error != null && usuarios.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 48, color: AppColors.danado),
                                      const SizedBox(height: 12),
                                      Text(error, textAlign: TextAlign.center),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: _controller.cargar,
                                        child: const Text('Reintentar'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : usuarios.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No se encontraron usuarios.',
                                      style: TextStyle(color: AppColors.textoSuave),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                    itemCount: usuarios.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final u = usuarios[i];
                                      final inicial = u.nombre.isEmpty
                                          ? '?'
                                          : u.nombre.substring(0, 1).toUpperCase();
                                      final esYo = u.id == _auth.usuario?.id;

                                      return TarjetaBorde(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: AppColors.superficieAlta,
                                              child: Text(
                                                inicial,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          u.nombre,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      if (esYo)
                                                        const Text(
                                                          ' (Tú)',
                                                          style: TextStyle(
                                                            color: AppColors.textoSuave,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    u.email,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors.textoSuave,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Insignia(
                                                    texto: u.rolLegible,
                                                    color: u.esAdministrador
                                                        ? AppColors.mantenimiento
                                                        : AppColors.neutro,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(80, 36),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                ),
                                              ),
                                              onPressed: () => _abrirCambiarRol(u),
                                              child: const Text(
                                                'Rol',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/politica.dart';
import '../../../shared/foto_perfil.dart';
import '../../../shared/servidor.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../admin/presentation/estadisticas_page.dart';
import '../../admin/presentation/asignaciones_page.dart';
import '../../admin/presentation/usuarios_page.dart';
import '../../auditoria/auditoria_page.dart';
import '../../auth/domain/auth_domain.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/cambiar_correo_sheet.dart';
import '../../recursos/presentation/equipos_page.dart';
import '../../recursos/presentation/mantenimiento_page.dart';
import '../../salones_admin/presentation/catalogo_page.dart';
import 'foto_perfil_sheet.dart';

/// Versión mostrada en el perfil (la de pubspec.yaml).
const String versionApp = '0.1.1';

/// Colores que se pueden elegir para el avatar (todos de [AppColors]).
const List<Color> coloresAvatar = [
  AppColors.primario,
  AppColors.indigo,
  AppColors.disponible,
  AppColors.prestado,
  AppColors.danado,
  AppColors.mantenimiento,
];

String hexDe(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color? colorDeHex(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
}

/// Perfil (ADR-0016, ADR-0019, ADR-0020): cabecera con foto, rol de solo lectura, datos
/// personales, seguridad, preferencias, servidor y cuenta. Todo se guarda en el servidor.
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
    _auth.actualizarPerfil();
  }

  void _abrir(Widget pagina) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));

  /// Muestra el aviso o el error de la última acción y lo limpia.
  void _resultado(bool ok) {
    if (!mounted) return;
    final texto = ok ? _auth.aviso : _auth.error;
    if (texto != null) mostrarMensaje(context, texto);
    ok ? _auth.limpiarAviso() : _auth.limpiarError();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final u = _auth.usuario;
        if (u == null) return const SizedBox.shrink();
        final p = u.preferencias;
        final permisos = _auth.permisos;
        return RefreshIndicator(
          onRefresh: _auth.actualizarPerfil,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 130),
            children: [
              EncabezadoDegradado(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                child: _Cabecera(usuario: u, onFoto: () => mostrarHojaFoto(context)),
              ),
              if (_auth.cargando) const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!u.correoInstitucional)
                      _AvisoCorreoAntiguo(
                          correo: u.email, onCambiar: () => mostrarCambiarCorreo(context)),
                    const _Titulo('Tu rol'),
                    _RolSoloLectura(usuario: u),
                    // Lo que se muestra depende de los PERMISOS (ADR-0018), nunca del texto del rol.
                    if (_auth.permisosReales.puede(Permisos.modoPrueba))
                      _ModoPrueba(auth: _auth),
                    if (permisos.puede(Permisos.equiposGestionar)) ...[
                      const _Titulo('Herramientas'),
                      _Fila(
                        icono: Icons.devices_other_rounded,
                        color: AppColors.primarioClaro,
                        titulo: 'Inventario de equipos',
                        onTap: () => _abrir(const EquiposPage()),
                      ),
                      _Fila(
                        icono: Icons.build_rounded,
                        color: AppColors.mantenimiento,
                        titulo: 'Mantenimiento',
                        onTap: () => _abrir(const MantenimientoPage()),
                      ),
                    ],
                    if (permisos.puede(Permisos.usuariosGestionar) ||
                        permisos.puede(Permisos.salonesCrearCatalogo) ||
                        permisos.puede(Permisos.auditoriaVer) ||
                        permisos.puede(Permisos.estadisticasVer)) ...[
                      const _Titulo('Administración'),
                      if (permisos.puede(Permisos.usuariosGestionar))
                        _Fila(
                          icono: Icons.admin_panel_settings_rounded,
                          color: AppColors.indigoClaro,
                          titulo: 'Usuarios y roles',
                          detalle: 'Cambiar roles, activar o desactivar cuentas',
                          onTap: () => _abrir(const UsuariosPage()),
                        ),
                      if (permisos.puede(Permisos.usuariosGestionar))
                        _Fila(
                          icono: Icons.alternate_email_rounded,
                          color: AppColors.mantenimiento,
                          titulo: 'Roles por correo',
                          detalle: 'Quién es Auditor o Administrador según su correo',
                          onTap: () => _abrir(const AsignacionesPage()),
                        ),
                      if (permisos.puede(Permisos.salonesCrearCatalogo))
                        _Fila(
                          icono: Icons.apartment_rounded,
                          color: AppColors.primarioClaro,
                          titulo: 'Catálogo de salones',
                          detalle: 'Crear, crear varios por piso y desactivar',
                          onTap: () => _abrir(const CatalogoPage()),
                        ),
                      if (permisos.puede(Permisos.estadisticasVer))
                        _Fila(
                          icono: Icons.insights_rounded,
                          color: AppColors.disponible,
                          titulo: 'Estadísticas',
                          detalle: 'Uso de salones, solicitudes y reportes',
                          onTap: () => _abrir(const EstadisticasPage()),
                        ),
                      if (permisos.puede(Permisos.auditoriaVer))
                        _Fila(
                          icono: Icons.history_rounded,
                          color: AppColors.prestado,
                          titulo: 'Bitácora de auditoría',
                          detalle: 'Quién hizo qué y cuándo',
                          onTap: () => _abrir(const AuditoriaPage()),
                        ),
                    ],
                    const _Titulo('Datos personales'),
                    _Fila(
                      icono: Icons.account_circle_rounded,
                      color: AppColors.primarioClaro,
                      titulo: 'Foto de perfil',
                      detalle: u.tieneFoto
                          ? 'Toca para cambiarla o quitarla'
                          : 'Sin foto (se ven tus iniciales)',
                      onTap: () => mostrarHojaFoto(context),
                    ),
                    _Fila(
                      icono: Icons.badge_rounded,
                      color: AppColors.primarioClaro,
                      titulo: 'Nombre para mostrar',
                      detalle: u.nombreMostrar ?? 'Sin definir (se usa ${u.nombre})',
                      onTap: () => _editarDatos(u),
                    ),
                    _Fila(
                      icono: Icons.phone_rounded,
                      color: AppColors.primarioClaro,
                      titulo: 'Teléfono',
                      detalle: u.telefono ?? 'Sin definir',
                      onTap: () => _editarDatos(u),
                    ),
                    // Si el cargo viene de la lista de roles por correo, no se edita aquí.
                    if (u.cargo == null)
                      _Fila(
                        icono: Icons.apartment_rounded,
                        color: AppColors.primarioClaro,
                        titulo: 'Dependencia o cargo',
                        detalle: u.dependencia ?? 'Sin definir',
                        onTap: () => _editarDatos(u),
                      ),
                    const _Titulo('Seguridad'),
                    _Fila(
                      icono: Icons.alternate_email_rounded,
                      color: AppColors.indigoClaro,
                      titulo: 'Cambiar correo',
                      detalle: '${u.email} · solo correos @${Politica.dominioInstitucional}',
                      onTap: () => mostrarCambiarCorreo(context),
                    ),
                    _Fila(
                      icono: Icons.password_rounded,
                      color: AppColors.indigoClaro,
                      titulo: 'Cambiar contraseña',
                      detalle: 'Cierra las sesiones en otros dispositivos',
                      onTap: () => _cambiarPassword(u),
                    ),
                    _Fila(
                      icono: Icons.devices_rounded,
                      color: AppColors.indigoClaro,
                      titulo: 'Cerrar las demás sesiones',
                      detalle: 'Este dispositivo sigue conectado',
                      onTap: () => _confirmar(
                        titulo: '¿Cerrar las demás sesiones?',
                        texto: 'Se cerrará tu sesión en todos los demás celulares y navegadores.',
                        accion: 'Cerrar sesiones',
                        alAceptar: () async => _resultado(await _auth.cerrarOtrasSesiones()),
                      ),
                    ),
                    const _Titulo('Preferencias'),
                    _Seccion(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tamaño del texto',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          SegmentedButton<TamanoTexto>(
                            showSelectedIcon: false,
                            segments: [
                              for (final t in TamanoTexto.values)
                                ButtonSegment(value: t, label: Text(t.etiqueta)),
                            ],
                            selected: {p.tamanoTexto},
                            onSelectionChanged: _auth.cargando
                                ? null
                                : (s) => _auth.guardarPreferencias(p.conTamano(s.first)),
                          ),
                          const SizedBox(height: 14),
                          const Text('Avisos', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Text(
                            'Los de seguridad (contraseña, correo) siempre llegan.',
                            style: TextStyle(color: AppColors.textoTenue, fontSize: 12),
                          ),
                          for (final canal in CanalAviso.values)
                            for (final cat in CategoriaAviso.values)
                              SwitchListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(cat.etiqueta),
                                subtitle: Text(canal.etiqueta),
                                value: p.aviso(canal, cat),
                                onChanged: _auth.cargando
                                    ? null
                                    : (v) => _auth.guardarPreferencias(p.conAviso(canal, cat, v)),
                              ),
                          if (permisos.opera) ...[
                            const SizedBox(height: 6),
                            const Text('Abrir la app en',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 'inicio', label: Text('Inicio')),
                                ButtonSegment(value: 'salones', label: Text('Salones')),
                                ButtonSegment(value: 'control', label: Text('Control')),
                              ],
                              selected: {p.pantallaInicio},
                              onSelectionChanged: _auth.cargando
                                  ? null
                                  : (s) => _auth.guardarPreferencias(p.conPantallaInicio(s.first)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const _Titulo('Servidor y versión'),
                    _Seccion(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ApiConfig.describir(),
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(ApiConfig.baseUrl,
                                    style: const TextStyle(color: AppColors.textoTenue, fontSize: 12)),
                                const SizedBox(height: 4),
                                const Text('App $versionApp',
                                    style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
                              ],
                            ),
                          ),
                          const InsigniaServidor(compacta: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BotonPildora(
                      texto: 'Cerrar sesión',
                      icono: Icons.logout_rounded,
                      estilo: EstiloBoton.secundario,
                      onPressed: () => _confirmar(
                        titulo: '¿Cerrar sesión?',
                        texto: 'Tendrás que iniciar sesión de nuevo en este dispositivo.',
                        accion: 'Cerrar sesión',
                        alAceptar: () async => _auth.cerrarSesion(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _desactivar(context),
                      icon: const Icon(Icons.no_accounts_rounded, color: AppColors.danado),
                      label: const Text('Desactivar mi cuenta',
                          style: TextStyle(color: AppColors.danado)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────

  Future<void> _editarDatos(Usuario u) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditarDatosSheet(usuario: u),
    );
    if (guardado == true) _resultado(true);
  }

  Future<void> _cambiarPassword(Usuario u) async {
    final form = GlobalKey<FormState>();
    final actual = TextEditingController();
    final nueva = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: ListenableBuilder(
          listenable: _auth,
          builder: (ctx, _) => Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Cambiar contraseña',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: actual,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  validator: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña actual' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nueva,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Contraseña nueva'),
                  validator: (v) => Politica.errorPassword(v ?? '', correo: u.email, nombre: u.nombre),
                ),
                if (_auth.error != null) ...[
                  const SizedBox(height: 10),
                  Text(_auth.error!, style: const TextStyle(color: AppColors.danado)),
                ],
                const SizedBox(height: 14),
                BotonPildora(
                  texto: 'Guardar',
                  cargando: _auth.cargando,
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    final listo = await _auth.cambiarPassword(actual.text, nueva.text);
                    if (listo && ctx.mounted) Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    actual.dispose();
    nueva.dispose();
    ok == true ? _resultado(true) : _auth.limpiarError();
  }

  Future<void> _desactivar(BuildContext context) async {
    final clave = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danado),
        title: const Text('¿Desactivar tu cuenta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No podrás volver a entrar. Tus solicitudes y registros se conservan. Solo un '
              'administrador puede reactivarla.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clave,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Tu contraseña para confirmar'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar', style: TextStyle(color: AppColors.danado)),
          ),
        ],
      ),
    );
    final texto = clave.text;
    clave.dispose();
    if (confirmado != true) return;
    final ok = await _auth.desactivarCuenta(texto);
    if (!ok) _resultado(false);
  }

  void _confirmar({
    required String titulo,
    required String texto,
    required String accion,
    required Future<void> Function() alAceptar,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              alAceptar();
            },
            child: Text(accion),
          ),
        ],
      ),
    );
  }
}

// ── Piezas ───────────────────────────────────────────────────────────────

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.usuario, required this.onFoto});
  final Usuario usuario;
  final VoidCallback onFoto;

  @override
  Widget build(BuildContext context) {
    final verificado = usuario.emailVerificado;
    return Row(
      children: [
        Semantics(
          button: true,
          label: usuario.tieneFoto
              ? 'Tu foto de perfil. Toca para cambiarla o quitarla.'
              : 'Tus iniciales. Toca para poner una foto de perfil.',
          excludeSemantics: true,
          child: InkWell(
            onTap: onFoto,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 70,
              height: 68,
              child: Stack(
                children: [
                  AvatarPerfil(usuario: usuario, tamano: 64),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primario,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.photo_camera_rounded, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usuario.nombreVisible,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(usuario.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    icono: verificado ? Icons.verified_rounded : Icons.mark_email_unread_rounded,
                    texto: verificado ? 'Verificado' : 'Sin verificar',
                    color: verificado ? AppColors.disponible : AppColors.prestado,
                  ),
                  _Chip(
                    icono: Icons.badge_outlined,
                    texto: usuario.rolEtiqueta,
                    color: AppColors.indigoClaro,
                  ),
                  if (usuario.cargo != null)
                    _Chip(
                      icono: Icons.work_outline_rounded,
                      texto: usuario.cargo!,
                      color: AppColors.mantenimiento,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Avatar del usuario conectado: su foto, o sus iniciales con el color que eligió.
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, required this.usuario, this.tamano = 64});
  final Usuario usuario;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = colorDeHex(usuario.colorAvatar) ?? AppColors.primario;
    final interior = tamano - 4;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
      ),
      child: FotoOIniciales(
        usuarioId: usuario.id,
        fotoVersion: usuario.tieneFoto ? usuario.fotoVersion : 0,
        tamano: interior,
        propia: true,
        respaldo: Text(
          AvatarIniciales.iniciales(usuario.nombreVisible),
          style: TextStyle(
              fontSize: tamano * 0.37, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}

/// El rol NO se elige (ADR-0019): se muestra de dónde viene y cómo pedir un cambio.
class _RolSoloLectura extends StatelessWidget {
  const _RolSoloLectura({required this.usuario});
  final Usuario usuario;

  String get _origen {
    final texto = usuario.rolOrigenTexto;
    if (texto != null && texto.isNotEmpty) return texto;
    return switch (usuario.rolOrigen) {
      'correo' => 'Asignado por tu correo institucional',
      'manual' => 'Asignado por un administrador',
      _ => 'Eres estudiante. Si trabajas en la UTB y necesitas otro rol, pídeselo a un '
          'administrador.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final icono = switch (usuario.rolOrigen) {
      'correo' => Icons.alternate_email_rounded,
      'manual' => Icons.admin_panel_settings_rounded,
      _ => Icons.school_rounded,
    };
    return Semantics(
      label: 'Tu rol: ${usuario.rolEtiqueta}. $_origen'
          '${usuario.cargo == null ? '' : '. Cargo: ${usuario.cargo}'}',
      excludeSemantics: true,
      child: _Seccion(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: AppColors.indigoClaro, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.rolEtiqueta,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (usuario.cargo != null)
                    Text(usuario.cargo!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(_origen,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textoTenue),
          ],
        ),
      ),
    );
  }
}

/// Cuenta antigua con correo que no es de la UTB: sigue entrando, pero se le pide pasarse al
/// institucional (con verificación al correo nuevo).
class _AvisoCorreoAntiguo extends StatelessWidget {
  const _AvisoCorreoAntiguo({required this.correo, required this.onCambiar});
  final String correo;
  final VoidCallback onCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.prestado.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.prestado.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.prestado, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tu correo no es institucional',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tu cuenta usa $correo. Cámbialo a tu correo de la UTB '
              '(${Politica.ejemploCorreo}): te enviaremos un enlace para confirmar que es tuyo.',
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCambiar,
                icon: const Icon(Icons.alternate_email_rounded),
                label: const Text('Cambiar a mi correo institucional'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icono, required this.texto, required this.color});
  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Semantics(
        header: true,
        child: Text(texto.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textoTenue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1)),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      TarjetaBorde(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: child);
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.onTap,
    this.detalle,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String? detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TarjetaBorde(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  if (detalle != null)
                    Text(detalle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5)),
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

/// Hoja para editar nombre para mostrar, teléfono, dependencia y color del avatar.
class _EditarDatosSheet extends StatefulWidget {
  const _EditarDatosSheet({required this.usuario});
  final Usuario usuario;

  @override
  State<_EditarDatosSheet> createState() => _EditarDatosSheetState();
}

class _EditarDatosSheetState extends State<_EditarDatosSheet> {
  final _auth = sl<AuthController>();
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario.nombreMostrar ?? '');
  late final _telefono = TextEditingController(text: widget.usuario.telefono ?? '');
  late final _dependencia = TextEditingController(text: widget.usuario.dependencia ?? '');
  late String? _color = widget.usuario.colorAvatar;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _dependencia.dispose();
    _auth.limpiarError();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final ok = await _auth.guardarPerfil({
      'nombre_mostrar': _nombre.text.trim(),
      'telefono': _telefono.text.trim(),
      if (widget.usuario.cargo == null) 'dependencia': _dependencia.text.trim(),
      'color_avatar': _color ?? '',
    }, avisoOk: 'Datos guardados');
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) => Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Datos personales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Nombre para mostrar',
                  hintText: widget.usuario.nombre,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  return RegExp(r'^[0-9+()\- ]{7,20}$').hasMatch(t)
                      ? null
                      : 'Usa solo números, espacios, +, - o paréntesis';
                },
              ),
              if (widget.usuario.cargo == null) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dependencia,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Dependencia o cargo (opcional)',
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Color del avatar', style: TextStyle(fontWeight: FontWeight.w700)),
              const Text('Se usa cuando no tienes foto.',
                  style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final c in coloresAvatar)
                    Semantics(
                      button: true,
                      selected: _color == hexDe(c),
                      label: 'Color ${hexDe(c)}',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = hexDe(c)),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == hexDe(c) ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _color == hexDe(c)
                              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              if (_auth.error != null) ...[
                const SizedBox(height: 10),
                Text(_auth.error!, style: const TextStyle(color: AppColors.danado)),
              ],
              const SizedBox(height: 14),
              BotonPildora(texto: 'Guardar', cargando: _auth.cargando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}


/// Modo prueba (solo Administrador, ADR-0018): ver la app como Estudiante o Auditor. Cambia
/// la navegación y las pantallas; el servidor sigue aplicando el rol real. Se guarda solo en
/// este dispositivo.
class _ModoPrueba extends StatelessWidget {
  const _ModoPrueba({required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final actual = auth.vistaComo ?? auth.usuario?.rol ?? RolUsuario.administrador;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo('Modo prueba'),
        const Text(
          'Mira la app como la ve cada rol. Solo cambia lo que se muestra: tus permisos reales '
          'siguen siendo de administrador. Para probar de verdad lo que un rol NO puede hacer, '
          'entra con su cuenta de prueba.',
          style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final rol in RolUsuario.todos)
              ButtonSegment(value: rol, label: Text(RolUsuario.etiqueta(rol))),
          ],
          selected: {actual},
          onSelectionChanged: (s) => auth.verComo(s.first),
        ),
      ],
    );
  }
}

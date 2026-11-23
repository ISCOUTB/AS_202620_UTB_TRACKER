import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/politica.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../data/admin_data.dart';
import 'admin_controllers.dart';
import 'usuarios_page.dart' show colorDeRol;

/// ROLES POR CORREO (solo Administrador, ADR-0019). El correo @utb.edu.co no dice si alguien es
/// estudiante o personal: esta lista (correo EXACTO -> rol) lo decide. El rol solo se aplica
/// cuando la persona verifica su correo; un rol puesto a mano en Usuarios gana sobre la lista.
class AsignacionesPage extends StatefulWidget {
  const AsignacionesPage({super.key, this.controller});
  final AsignacionesController? controller;

  @override
  State<AsignacionesPage> createState() => _AsignacionesPageState();
}

class _AsignacionesPageState extends State<AsignacionesPage> {
  late final AsignacionesController _c = widget.controller ?? sl<AsignacionesController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.cargar();
    });
  }

  Future<void> _editar([AsignacionRol? a]) async {
    final mensaje = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaAsignacion(controller: _c, asignacion: a),
    );
    if (mensaje != null && mounted) mostrarMensaje(context, mensaje);
  }

  Future<void> _importar() async {
    final mensaje = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaImportar(controller: _c),
    );
    if (mensaje != null && mounted) mostrarMensaje(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar'),
      ),
      body: ConPermiso(
        permiso: Permisos.usuariosGestionar,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _c.cargar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                EncabezadoDegradado(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BackButton(),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _importar,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Importar lista'),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('Roles por correo',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 0, 12),
                        child: Text(
                            'Quién es Auditor o Administrador según su correo institucional. '
                            'Se aplica cuando la persona verifica su correo.',
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
                            hintText: 'Buscar por correo o cargo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _cuerpo()),
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
        if (_c.items.isEmpty) {
          return const VistaVacia(
            mensaje: 'Sin asignaciones',
            detalle: 'Agrega el correo institucional de cada auditor o administrador, o '
                'importa una lista.',
          );
        }
        return Column(
          children: [
            for (final a in _c.items) ...[
              _FilaAsignacion(asignacion: a, onTap: () => _editar(a)),
              const SizedBox(height: 8),
            ],
          ],
        );
    }
  }
}

class _FilaAsignacion extends StatelessWidget {
  const _FilaAsignacion({required this.asignacion, required this.onTap});
  final AsignacionRol asignacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = asignacion;
    final etiqueta = a.rolEtiqueta.isEmpty ? RolUsuario.etiqueta(a.rol) : a.rolEtiqueta;
    return Semantics(
      button: true,
      label: '${a.correo}, $etiqueta${a.cargo == null ? '' : ', ${a.cargo}'}',
      child: TarjetaBorde(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.alternate_email_rounded, color: colorDeRol(a.rol)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(a.cargo ?? 'Sin cargo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Insignia(texto: etiqueta, color: colorDeRol(a.rol)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Agregar o editar una fila. Al editar, el correo no cambia (se quita y se agrega otra).
class _HojaAsignacion extends StatefulWidget {
  const _HojaAsignacion({required this.controller, this.asignacion});
  final AsignacionesController controller;
  final AsignacionRol? asignacion;

  @override
  State<_HojaAsignacion> createState() => _HojaAsignacionState();
}

class _HojaAsignacionState extends State<_HojaAsignacion> {
  final _form = GlobalKey<FormState>();
  late final _correo = TextEditingController(text: widget.asignacion?.correo ?? '');
  late final _cargo = TextEditingController(text: widget.asignacion?.cargo ?? '');
  late String _rol = widget.asignacion?.rol ?? RolUsuario.auditor;
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.asignacion != null;

  @override
  void dispose() {
    _correo.dispose();
    _cargo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final cargo = _cargo.text.trim().isEmpty ? null : _cargo.text.trim();
    final error = _editando
        ? await widget.controller.editar(widget.asignacion!, _rol, cargo)
        : await widget.controller.crear(Politica.normalizarCorreo(_correo.text), _rol, cargo);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, _editando ? 'Asignación actualizada' : 'Asignación agregada');
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  Future<void> _quitar() async {
    final a = widget.asignacion!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar esta asignación?'),
        content: Text('Si ${a.correo} ya tiene cuenta y su rol venía de esta lista, pasará a '
            'Estudiante y se cerrarán sus sesiones.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _guardando = true);
    final error = await widget.controller.quitar(a);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, 'Asignación quitada');
    } else {
      setState(() {
        _guardando = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editando ? 'Editar asignación' : 'Agregar asignación',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                enabled: !_editando,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional exacto',
                  helperText: 'Ejemplo: ${Politica.ejemploCorreo}',
                ),
                validator: (v) => Politica.errorCorreoNuevo(v ?? ''),
              ),
              const SizedBox(height: 12),
              const Text('Rol', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              for (final rol in RolUsuario.todos)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  selected: rol == _rol,
                  leading: Icon(
                    rol == _rol
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: rol == _rol ? AppColors.primarioClaro : AppColors.textoTenue,
                  ),
                  onTap: _guardando ? null : () => setState(() => _rol = rol),
                  title: Text(RolUsuario.etiqueta(rol)),
                  subtitle: Text(RolUsuario.descripcion(rol)),
                ),
              TextFormField(
                controller: _cargo,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Cargo o dependencia (opcional)',
                  hintText: 'Auxiliar de planta',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: AppColors.danado)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: const Text('Guardar'),
              ),
              if (_editando) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danado),
                  onPressed: _guardando ? null : _quitar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Quitar asignación'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pegar una lista o un CSV: primero se REVISA (simular) y se muestran los errores por línea;
/// solo si no hay errores se puede aplicar (todo o nada).
class _HojaImportar extends StatefulWidget {
  const _HojaImportar({required this.controller});
  final AsignacionesController controller;

  @override
  State<_HojaImportar> createState() => _HojaImportarState();
}

class _HojaImportarState extends State<_HojaImportar> {
  final _texto = TextEditingController();
  ResultadoImportacion? _revision;
  bool _trabajando = false;
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _ejecutar({required bool simular}) async {
    setState(() {
      _trabajando = true;
      _error = null;
    });
    try {
      final r = await widget.controller.importar(_texto.text, simular: simular);
      if (!mounted) return;
      if (r.aplicado) {
        Navigator.pop(context,
            'Lista aplicada: ${r.creadas} nuevas, ${r.actualizadas} actualizadas');
        return;
      }
      setState(() => _revision = r);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.mensaje : 'No se pudo importar la lista');
      }
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _revision;
    final sePuedeAplicar = r != null && r.errores.isEmpty && r.validas > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Importar lista',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Una persona por línea: correo,rol,cargo (el cargo es opcional; también sirve '
              'punto y coma). Rol: Estudiante, Auditor o Administrador.',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _texto,
              minLines: 4,
              maxLines: 8,
              // Al cambiar el texto la revisión anterior deja de valer (y se activa "Revisar").
              onChanged: (_) => setState(() => _revision = null),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'ana.perez@utb.edu.co,Auditor,Auxiliar de planta',
              ),
            ),
            if (r != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  r.errores.isEmpty
                      ? '${r.validas} líneas correctas: ${r.creadas} nuevas, '
                          '${r.actualizadas} cambian, ${r.sinCambios} sin cambios.'
                      : 'Hay ${r.errores.length} líneas con errores. No se guardó nada.',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: r.errores.isEmpty ? AppColors.disponible : AppColors.danado),
                ),
              ),
              for (final (linea, error) in r.errores)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.danado),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(linea > 0 ? 'Línea $linea: $error' : error,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 12),
            if (sePuedeAplicar)
              FilledButton.icon(
                onPressed: _trabajando ? null : () => _ejecutar(simular: false),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Aplicar lista'),
              )
            else
              FilledButton.icon(
                onPressed: _trabajando || _texto.text.trim().isEmpty
                    ? null
                    : () => _ejecutar(simular: true),
                icon: _trabajando
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fact_check_rounded),
                label: const Text('Revisar'),
              ),
          ],
        ),
      ),
    );
  }
}

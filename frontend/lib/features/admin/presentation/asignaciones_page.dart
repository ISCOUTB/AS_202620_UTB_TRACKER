import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/sin_acceso.dart';
import '../../../shared/utb_ui.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/permisos.dart';
import '../data/admin_data.dart';
import 'admin_controllers.dart';

/// CARGAR ROLES (solo Administrador, ADR-0024). Pega una lista `correo,rol[,cargo]`, revísala y
/// aplícala: solo cambia el rol de cuentas que YA existen. Registrarse nunca da un rol, y un
/// correo sin cuenta no queda esperando.
class AsignacionesPage extends StatefulWidget {
  const AsignacionesPage({super.key, this.controller});
  final AsignacionesController? controller;

  @override
  State<AsignacionesPage> createState() => _AsignacionesPageState();
}

class _AsignacionesPageState extends State<AsignacionesPage> {
  late final AsignacionesController _c = widget.controller ?? sl<AsignacionesController>();

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
      body: ConPermiso(
        permiso: Permisos.usuariosGestionar,
        child: ListView(
          children: [
            const EncabezadoDegradado(
              padding: EdgeInsets.fromLTRB(12, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButton(),
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Cargar roles',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, 2, 0, 4),
                    child: Text(
                        'Asigna Auditor o Administrador a varias cuentas a la vez. Solo cuentas '
                        'que ya existen.',
                        style: TextStyle(color: Color(0xD9FFFFFF))),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nadie recibe un rol por registrarse con un correo: todas las cuentas nuevas '
                    'son Estudiantes. Aquí (o en Usuarios) un administrador sube el rol de una '
                    'cuenta que ya existe. Cada cambio cierra las sesiones de esa persona y queda '
                    'en la bitácora.',
                    style: TextStyle(color: AppColors.textoSuave),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _importar,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Cargar lista'),
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
            'Roles aplicados: ${r.actualizadas} cuentas actualizadas, ${r.sinCuenta} sin cuenta');
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
            const Text('Cargar roles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Una persona por línea: correo,rol,cargo (el cargo es opcional; también sirve '
              'punto y coma). Rol: Estudiante, Auditor o Administrador. Solo se aplica a cuentas que '
              'ya existen; primero revisa y luego aplica.',
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
                      ? '${r.validas} líneas correctas: ${r.actualizadas} cuentas cambian, '
                          '${r.sinCambios} sin cambios, ${r.sinCuenta} sin cuenta.'
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
            if (r != null && r.correosSinCuenta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sin cuenta (no se les asigna nada; si se registran serán Estudiantes hasta que '
                'les des el rol): ${r.correosSinCuenta.join(', ')}',
                style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
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
                label: const Text('Aplicar roles'),
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

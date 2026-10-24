import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/utilidades.dart';
import '../../../shared/widgets.dart';
import '../../auth/domain/auth_domain.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../recursos/domain/entities/recurso.dart';
import '../../recursos/presentation/recursos_controller.dart';
import 'prestamos_controller.dart';

/// Abre el formulario de préstamo como hoja inferior. Devuelve true si se registró.
Future<bool?> mostrarSolicitudPrestamo(BuildContext context, Recurso recurso) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SolicitudPrestamo(recurso: recurso),
    ),
  );
}

class _SolicitudPrestamo extends StatefulWidget {
  const _SolicitudPrestamo({required this.recurso});
  final Recurso recurso;

  @override
  State<_SolicitudPrestamo> createState() => _SolicitudPrestamoState();
}

class _SolicitudPrestamoState extends State<_SolicitudPrestamo> {
  final AuthController _auth = sl<AuthController>();
  final PrestamosController _prestamos = sl<PrestamosController>();
  final RecursosController _recursos = sl<RecursosController>();
  final AuthRepository _authRepo = sl<AuthRepository>();

  final TextEditingController _idUsuario = TextEditingController();

  /// Una clave por intento de préstamo: si falla la red y el usuario reintenta, se reenvía LA MISMA
  /// y el backend no duplica (S11 req. 11.3).
  final String _clave = nuevaClaveIdempotencia();

  late DateTime _devolucion = _sugerida();

  Usuario? _prestatario; // solo para auxiliares: a quién se le presta
  String? _errorPrestatario;
  bool _buscando = false;
  bool _enviando = false;
  String? _error;

  static DateTime _sugerida() {
    final ahora = DateTime.now();
    final hoy18 = DateTime(ahora.year, ahora.month, ahora.day, 18);
    return hoy18.isAfter(ahora.add(const Duration(hours: 1)))
        ? hoy18
        : hoy18.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _idUsuario.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _devolucion,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _devolucion = DateTime(fecha.year, fecha.month, fecha.day, _devolucion.hour, _devolucion.minute);
    });
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_devolucion),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _devolucion = DateTime(
          _devolucion.year, _devolucion.month, _devolucion.day, hora.hour, hora.minute);
    });
  }

  Future<void> _buscarPrestatario() async {
    final id = int.tryParse(_idUsuario.text.trim());
    if (id == null || id <= 0) {
      setState(() {
        _prestatario = null;
        _errorPrestatario = 'Escribe un ID numérico';
      });
      return;
    }
    setState(() {
      _buscando = true;
      _errorPrestatario = null;
    });
    try {
      final u = await _authRepo.obtenerUsuario(id);
      if (!mounted) return;
      setState(() => _prestatario = u);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _prestatario = null;
        _errorPrestatario =
            e.tipo == TipoError.noEncontrado ? 'No existe un usuario con ese ID' : e.mensaje;
      });
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _confirmar() async {
    final quien = _auth.esAdministrador ? _prestatario : _auth.usuario;
    if (quien == null) {
      setState(() => _error = 'Indica a quién se le presta el equipo.');
      return;
    }
    if (!_devolucion.isAfter(DateTime.now())) {
      setState(() => _error = 'La fecha de devolución debe ser futura.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });

    final r = await _prestamos.solicitar(
      recursoId: widget.recurso.id,
      usuarioId: quien.id,
      fechaDevolucionEsperada: _devolucion,
      claveIdempotencia: _clave,
    );
    if (!mounted) return;

    if (r.ok) {
      // El estado del equipo cambió a "prestado": se refresca el catálogo sin bloquear la UI.
      _recursos.cargar(silencioso: true);
      Navigator.of(context).pop(true);
      mostrarMensaje(context, 'Préstamo registrado para ${quien.nombre}');
      return;
    }
    if (r.recursoYaNoDisponible) {
      // QS-06: otro lo prestó primero. Se actualiza el catálogo y se cierra.
      _recursos.cargar(silencioso: true);
      Navigator.of(context).pop(false);
      mostrarMensaje(context, r.error ?? 'El equipo ya no está disponible.');
      return;
    }
    setState(() {
      _enviando = false;
      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = _auth.esAdministrador;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FiguraCircular(
                    figura: widget.recurso.categoria.figura, tamano: 56, relleno: 0.12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Solicitar préstamo',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      Text(
                        '${widget.recurso.titulo} · Salón ${widget.recurso.salonId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textoSuave),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (admin) ...[
              const Text('¿A quién se le presta?',
                  style: TextStyle(color: AppColors.textoSuave)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idUsuario,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {
                        _prestatario = null;
                        _errorPrestatario = null;
                      }),
                      decoration: InputDecoration(
                        labelText: 'ID del usuario',
                        errorText: _errorPrestatario,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _buscando ? null : _buscarPrestatario,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(96, 56)),
                      child: _buscando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              if (_prestatario != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.disponible, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_prestatario!.nombre} · ${_prestatario!.email}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
            ] else ...[
              TarjetaBorde(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Se registrará a nombre de ${_auth.usuario?.nombre ?? '—'}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            const Text('Devolución esperada', style: TextStyle(color: AppColors.textoSuave)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('${_devolucion.day}/${_devolucion.month}/${_devolucion.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirHora,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(TimeOfDay.fromDateTime(_devolucion).format(context)),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.danado)),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _enviando ? null : _confirmar,
              child: _enviando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : Text(_error == null ? 'Confirmar préstamo' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

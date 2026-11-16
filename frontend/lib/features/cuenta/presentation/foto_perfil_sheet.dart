import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../../auth/presentation/auth_controller.dart';

/// Lado máximo y calidad con que la app reduce la foto ANTES de subirla (ADR-0020). El servidor
/// admite hasta 512 px y 200 KB; a 256 px una foto JPEG suele pesar 15-40 KB.
const double ladoFoto = 256;
const int calidadFoto = 82;
const int maximoBytesFoto = 200 * 1024;

/// Elige una imagen ya reducida; se puede reemplazar en las pruebas.
typedef ElegirImagen = Future<XFile?> Function(ImageSource origen);

Future<XFile?> elegirConImagePicker(ImageSource origen) => ImagePicker().pickImage(
      source: origen,
      maxWidth: ladoFoto,
      maxHeight: ladoFoto,
      imageQuality: calidadFoto,
      preferredCameraDevice: CameraDevice.front,
      requestFullMetadata: false, // no pide permiso de ubicación de las fotos (iOS)
    );

/// Tipo por la firma (igual que el servidor): solo JPEG y PNG.
String? tipoDeImagen(Uint8List b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    return 'image/png';
  }
  return null;
}

/// Mensaje útil cuando el sistema niega la cámara o la galería.
String mensajePermiso(PlatformException e, ImageSource origen) {
  final camara = origen == ImageSource.camera;
  if (e.code.contains('denied') || e.code.contains('permission')) {
    return camara
        ? 'No tenemos permiso para usar la cámara. Actívalo en Ajustes > Aplicaciones > '
            'UTB Tracker > Permisos, o elige una foto de la galería.'
        : 'No tenemos permiso para ver tus fotos. Actívalo en Ajustes > Aplicaciones > '
            'UTB Tracker > Permisos.';
  }
  return camara ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.';
}

/// Hoja inferior: Tomar foto / Elegir de la galería / Quitar foto, con vista previa antes de
/// subir, estados de carga y errores.
Future<void> mostrarHojaFoto(BuildContext context,
    {ElegirImagen elegir = elegirConImagePicker, bool? hayCamara}) async {
  final mensaje = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => HojaFotoPerfil(elegir: elegir, hayCamara: hayCamara),
  );
  if (mensaje != null && context.mounted) mostrarMensaje(context, mensaje);
}

class HojaFotoPerfil extends StatefulWidget {
  const HojaFotoPerfil({super.key, required this.elegir, this.hayCamara});
  final ElegirImagen elegir;
  final bool? hayCamara;

  @override
  State<HojaFotoPerfil> createState() => _HojaFotoPerfilState();
}

class _HojaFotoPerfilState extends State<HojaFotoPerfil> {
  final AuthController _auth = sl<AuthController>();
  Uint8List? _vista;
  String? _tipo;
  bool _trabajando = false;
  String? _error;

  bool get _hayCamara {
    if (widget.hayCamara != null) return widget.hayCamara!;
    try {
      return ImagePicker().supportsImageSource(ImageSource.camera);
    } catch (_) {
      return false;
    }
  }

  Future<void> _elegir(ImageSource origen) async {
    setState(() => _error = null);
    try {
      final archivo = await widget.elegir(origen);
      if (archivo == null || !mounted) return; // canceló
      final bytes = await archivo.readAsBytes();
      final tipo = tipoDeImagen(bytes);
      setState(() {
        if (tipo == null) {
          _error = 'Ese formato no se puede usar. Elige una foto JPEG o PNG.';
        } else if (bytes.length > maximoBytesFoto) {
          _error = 'La foto es demasiado grande. Elige otra.';
        } else {
          _vista = bytes;
          _tipo = tipo;
        }
      });
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = mensajePermiso(e, origen));
    }
  }

  Future<void> _subir() async {
    setState(() {
      _trabajando = true;
      _error = null;
    });
    final ok = await _auth.subirFoto(_vista!, _tipo!);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, 'Foto actualizada');
    } else {
      setState(() {
        _trabajando = false;
        _error = _auth.error ?? 'No se pudo subir la foto';
      });
      _auth.limpiarError();
    }
  }

  Future<void> _quitar() async {
    setState(() {
      _trabajando = true;
      _error = null;
    });
    final ok = await _auth.quitarFoto();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, 'Foto quitada');
    } else {
      setState(() {
        _trabajando = false;
        _error = _auth.error ?? 'No se pudo quitar la foto';
      });
      _auth.limpiarError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneFoto = _auth.usuario?.tieneFoto ?? false;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_vista == null ? 'Foto de perfil' : 'Vista previa',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              _vista == null
                  ? 'La ven tú, los auditores y los administradores. Se guarda sin la '
                      'ubicación ni otros datos de la foto.'
                  : '¿Usar esta foto?',
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_vista != null) ...[
              Center(
                child: Semantics(
                  image: true,
                  label: 'Vista previa de tu nueva foto de perfil',
                  child: ClipOval(
                    child: Image.memory(_vista!,
                        width: 140, height: 140, fit: BoxFit.cover, excludeFromSemantics: true),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_trabajando)
                const Column(
                  children: [
                    LinearProgressIndicator(semanticsLabel: 'Subiendo foto'),
                    SizedBox(height: 6),
                    Text('Subiendo…', style: TextStyle(color: AppColors.textoSuave)),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _subir,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Usar esta foto'),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _trabajando ? null : () => setState(() => _vista = null),
                child: const Text('Elegir otra'),
              ),
            ] else ...[
              if (_hayCamara)
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Tomar foto'),
                  enabled: !_trabajando,
                  onTap: () => _elegir(ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir de la galería'),
                enabled: !_trabajando,
                onTap: () => _elegir(ImageSource.gallery),
              ),
              if (tieneFoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danado),
                  title: const Text('Quitar foto', style: TextStyle(color: AppColors.danado)),
                  subtitle: const Text('Volverás a ver tus iniciales'),
                  enabled: !_trabajando,
                  onTap: _quitar,
                ),
              if (_trabajando) const LinearProgressIndicator(semanticsLabel: 'Quitando foto'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danado, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(_error!, style: const TextStyle(color: AppColors.danado))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/di/injection.dart';
import '../core/network/api_client.dart';

/// Fotos de perfil en memoria por (usuario, versión) (ADR-0020). La versión cambia con cada
/// subida, así que una foto ya descargada no se vuelve a pedir en otra pantalla y una nueva
/// nunca se confunde con la anterior.
class CacheFotos {
  CacheFotos(this._api);
  final ApiClient _api;

  static const _maximo = 120;
  final _memoria = <String, Future<Uint8List?>>{};

  /// La propia sale de /auth/me/foto; la de otra persona de /usuarios/{id}/foto (el servidor
  /// solo la entrega a quien tiene permiso). null si no hay o no se pudo descargar.
  Future<Uint8List?> foto({required int usuarioId, required int version, bool propia = false}) {
    final clave = '$usuarioId:$version';
    final enCache = _memoria[clave];
    if (enCache != null) return enCache;
    if (_memoria.length >= _maximo) _memoria.remove(_memoria.keys.first);
    final descarga = _descargar(usuarioId, version, propia);
    _memoria[clave] = descarga;
    descarga.then((b) {
      if (b == null) _memoria.remove(clave); // reintenta la próxima vez
    });
    return descarga;
  }

  Future<Uint8List?> _descargar(int usuarioId, int version, bool propia) async {
    try {
      final ruta = propia ? '/auth/me/foto' : '/usuarios/$usuarioId/foto';
      final bytes = await _api.getBytes(ruta, parametros: {'v': version});
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  void olvidar(int usuarioId) => _memoria.removeWhere((k, _) => k.startsWith('$usuarioId:'));

  void vaciar() => _memoria.clear();
}

/// Muestra la foto de perfil si la hay; si no (o mientras carga, o si falla) muestra [respaldo]
/// (las iniciales con el color elegido). Recortada en círculo de [tamano].
class FotoOIniciales extends StatefulWidget {
  const FotoOIniciales({
    super.key,
    required this.usuarioId,
    required this.fotoVersion,
    required this.tamano,
    required this.respaldo,
    this.propia = false,
  });

  final int usuarioId;

  /// 0 = sin foto.
  final int fotoVersion;
  final double tamano;
  final Widget respaldo;
  final bool propia;

  @override
  State<FotoOIniciales> createState() => _FotoOInicialesState();
}

class _FotoOInicialesState extends State<FotoOIniciales> {
  Future<Uint8List?>? _foto;

  @override
  void initState() {
    super.initState();
    _pedir();
  }

  @override
  void didUpdateWidget(FotoOIniciales anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.fotoVersion != widget.fotoVersion || anterior.usuarioId != widget.usuarioId) {
      _pedir();
    }
  }

  void _pedir() {
    _foto = widget.fotoVersion > 0 && sl.isRegistered<CacheFotos>()
        ? sl<CacheFotos>().foto(
            usuarioId: widget.usuarioId, version: widget.fotoVersion, propia: widget.propia)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final foto = _foto;
    if (foto == null) return widget.respaldo;
    return FutureBuilder<Uint8List?>(
      future: foto,
      builder: (context, s) {
        final bytes = s.data;
        if (bytes == null) return widget.respaldo;
        return ClipOval(
          child: Image.memory(
            bytes,
            width: widget.tamano,
            height: widget.tamano,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true, // la etiqueta la pone quien la usa
            errorBuilder: (_, __, ___) => widget.respaldo,
          ),
        );
      },
    );
  }
}

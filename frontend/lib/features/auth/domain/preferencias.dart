/// Preferencias guardadas en el SERVIDOR (no en el dispositivo): siguen a la persona en el
/// celular y en la web (ADR-0016). Espejo de `app/schemas/perfil.py`.
enum TamanoTexto {
  normal('normal', 'Normal', 1.0),
  grande('grande', 'Grande', 1.15),
  extraGrande('extra_grande', 'Extra grande', 1.3);

  const TamanoTexto(this.api, this.etiqueta, this.factor);
  final String api;
  final String etiqueta;

  /// Multiplica el tamaño del texto (sobre la escala base de la app).
  final double factor;

  static TamanoTexto desdeApi(Object? v) =>
      values.firstWhere((t) => t.api == v, orElse: () => TamanoTexto.normal);
}

/// Tipos de aviso que la persona puede apagar. Los de seguridad (verificación, contraseña,
/// cambio de correo) siempre llegan.
enum CategoriaAviso {
  cuenta('cuenta', 'Novedades de mi cuenta'),
  salones('salones', 'Mis solicitudes de salón');

  const CategoriaAviso(this.api, this.etiqueta);
  final String api;
  final String etiqueta;
}

enum CanalAviso {
  correo('correo', 'Correo'),
  push('push', 'Notificación en el celular');

  const CanalAviso(this.api, this.etiqueta);
  final String api;
  final String etiqueta;
}

class Preferencias {
  const Preferencias({
    this.avisos = const {},
    this.tamanoTexto = TamanoTexto.normal,
    this.pantallaInicio = 'inicio',
  });

  /// "correo.salones" -> false. Lo que no está, está encendido.
  final Map<String, bool> avisos;
  final TamanoTexto tamanoTexto;
  final String pantallaInicio;

  bool aviso(CanalAviso canal, CategoriaAviso cat) => avisos['${canal.api}.${cat.api}'] ?? true;

  Preferencias conAviso(CanalAviso canal, CategoriaAviso cat, bool valor) => Preferencias(
        avisos: {...avisos, '${canal.api}.${cat.api}': valor},
        tamanoTexto: tamanoTexto,
        pantallaInicio: pantallaInicio,
      );

  Preferencias conTamano(TamanoTexto t) =>
      Preferencias(avisos: avisos, tamanoTexto: t, pantallaInicio: pantallaInicio);

  Preferencias conPantallaInicio(String p) =>
      Preferencias(avisos: avisos, tamanoTexto: tamanoTexto, pantallaInicio: p);

  static Preferencias desdeJson(Object? j) {
    if (j is! Map) return const Preferencias();
    final avisos = <String, bool>{};
    final n = j['notificaciones'];
    if (n is Map) {
      for (final canal in CanalAviso.values) {
        final c = n[canal.api];
        if (c is! Map) continue;
        for (final cat in CategoriaAviso.values) {
          if (c[cat.api] is bool) avisos['${canal.api}.${cat.api}'] = c[cat.api] as bool;
        }
      }
    }
    final inicio = j['pantalla_inicio'];
    return Preferencias(
      avisos: avisos,
      tamanoTexto: TamanoTexto.desdeApi(j['tamano_texto']),
      pantallaInicio: inicio is String ? inicio : 'inicio',
    );
  }

  Map<String, dynamic> aJson() => {
        'notificaciones': {
          for (final canal in CanalAviso.values)
            canal.api: {
              for (final cat in CategoriaAviso.values) cat.api: aviso(canal, cat),
            },
        },
        'tamano_texto': tamanoTexto.api,
        'pantalla_inicio': pantallaInicio,
      };
}

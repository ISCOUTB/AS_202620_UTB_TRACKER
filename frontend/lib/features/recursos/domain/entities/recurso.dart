import '../../../../core/assets/figuras.dart';

/// Categorías que declara el modelo del backend (`Recurso.categoria`).
enum CategoriaRecurso {
  videoBeam('video_beam', 'Video beam', Figuras.videoBeam),
  computador('computador', 'Computador', Figuras.computador),
  aireAc('aire_ac', 'Aire acond.', Figuras.aireAc),
  tv('tv', 'TV', Figuras.tv),
  audio('audio', 'Audio', Figuras.audio),
  otro('otro', 'Otro', Figuras.otros);

  const CategoriaRecurso(this.codigo, this.etiqueta, this.figura);

  /// Valor exacto que viaja por la API.
  final String codigo;
  final String etiqueta;
  final String figura;

  static CategoriaRecurso desde(String valor) {
    final v = valor.trim().toLowerCase();
    for (final c in CategoriaRecurso.values) {
      if (c.codigo == v) return c;
    }
    return CategoriaRecurso.otro;
  }

  /// Las que se pueden crear desde el formulario (la API acepta texto libre; se limita a las conocidas).
  static List<CategoriaRecurso> get creables =>
      values.where((c) => c != CategoriaRecurso.otro).toList();
}

/// Estados válidos del backend: disponible | prestado | dañado | mantenimiento.
enum EstadoRecurso {
  disponible('Disponible'),
  prestado('Prestado'),
  danado('Dañado'),
  mantenimiento('Mantenimiento'),
  desconocido('Sin estado');

  const EstadoRecurso(this.etiqueta);
  final String etiqueta;

  static EstadoRecurso desde(String valor) {
    switch (valor.trim().toLowerCase()) {
      case 'disponible':
        return EstadoRecurso.disponible;
      case 'prestado':
        return EstadoRecurso.prestado;
      case 'dañado':
      case 'danado':
        return EstadoRecurso.danado;
      case 'mantenimiento':
        return EstadoRecurso.mantenimiento;
      default:
        return EstadoRecurso.desconocido;
    }
  }
}

class Recurso {
  const Recurso({
    required this.id,
    required this.categoriaCodigo,
    required this.salonId,
    required this.serial,
    required this.estadoCodigo,
    this.salonNombre,
    this.salonEdificio,
    this.salonUbicacion,
    this.descripcion,
  });

  final int id;
  final String categoriaCodigo;

  /// Id interno del salón: solo para filtrar. Para mostrar se usa [salonTexto].
  final String salonId;
  final String serial;
  final String estadoCodigo;

  /// Código real del salón (p. ej. "A4-204"), edificio y ubicación legible.
  final String? salonNombre;
  final String? salonEdificio;
  final String? salonUbicacion;
  final String? descripcion;

  /// "A4-204" o "Sin salón asignado"; nunca el id interno.
  String get salonTexto => (salonNombre == null || salonNombre!.isEmpty)
      ? 'Sin salón asignado'
      : salonNombre!;

  /// "Ed. Aulas 4"
  String? get edificioTexto =>
      (salonEdificio == null || salonEdificio!.isEmpty) ? null : 'Ed. $salonEdificio';

  CategoriaRecurso get categoria => CategoriaRecurso.desde(categoriaCodigo);
  EstadoRecurso get estado => EstadoRecurso.desde(estadoCodigo);

  bool get disponible => estado == EstadoRecurso.disponible;

  /// "Video beam · VB-DEMO-01"
  String get titulo => '${categoria.etiqueta} · $serial';
}

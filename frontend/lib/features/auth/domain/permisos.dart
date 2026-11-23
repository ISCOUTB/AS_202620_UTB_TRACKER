/// Permisos del usuario (ADR-0018). La app decide qué mostrar SOLO con esta clase: ninguna
/// pantalla compara el texto del rol. La lista viene del servidor en `GET /auth/me`
/// (`permisos`) y el catálogo de roles en `GET /auth/roles` (matriz única del servidor,
/// `app/middleware/matriz_permisos.json`, ADR-0025). Aquí no hay copia de esa tabla.
class Permisos {
  const Permisos(this.valores);

  final Set<String> valores;

  static const salonesVer = 'salones.ver';
  static const salonesSolicitar = 'salones.solicitar';
  static const solicitudesPropias = 'solicitudes.propias';
  static const reportesCrear = 'reportes.crear';
  static const equiposVer = 'equipos.ver';
  static const horariosVer = 'horarios.ver';
  static const solicitudesGestionar = 'solicitudes.gestionar';
  static const salonesAdministrar = 'salones.administrar';
  static const reportesGestionar = 'reportes.gestionar';
  static const equiposGestionar = 'equipos.gestionar';
  static const horariosGestionar = 'horarios.gestionar';
  static const usuariosVer = 'usuarios.ver';
  static const salonesCrearCatalogo = 'salones.crear_catalogo';
  static const usuariosGestionar = 'usuarios.gestionar';
  static const auditoriaVer = 'auditoria.ver';
  static const estadisticasVer = 'estadisticas.ver';
  static const modoPrueba = 'modo_prueba';

  static const ninguno = Permisos({});

  /// Permisos que manda el servidor en `GET /auth/me` (`permisos`) o `GET /auth/roles`. La app NO
  /// tiene su propia tabla de roles (ADR-0025): sin lista, no hay permisos.
  factory Permisos.desdeJson(Object? lista) =>
      lista is List ? Permisos({for (final p in lista) p.toString()}) : ninguno;

  bool puede(String permiso) => valores.contains(permiso);

  /// Administra salones y atiende solicitudes (Auditor y Administrador).
  bool get opera => puede(solicitudesGestionar) || puede(salonesAdministrar);
}

/// Valores GUARDADOS del rol (no cambian: APK instaladas los leen). Solo nombres: qué puede hacer
/// cada uno lo dice el servidor.
abstract final class RolUsuario {
  static const estudiante = 'usuario_utb';
  static const auditor = 'auxiliar';
  static const administrador = 'administrador';
}

/// Un rol del catálogo del servidor (`GET /auth/roles`).
class RolCatalogo {
  const RolCatalogo({
    required this.valor,
    required this.etiqueta,
    required this.descripcion,
    required this.permisos,
  });

  final String valor;
  final String etiqueta;
  final String descripcion;
  final Permisos permisos;

  factory RolCatalogo.desdeJson(Map<String, dynamic> j) => RolCatalogo(
        valor: (j['valor'] ?? '').toString(),
        etiqueta: (j['etiqueta'] ?? '').toString(),
        descripcion: (j['descripcion'] ?? '').toString(),
        permisos: Permisos.desdeJson(j['permisos']),
      );
}

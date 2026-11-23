/// Permisos del usuario (ADR-0018). La app decide qué mostrar SOLO con esta clase: ninguna
/// pantalla compara el texto del rol. La lista viene del servidor en `GET /auth/me`
/// (`permisos`); el mapa de [deRol] es el mismo de `app/core/permisos.py` y solo se usa
/// con servidores anteriores a ADR-0018 y para el modo prueba del administrador.
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

  static const _todos = {
    salonesVer, salonesSolicitar, solicitudesPropias, reportesCrear, equiposVer, horariosVer,
  };
  static const _operacion = {
    solicitudesGestionar, salonesAdministrar, reportesGestionar, equiposGestionar,
    horariosGestionar, usuariosVer,
  };
  static const _administracion = {
    usuariosGestionar, auditoriaVer, estadisticasVer, modoPrueba, salonesCrearCatalogo,
  };

  static const ninguno = Permisos({});

  /// Mismo mapa que el servidor (`PERMISOS_POR_ROL`). Rol desconocido: sin permisos.
  factory Permisos.deRol(String rol) => switch (rol.trim().toLowerCase()) {
        RolUsuario.estudiante => const Permisos(_todos),
        RolUsuario.auditor => const Permisos({..._todos, ..._operacion}),
        RolUsuario.administrador =>
          const Permisos({..._todos, ..._operacion, ..._administracion}),
        _ => ninguno,
      };

  /// `permisos` del JSON si el servidor los manda; si no (servidor anterior), los del rol.
  factory Permisos.desdeJson(Object? lista, String rol) => lista is List
      ? Permisos({for (final p in lista) p.toString()})
      : Permisos.deRol(rol);

  bool puede(String permiso) => valores.contains(permiso);

  /// Administra salones y atiende solicitudes (Auditor y Administrador).
  bool get opera => puede(solicitudesGestionar) || puede(salonesAdministrar);
}

/// Valores GUARDADOS del rol (no cambian: APK instaladas los leen) y sus etiquetas.
abstract final class RolUsuario {
  static const estudiante = 'usuario_utb';
  static const auditor = 'auxiliar';
  static const administrador = 'administrador';
  static const todos = [estudiante, auditor, administrador];

  static String etiqueta(String rol) => switch (rol.trim().toLowerCase()) {
        estudiante => 'Estudiante',
        auditor => 'Auditor',
        administrador => 'Administrador',
        _ => 'Sin rol',
      };

  static String descripcion(String rol) => switch (rol.trim().toLowerCase()) {
        estudiante => 'Consulta salones y los solicita',
        auditor => 'Administra los salones y atiende solicitudes',
        administrador => 'Todo lo anterior, usuarios, bitácora y estadísticas',
        _ => '',
      };
}

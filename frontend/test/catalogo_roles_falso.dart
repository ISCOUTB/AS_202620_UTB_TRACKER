import 'package:utb_tracker_app/features/auth/domain/permisos.dart';

/// Copia de PRUEBA de lo que responde `GET /auth/roles` (la matriz vive en el servidor,
/// `app/middleware/matriz_permisos.json`, ADR-0025). Solo existe en las pruebas de la app.
const _todos = [
  'salones.ver', 'salones.solicitar', 'solicitudes.propias', 'reportes.crear', 'equipos.ver',
  'horarios.ver',
];
const _operacion = [
  'solicitudes.gestionar', 'salones.administrar', 'reportes.gestionar', 'equipos.gestionar',
  'horarios.gestionar', 'usuarios.ver',
];
const _administracion = [
  'salones.crear_catalogo', 'usuarios.gestionar', 'auditoria.ver', 'estadisticas.ver',
  'modo_prueba',
];

final List<Map<String, dynamic>> catalogoRolesFalso = [
  {
    'valor': 'usuario_utb',
    'etiqueta': 'Estudiante',
    'descripcion': 'Consulta salones y los solicita',
    'permisos': _todos,
  },
  {
    'valor': 'auxiliar',
    'etiqueta': 'Auditor',
    'descripcion': 'Administra los salones y atiende solicitudes',
    'permisos': [..._todos, ..._operacion],
  },
  {
    'valor': 'administrador',
    'etiqueta': 'Administrador',
    'descripcion': 'Todo lo anterior, usuarios, bitácora y estadísticas',
    'permisos': [..._todos, ..._operacion, ..._administracion],
  },
];

Map<String, dynamic> _rol(String valor) =>
    catalogoRolesFalso.firstWhere((r) => r['valor'] == valor);

/// Permisos del rol según el catálogo falso (rol desconocido: ninguno).
Permisos permisosDe(String valor) => catalogoRolesFalso.any((r) => r['valor'] == valor)
    ? Permisos.desdeJson(_rol(valor)['permisos'])
    : Permisos.ninguno;

String etiquetaDe(String valor) =>
    catalogoRolesFalso.any((r) => r['valor'] == valor) ? _rol(valor)['etiqueta'] as String : 'Sin rol';

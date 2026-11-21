import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';

/// Fila de la pantalla Usuarios del administrador (`GET /usuarios`, ADR-0018).
class UsuarioAdmin {
  const UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.rolEtiqueta,
    required this.activo,
    this.nombreMostrar,
    this.dependencia,
    this.ultimaActividad,
    this.fotoVersion = 0,
  });

  /// ADR-0020: 0 = sin foto.
  final int fotoVersion;


  final int id;
  final String nombre;
  final String? nombreMostrar;
  final String email;
  final String rol;
  final String rolEtiqueta;
  final bool activo;
  final String? dependencia;
  final DateTime? ultimaActividad;

  String get nombreVisible =>
      (nombreMostrar?.trim().isNotEmpty ?? false) ? nombreMostrar!.trim() : nombre;

  factory UsuarioAdmin.desdeJson(Map<String, dynamic> j) => UsuarioAdmin(
        id: (j['id'] as num).toInt(),
        nombre: (j['nombre'] ?? '').toString(),
        nombreMostrar: j['nombre_mostrar'] as String?,
        email: (j['email'] ?? '').toString(),
        rol: (j['rol'] ?? '').toString(),
        rolEtiqueta: (j['rol_etiqueta'] ?? '').toString(),
        activo: j['activo'] as bool? ?? true,
        dependencia: j['dependencia'] as String?,
        ultimaActividad: j['ultima_actividad'] != null
            ? parsearFechaServidor(j['ultima_actividad'].toString())
            : null,
        fotoVersion: (j['foto_version'] as num?)?.toInt() ?? 0,
      );
}

/// Resultado de importar una lista (todo o nada: con errores no se guardó nada).
class ResultadoImportacion {
  const ResultadoImportacion({
    required this.validas,
    required this.actualizadas,
    required this.sinCambios,
    required this.sinCuenta,
    required this.correosSinCuenta,
    required this.errores,
    required this.aplicado,
  });

  final int validas;
  final int actualizadas;
  final int sinCambios;
  final int sinCuenta;
  final List<String> correosSinCuenta;
  final List<(int linea, String error)> errores;
  final bool aplicado;

  factory ResultadoImportacion.desdeJson(Map<String, dynamic> j) => ResultadoImportacion(
        validas: (j['validas'] as num).toInt(),
        actualizadas: (j['actualizadas'] as num).toInt(),
        sinCambios: (j['sin_cambios'] as num).toInt(),
        sinCuenta: (j['sin_cuenta'] as num? ?? 0).toInt(),
        correosSinCuenta: [
          for (final c in (j['correos_sin_cuenta'] as List<dynamic>? ?? const [])) c.toString(),
        ],
        errores: [
          for (final e in (j['errores'] as List<dynamic>? ?? const []))
            ((e['linea'] as num).toInt(), (e['error'] ?? '').toString()),
        ],
        aplicado: j['aplicado'] as bool? ?? false,
      );
}

/// `GET /stats/admin`: solo datos reales que calcula el servidor.
class EstadisticasAdmin {
  const EstadisticasAdmin({
    required this.dias,
    required this.usuariosPorRol,
    required this.usuariosInactivos,
    required this.solicitudesPorEstado,
    required this.salonesMasSolicitados,
    required this.salonesPorTipo,
    required this.reportesPorEstado,
    required this.reportesPorTipo,
  });

  final int dias;
  final List<(String etiqueta, int total)> usuariosPorRol;
  final int usuariosInactivos;
  final Map<String, int> solicitudesPorEstado;
  final List<(String salon, int total)> salonesMasSolicitados;
  final Map<String, int> salonesPorTipo;
  final Map<String, int> reportesPorEstado;
  final Map<String, int> reportesPorTipo;

  int get totalSolicitudes => solicitudesPorEstado.values.fold(0, (a, b) => a + b);

  static Map<String, int> _mapa(Object? j) => {
        for (final e in ((j as Map<String, dynamic>?) ?? const {}).entries)
          e.key: (e.value as num).toInt(),
      };

  factory EstadisticasAdmin.desdeJson(Map<String, dynamic> j) => EstadisticasAdmin(
        dias: (j['dias'] as num).toInt(),
        usuariosPorRol: [
          for (final x in (j['usuarios_activos_por_rol'] as List<dynamic>))
            ((x['etiqueta'] ?? '').toString(), (x['total'] as num).toInt()),
        ],
        usuariosInactivos: (j['usuarios_inactivos'] as num?)?.toInt() ?? 0,
        solicitudesPorEstado: _mapa(j['solicitudes_por_estado']),
        salonesMasSolicitados: [
          for (final x in (j['salones_mas_solicitados'] as List<dynamic>))
            ((x['salon'] ?? '').toString(), (x['total'] as num).toInt()),
        ],
        salonesPorTipo: _mapa(j['salones_por_tipo']),
        reportesPorEstado: _mapa(j['reportes_salon_por_estado']),
        reportesPorTipo: _mapa(j['reportes_salon_por_tipo']),
      );
}

abstract class AdminRepository {
  Future<List<UsuarioAdmin>> usuarios({String? busqueda, String? rol});
  Future<UsuarioAdmin> cambiarRol(int id, String rol);
  Future<UsuarioAdmin> cambiarEstado(int id, {required bool activo});
  Future<EstadisticasAdmin> estadisticas({int dias = 30});
  Future<ResultadoImportacion> importarAsignaciones(String texto, {bool simular = false});
}

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<List<UsuarioAdmin>> usuarios({String? busqueda, String? rol}) async {
    final cuerpo = await _api.get('/usuarios', parametros: {
      'limit': 100,
      if (busqueda != null && busqueda.trim().isNotEmpty) 'busqueda': busqueda.trim(),
      if (rol != null) 'rol': rol,
    }) as List<dynamic>;
    return [for (final j in cuerpo) UsuarioAdmin.desdeJson(j as Map<String, dynamic>)];
  }

  @override
  Future<UsuarioAdmin> cambiarRol(int id, String rol) async => UsuarioAdmin.desdeJson(
      await _api.patch('/usuarios/$id/rol', cuerpo: {'rol': rol}) as Map<String, dynamic>);

  @override
  Future<UsuarioAdmin> cambiarEstado(int id, {required bool activo}) async =>
      UsuarioAdmin.desdeJson(await _api.patch('/usuarios/$id/estado',
          cuerpo: {'activo': activo}) as Map<String, dynamic>);

  @override
  Future<ResultadoImportacion> importarAsignaciones(String texto, {bool simular = false}) async =>
      ResultadoImportacion.desdeJson(await _api.post('/usuarios/asignaciones/importar',
          cuerpo: {'texto': texto, 'simular': simular}) as Map<String, dynamic>);

  @override
  Future<EstadisticasAdmin> estadisticas({int dias = 30}) async => EstadisticasAdmin.desdeJson(
      await _api.get('/stats/admin', parametros: {'dias': dias}) as Map<String, dynamic>);
}

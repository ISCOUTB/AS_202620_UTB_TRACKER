import '../../../core/network/api_client.dart';
import '../domain/entities/recurso.dart';
import '../domain/repositories/recursos_repository.dart';

/// JSON de `RecursoOut` (docs/contracts/openapi.json) → entidad.
class RecursoModel {
  RecursoModel._();

  static Recurso desdeJson(Map<String, dynamic> j) => Recurso(
        id: (j['id'] as num).toInt(),
        categoriaCodigo: (j['categoria'] ?? '').toString(),
        salonId: (j['salon_id'] ?? '').toString(),
        serial: (j['serial'] ?? '').toString(),
        estadoCodigo: (j['estado'] ?? '').toString(),
      );
}

class RecursosRemoteDataSource {
  RecursosRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Recurso>> listar() async {
    final cuerpo = await _api.get('/recursos') as List<dynamic>;
    return cuerpo
        .map((e) => RecursoModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recurso> obtener(int id) async {
    final cuerpo = await _api.get('/recursos/$id') as Map<String, dynamic>;
    return RecursoModel.desdeJson(cuerpo);
  }

  Future<Recurso> crear({
    required String categoria,
    required String salonId,
    required String serial,
  }) async {
    final cuerpo = await _api.post(
      '/recursos',
      cuerpo: {'categoria': categoria, 'salon_id': salonId, 'serial': serial},
    ) as Map<String, dynamic>;
    return RecursoModel.desdeJson(cuerpo);
  }

  Future<void> reportar({
    required int recursoId,
    required String estadoReportado,
    String? descripcion,
    String? imagenUrl,
  }) async {
    await _api.post(
      '/recursos/$recursoId/reportar',
      cuerpo: {
        'estado_reportado': estadoReportado,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        if (imagenUrl != null && imagenUrl.isNotEmpty) 'imagen_url': imagenUrl,
      },
    );
  }
}

class RecursosRepositoryImpl implements RecursosRepository {
  RecursosRepositoryImpl(this._remoto);
  final RecursosRemoteDataSource _remoto;

  @override
  Future<List<Recurso>> listar() => _remoto.listar();

  @override
  Future<Recurso> obtener(int id) => _remoto.obtener(id);

  @override
  Future<Recurso> crear({
    required String categoria,
    required String salonId,
    required String serial,
  }) =>
      _remoto.crear(categoria: categoria, salonId: salonId, serial: serial);

  @override
  Future<void> reportar({
    required int recursoId,
    required String estadoReportado,
    String? descripcion,
    String? imagenUrl,
  }) =>
      _remoto.reportar(
        recursoId: recursoId,
        estadoReportado: estadoReportado,
        descripcion: descripcion,
        imagenUrl: imagenUrl,
      );
}

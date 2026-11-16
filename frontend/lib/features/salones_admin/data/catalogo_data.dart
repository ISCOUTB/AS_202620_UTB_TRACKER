import '../../../core/network/api_client.dart';
import '../domain/catalogo.dart';

/// JSON del catálogo (ADR-0021) → entidades.
class CatalogoRepositoryImpl implements CatalogoRepository {
  CatalogoRepositoryImpl(this._api);
  final ApiClient _api;

  static List<String> _lista(Object? v) => [for (final e in (v as List? ?? const [])) '$e'];

  static VistaPreviaRango _previa(Map<String, dynamic> j) => VistaPreviaRango(
        edificio: (j['edificio'] ?? '').toString(),
        piso: (j['piso'] as num).toInt(),
        nuevos: _lista(j['nuevos']),
        existentes: _lista(j['existentes']),
        creados: _lista(j['creados']),
      );

  Map<String, dynamic> _rango(int edificio, int piso, int desde, int hasta, [int? capacidad]) => {
        'edificio': edificio,
        'piso': piso,
        'desde': desde,
        'hasta': hasta,
        if (capacidad != null) 'capacidad': capacidad,
      };

  @override
  Future<VistaPreviaRango> vistaPrevia(int edificio, int piso, int desde, int hasta) async =>
      _previa(await _api.post('/salones/catalogo/rango/vista-previa',
          cuerpo: _rango(edificio, piso, desde, hasta)) as Map<String, dynamic>);

  @override
  Future<VistaPreviaRango> crearRango(int edificio, int piso, int desde, int hasta,
          {int? capacidad}) async =>
      _previa(await _api.post('/salones/catalogo/rango',
          cuerpo: _rango(edificio, piso, desde, hasta, capacidad)) as Map<String, dynamic>);

  @override
  Future<List<SalonFueraCatalogo>> fueraDelCatalogo() async {
    final cuerpo = await _api.get('/salones/catalogo/fuera') as List<dynamic>;
    return [
      for (final e in cuerpo.cast<Map<String, dynamic>>())
        SalonFueraCatalogo(
          id: (e['id'] as num).toInt(),
          nombre: (e['nombre'] ?? '').toString(),
          tieneHistorial: e['tiene_historial'] as bool? ?? false,
          problema: (e['problema'] ?? '').toString(),
          propuesta: (e['propuesta'] ?? '').toString(),
        ),
    ];
  }

  @override
  Future<void> desactivar(int salonId) => _api.delete('/salones/$salonId');
}

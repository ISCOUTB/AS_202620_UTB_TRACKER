import '../../../core/network/api_client.dart';
import '../../salones/data/salones_data.dart';
import '../../salones/domain/entities/salon.dart';

/// Solicitudes de salón por rol (ADR-0018):
/// - Estudiante: `GET /prestamos-salon/mias`, cancelar las pendientes.
/// - Auditor/Administrador: bandeja `GET /prestamos-salon/gestion`, aprobar y rechazar.
abstract class SolicitudesRepository {
  Future<List<PrestamoSalon>> mias();
  Future<List<PrestamoSalon>> bandeja({String estado = 'pendiente'});
  Future<PrestamoSalon> cancelar(int id);
  Future<PrestamoSalon> aprobar(int id, {String? nota});
  Future<PrestamoSalon> rechazar(int id, String motivo);
}

class SolicitudesRepositoryImpl implements SolicitudesRepository {
  SolicitudesRepositoryImpl(this._api);
  final ApiClient _api;

  List<PrestamoSalon> _lista(Object? cuerpo) => [
        for (final j in (cuerpo as List<dynamic>))
          PrestamoSalonModel.desdeJson(j as Map<String, dynamic>),
      ];

  PrestamoSalon _una(Object? cuerpo) =>
      PrestamoSalonModel.desdeJson(cuerpo as Map<String, dynamic>);

  @override
  Future<List<PrestamoSalon>> mias() async =>
      _lista(await _api.get('/prestamos-salon/mias', parametros: {'limit': 100}));

  @override
  Future<List<PrestamoSalon>> bandeja({String estado = 'pendiente'}) async => _lista(
      await _api.get('/prestamos-salon/gestion', parametros: {'estado': estado, 'limit': 100}));

  @override
  Future<PrestamoSalon> cancelar(int id) async => _una(await _api.delete('/prestamos-salon/$id'));

  @override
  Future<PrestamoSalon> aprobar(int id, {String? nota}) async => _una(await _api.post(
      '/prestamos-salon/$id/aprobar',
      cuerpo: {if (nota != null && nota.trim().isNotEmpty) 'respuesta': nota.trim()}));

  @override
  Future<PrestamoSalon> rechazar(int id, String motivo) async => _una(
      await _api.post('/prestamos-salon/$id/rechazar', cuerpo: {'respuesta': motivo.trim()}));
}

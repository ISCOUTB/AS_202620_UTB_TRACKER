import '../../../core/network/api_client.dart';

class DashboardStats {
  const DashboardStats({
    required this.salonesLibres,
    required this.salonesOcupados,
    required this.equiposDisponibles,
    required this.prestamosActivos,
    required this.reportesAbiertos,
    required this.solicitudesPendientes,
  });

  final int salonesLibres;
  final int salonesOcupados;
  final int equiposDisponibles;
  final int prestamosActivos;
  final int reportesAbiertos;
  final int solicitudesPendientes;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        salonesLibres: _int(json['salones_libres']),
        salonesOcupados: _int(json['salones_ocupados']),
        equiposDisponibles: _int(json['equipos_disponibles']),
        prestamosActivos: _int(json['prestamos_activos']),
        reportesAbiertos: _int(json['reportes_abiertos']),
        solicitudesPendientes: _int(json['solicitudes_salon_pendientes']),
      );

  static int _int(Object? value) => value is num ? value.toInt() : 0;
}

class StatsRemoteDataSource {
  StatsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<DashboardStats> resumen() async {
    final response = await _api.get('/stats/resumen');
    return DashboardStats.fromJson(response as Map<String, dynamic>);
  }
}

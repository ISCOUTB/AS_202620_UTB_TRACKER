import '../../../core/network/api_client.dart';

class MantenimientoItem {
  const MantenimientoItem({
    required this.id,
    required this.recursoId,
    required this.estado,
    required this.tipo,
    this.descripcion,
    this.fechaProgramada,
  });

  final int id;
  final int recursoId;
  final String estado;
  final String tipo;
  final String? descripcion;
  final DateTime? fechaProgramada;

  factory MantenimientoItem.fromJson(Map<String, dynamic> json) {
    final fecha = json['fecha_programada']?.toString();
    return MantenimientoItem(
      id: (json['id'] as num).toInt(),
      recursoId: (json['recurso_id'] as num).toInt(),
      estado: (json['estado'] ?? 'pendiente').toString(),
      tipo: (json['tipo'] ?? 'correctivo').toString(),
      descripcion: json['descripcion']?.toString(),
      fechaProgramada: fecha == null ? null : DateTime.tryParse(fecha),
    );
  }
}

class MantenimientoRemoteDataSource {
  MantenimientoRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<MantenimientoItem>> listar() async {
    final response = await _api.get('/mantenimientos') as List<dynamic>;
    return response
        .map((item) => MantenimientoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MantenimientoItem> actualizar(int id, String estado) async {
    final response = await _api.patch(
      '/mantenimientos/$id',
      cuerpo: {'estado': estado},
    ) as Map<String, dynamic>;
    return MantenimientoItem.fromJson(response);
  }
}

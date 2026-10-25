import '../entities/recurso.dart';

/// Contrato del dominio. La UI no sabe si los datos vienen del API, de caché o de un mock.
abstract class RecursosRepository {
  /// GET /recursos
  Future<List<Recurso>> listar();

  /// GET /recursos/{id}
  Future<Recurso> obtener(int id);

  /// POST /recursos (queda en estado "disponible"; 409 si el serial ya existe)
  Future<Recurso> crear({
    required String categoria,
    required dynamic salonId,
    required String serial,
  });

  /// POST /recursos/{id}/reportar (reporta daño/mantenimiento con descripción e imagen)
  Future<void> reportar({
    required int recursoId,
    required String estadoReportado,
    String? descripcion,
    String? imagenUrl,
  });
}

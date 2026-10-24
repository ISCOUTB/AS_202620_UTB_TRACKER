import '../entities/prestamo.dart';

abstract class PrestamosRepository {
  /// GET /prestamos (hoy el backend devuelve TODOS; el filtrado por usuario se hace en el cliente).
  Future<List<Prestamo>> listar();

  /// POST /prestamos con cabecera X-Idempotency-Key.
  /// 404 recurso inexistente · 409 recurso no disponible.
  Future<Prestamo> crear({
    required int recursoId,
    required int usuarioId,
    required DateTime fechaDevolucionEsperada,
    required String claveIdempotencia,
  });

  /// PATCH /prestamos/{id}/devolver
  Future<Prestamo> devolver(int prestamoId);
}

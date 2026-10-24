import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';
import '../domain/entities/prestamo.dart';
import '../domain/repositories/prestamos_repository.dart';

/// JSON de `PrestamoOut` → entidad. `fecha_devolucion_real` es obligatoria en el contrato pero
/// puede venir `null` (préstamo sin devolver).
class PrestamoModel {
  PrestamoModel._();

  static Prestamo desdeJson(Map<String, dynamic> j) {
    final real = j['fecha_devolucion_real'];
    return Prestamo(
      id: (j['id'] as num).toInt(),
      recursoId: (j['recurso_id'] as num).toInt(),
      usuarioId: (j['usuario_id'] as num).toInt(),
      fechaPrestamo: parsearFechaServidor(j['fecha_prestamo'].toString()),
      fechaDevolucionEsperada:
          parsearFechaServidor(j['fecha_devolucion_esperada'].toString()),
      fechaDevolucionReal: real == null ? null : parsearFechaServidor(real.toString()),
    );
  }
}

class PrestamosRemoteDataSource {
  PrestamosRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Prestamo>> listar() async {
    final cuerpo = await _api.get('/prestamos') as List<dynamic>;
    return cuerpo
        .map((e) => PrestamoModel.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Prestamo> crear({
    required int recursoId,
    required int usuarioId,
    required DateTime fechaDevolucionEsperada,
    required String claveIdempotencia,
  }) async {
    final cuerpo = await _api.post(
      '/prestamos',
      cabeceras: {'X-Idempotency-Key': claveIdempotencia},
      cuerpo: {
        'recurso_id': recursoId,
        'usuario_id': usuarioId,
        'fecha_devolucion_esperada': fechaParaServidor(fechaDevolucionEsperada),
      },
    ) as Map<String, dynamic>;
    return PrestamoModel.desdeJson(cuerpo);
  }

  Future<Prestamo> devolver(int prestamoId) async {
    final cuerpo = await _api.patch(
      '/prestamos/$prestamoId/devolver',
    ) as Map<String, dynamic>;
    return PrestamoModel.desdeJson(cuerpo);
  }
}

class PrestamosRepositoryImpl implements PrestamosRepository {
  PrestamosRepositoryImpl(this._remoto);
  final PrestamosRemoteDataSource _remoto;

  @override
  Future<List<Prestamo>> listar() => _remoto.listar();

  @override
  Future<Prestamo> crear({
    required int recursoId,
    required int usuarioId,
    required DateTime fechaDevolucionEsperada,
    required String claveIdempotencia,
  }) =>
      _remoto.crear(
        recursoId: recursoId,
        usuarioId: usuarioId,
        fechaDevolucionEsperada: fechaDevolucionEsperada,
        claveIdempotencia: claveIdempotencia,
      );

  @override
  Future<Prestamo> devolver(int prestamoId) => _remoto.devolver(prestamoId);
}

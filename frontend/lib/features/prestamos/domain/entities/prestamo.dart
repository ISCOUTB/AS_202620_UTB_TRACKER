enum EstadoPrestamo { activo, vencido, devuelto }

/// Préstamo tal como lo devuelve `PrestamoOut`.
/// El backend no guarda un "estado": se deriva de las fechas (ubicuo: activo / vencido / devuelto).
class Prestamo {
  const Prestamo({
    required this.id,
    required this.recursoId,
    required this.usuarioId,
    required this.fechaPrestamo,
    required this.fechaDevolucionEsperada,
    this.fechaDevolucionReal,
  });

  final int id;
  final int recursoId;
  final int usuarioId;
  final DateTime fechaPrestamo;
  final DateTime fechaDevolucionEsperada;
  final DateTime? fechaDevolucionReal;

  bool get devuelto => fechaDevolucionReal != null;

  EstadoPrestamo estadoEn(DateTime ahora) {
    if (devuelto) return EstadoPrestamo.devuelto;
    return fechaDevolucionEsperada.isBefore(ahora)
        ? EstadoPrestamo.vencido
        : EstadoPrestamo.activo;
  }
}

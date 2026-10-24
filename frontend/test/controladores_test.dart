import 'package:flutter_test/flutter_test.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/features/prestamos/domain/entities/prestamo.dart';
import 'package:utb_tracker_app/features/prestamos/domain/repositories/prestamos_repository.dart';
import 'package:utb_tracker_app/features/prestamos/presentation/prestamos_controller.dart';
import 'package:utb_tracker_app/features/recursos/domain/entities/recurso.dart';
import 'package:utb_tracker_app/features/recursos/domain/repositories/recursos_repository.dart';
import 'package:utb_tracker_app/features/recursos/presentation/recursos_controller.dart';

class _RecursosFalso implements RecursosRepository {
  _RecursosFalso(this.datos);
  final List<Recurso> datos;

  @override
  Future<List<Recurso>> listar() async => List.of(datos);

  @override
  Future<Recurso> obtener(int id) async => datos.firstWhere((r) => r.id == id);

  @override
  Future<Recurso> crear({
    required String categoria,
    required String salonId,
    required String serial,
  }) async {
    if (datos.any((r) => r.serial == serial)) {
      throw ApiException(TipoError.conflicto, 'Ya existe un recurso con ese serial');
    }
    return Recurso(
      id: 99,
      categoriaCodigo: categoria,
      salonId: salonId,
      serial: serial,
      estadoCodigo: 'disponible',
    );
  }
}

class _PrestamosFalso implements PrestamosRepository {
  _PrestamosFalso({this.fallo});
  final ApiException? fallo;

  @override
  Future<List<Prestamo>> listar() async => [];

  @override
  Future<Prestamo> crear({
    required int recursoId,
    required int usuarioId,
    required DateTime fechaDevolucionEsperada,
    required String claveIdempotencia,
  }) async {
    if (fallo != null) throw fallo!;
    return Prestamo(
      id: 1,
      recursoId: recursoId,
      usuarioId: usuarioId,
      fechaPrestamo: DateTime.now(),
      fechaDevolucionEsperada: fechaDevolucionEsperada,
    );
  }
}

const _vb = Recurso(
  id: 1,
  categoriaCodigo: 'video_beam',
  salonId: 'A1-304',
  serial: 'VB-1',
  estadoCodigo: 'disponible',
);
const _pc = Recurso(
  id: 2,
  categoriaCodigo: 'computador',
  salonId: 'B2-101',
  serial: 'PC-24',
  estadoCodigo: 'dañado',
);

void main() {
  group('Recurso', () {
    test('estado "dañado" (con ñ) se reconoce', () {
      expect(_pc.estado, EstadoRecurso.danado);
    });
    test('categoría desconocida cae en "otro"', () {
      expect(CategoriaRecurso.desde('nevera'), CategoriaRecurso.otro);
    });
  });

  group('RecursosController', () {
    test('carga y filtra por categoría, estado y texto', () async {
      final c = RecursosController(_RecursosFalso([_vb, _pc]));
      await c.cargar();
      expect(c.todos.length, 2);

      c.fijarCategoria(CategoriaRecurso.computador);
      expect(c.filtrados, [_pc]);
      c.limpiarFiltros();

      c.fijarEstado(EstadoRecurso.disponible);
      expect(c.filtrados, [_vb]);
      c.limpiarFiltros();

      c.fijarBusqueda('b2-101');
      expect(c.filtrados, [_pc]);
    });

    test('cuenta disponibles y fuera de servicio', () async {
      final c = RecursosController(_RecursosFalso([_vb, _pc]));
      await c.cargar();
      expect(c.totalDisponibles, 1);
      expect(c.totalFueraDeServicio, 1);
      expect(c.disponiblesDe(CategoriaRecurso.videoBeam), 1);
    });

    test('crear con serial repetido devuelve el mensaje del 409', () async {
      final c = RecursosController(_RecursosFalso([_vb]));
      await c.cargar();
      final error = await c.crear(categoria: 'tv', salonId: 'A1', serial: 'VB-1');
      expect(error, contains('Ya existe'));
      expect(c.todos.length, 1);
    });
  });

  group('PrestamosController', () {
    test('solicitar con éxito agrega el préstamo', () async {
      final c = PrestamosController(_PrestamosFalso());
      final r = await c.solicitar(
        recursoId: 1,
        usuarioId: 5,
        fechaDevolucionEsperada: DateTime.now().add(const Duration(days: 1)),
        claveIdempotencia: 'k',
      );
      expect(r.ok, isTrue);
      expect(c.todos.length, 1);
      expect(c.deUsuario(5).length, 1);
    });

    test('409 marca recursoYaNoDisponible (QS-06)', () async {
      final c = PrestamosController(_PrestamosFalso(
        fallo: ApiException(TipoError.conflicto, 'El recurso no esta disponible', statusCode: 409),
      ));
      final r = await c.solicitar(
        recursoId: 1,
        usuarioId: 5,
        fechaDevolucionEsperada: DateTime.now().add(const Duration(days: 1)),
        claveIdempotencia: 'k',
      );
      expect(r.ok, isFalse);
      expect(r.recursoYaNoDisponible, isTrue);
    });

    test('estado derivado de las fechas', () {
      final ahora = DateTime(2026, 10, 20, 12);
      Prestamo p(DateTime esperada, [DateTime? real]) => Prestamo(
            id: 1,
            recursoId: 1,
            usuarioId: 1,
            fechaPrestamo: DateTime(2026, 10, 19),
            fechaDevolucionEsperada: esperada,
            fechaDevolucionReal: real,
          );
      expect(p(DateTime(2026, 10, 21)).estadoEn(ahora), EstadoPrestamo.activo);
      expect(p(DateTime(2026, 10, 19, 18)).estadoEn(ahora), EstadoPrestamo.vencido);
      expect(p(DateTime(2026, 10, 19, 18), DateTime(2026, 10, 19, 17)).estadoEn(ahora),
          EstadoPrestamo.devuelto);
    });
  });
}

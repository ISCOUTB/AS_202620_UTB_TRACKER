import 'package:flutter_test/flutter_test.dart';
import 'package:utb_tracker_app/core/error/api_exception.dart';
import 'package:utb_tracker_app/features/admin/presentation/admin_usuarios_controller.dart';
import 'package:utb_tracker_app/features/auth/domain/auth_domain.dart';
import 'package:utb_tracker_app/features/prestamos/domain/entities/prestamo.dart';
import 'package:utb_tracker_app/features/prestamos/domain/repositories/prestamos_repository.dart';
import 'package:utb_tracker_app/features/prestamos/presentation/prestamos_controller.dart';
import 'package:utb_tracker_app/features/recursos/domain/entities/recurso.dart';
import 'package:utb_tracker_app/features/recursos/domain/repositories/recursos_repository.dart';
import 'package:utb_tracker_app/features/recursos/presentation/recursos_controller.dart';

class _AuthFalso implements AuthRepository {
  _AuthFalso(this.usuarios, {this.fallo});
  final List<Usuario> usuarios;
  final ApiException? fallo;

  @override
  Future<Sesion> iniciarSesion(String nombre, String password, {Usuario? conocido}) async {
    throw UnimplementedError();
  }

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String rol,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Usuario> usuarioActual() async => usuarios.first;

  @override
  Future<Usuario> obtenerUsuario(int id) async => usuarios.firstWhere((u) => u.id == id);

  @override
  Future<List<Usuario>> listarUsuarios({String? busqueda, String? rol}) async => List.of(usuarios);

  @override
  Future<Usuario> actualizarRolUsuario(int usuarioId, String nuevoRol) async {
    if (fallo != null) throw fallo!;
    final index = usuarios.indexWhere((u) => u.id == usuarioId);
    if (index == -1) throw ApiException(TipoError.noEncontrado, 'Usuario no encontrado');
    final actual = usuarios[index];
    final actualizado = Usuario(
      id: actual.id,
      nombre: actual.nombre,
      email: actual.email,
      rol: nuevoRol,
    );
    usuarios[index] = actualizado;
    return actualizado;
  }

  @override
  Future<bool> servidorSaludable() async => true;
}

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
    required dynamic salonId,
    required String serial,
  }) async {
    if (datos.any((r) => r.serial == serial)) {
      throw ApiException(TipoError.conflicto, 'Ya existe un recurso con ese serial');
    }
    return Recurso(
      id: 99,
      categoriaCodigo: categoria,
      salonId: salonId.toString(),
      serial: serial,
      estadoCodigo: 'disponible',
    );
  }

  @override
  Future<void> reportar({
    required int recursoId,
    required String estadoReportado,
    String? descripcion,
    String? imagenUrl,
  }) async {}
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

  @override
  Future<Prestamo> devolver(int prestamoId) async {
    if (fallo != null) throw fallo!;
    return Prestamo(
      id: prestamoId,
      recursoId: 1,
      usuarioId: 1,
      fechaPrestamo: DateTime.now(),
      fechaDevolucionEsperada: DateTime.now().add(const Duration(hours: 1)),
      fechaDevolucionReal: DateTime.now(),
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

  group('AdminUsuariosController', () {
    const u1 = Usuario(id: 1, nombre: 'Ana Gómez', email: 'ana@utb.edu.co', rol: 'usuario_utb');
    const u2 = Usuario(id: 2, nombre: 'Carlos Auxiliar', email: 'carlos@utb.edu.co', rol: 'administrador');

    test('carga y filtra usuarios por texto y rol', () async {
      final ctrl = AdminUsuariosController(_AuthFalso([u1, u2]));
      await ctrl.cargar();

      expect(ctrl.todos.length, 2);
      expect(ctrl.filtrados.length, 2);

      ctrl.fijarBusqueda('carlos');
      expect(ctrl.filtrados, [u2]);

      ctrl.fijarBusqueda('');
      ctrl.fijarFiltroRol('usuario_utb');
      expect(ctrl.filtrados, [u1]);

      ctrl.fijarFiltroRol('auxiliar');
      expect(ctrl.filtrados, [u2]);
    });

    test('actualiza el rol de un usuario exitosamente', () async {
      final ctrl = AdminUsuariosController(_AuthFalso([u1, u2]));
      await ctrl.cargar();

      final exito = await ctrl.cambiarRol(usuarioId: 1, nuevoRol: 'administrador');
      expect(exito, isTrue);
      expect(ctrl.todos.firstWhere((u) => u.id == 1).esAdministrador, isTrue);
    });

    test('maneja error cuando falla la asignación de rol', () async {
      final ctrl = AdminUsuariosController(_AuthFalso(
        [u1],
        fallo: ApiException(TipoError.servidor, 'Fallo al actualizar rol', statusCode: 500),
      ));
      await ctrl.cargar();

      final exito = await ctrl.cambiarRol(usuarioId: 1, nuevoRol: 'auxiliar');
      expect(exito, isFalse);
      expect(ctrl.error, contains('Fallo al actualizar rol'));
    });
  });
}

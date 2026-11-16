import 'package:get_it/get_it.dart';

import '../../shared/foto_perfil.dart';
import '../../features/admin/data/admin_data.dart';
import '../../features/admin/presentation/admin_controllers.dart';
import '../../features/auditoria/auditoria.dart';
import '../../features/auth/data/auth_data.dart';
import '../../features/auth/domain/auth_domain.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/control/presentation/control_controller.dart';
import '../../features/prestamos/data/prestamos_data.dart';
import '../../features/prestamos/domain/repositories/prestamos_repository.dart';
import '../../features/prestamos/presentation/prestamos_controller.dart';
import '../../features/recursos/data/recursos_data.dart';
import '../../features/recursos/data/mantenimiento_data.dart';
import '../../features/recursos/domain/repositories/recursos_repository.dart';
import '../../features/recursos/presentation/recursos_controller.dart';
import '../../features/recursos/presentation/mantenimiento_controller.dart';
import '../../features/salones/data/salones_data.dart';
import '../../features/salones/domain/repositories/salones_repository.dart';
import '../../features/salones/presentation/salones_controller.dart';
import '../../features/salones_admin/data/catalogo_data.dart';
import '../../features/salones_admin/data/disponibilidad_data.dart';
import '../../features/salones_admin/data/salones_admin_data.dart';
import '../../features/salones_admin/domain/catalogo.dart';
import '../../features/salones_admin/domain/disponibilidad.dart';
import '../../features/salones_admin/domain/repositories/salones_admin_repository.dart';
import '../../features/salones_admin/presentation/salones_admin_controller.dart';
import '../../features/solicitudes/data/solicitudes_data.dart';
import '../../features/solicitudes/presentation/solicitudes_controller.dart';
import '../../features/stats/data/stats_data.dart';
import '../../features/stats/presentation/stats_controller.dart';
import '../network/api_client.dart';

final GetIt sl = GetIt.instance;

/// Composición de dependencias (patrón Repositorio + GetIt del Blueprint).
/// Presentación → Dominio (interfaces) ← Datos (implementaciones). La dependencia apunta al centro.
Future<void> configurarDependencias({ApiClient? api}) async {
  await sl.reset();

  sl.registerSingleton<ApiClient>(api ?? ApiClient());

  // Datos
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => RecursosRemoteDataSource(sl()));
  sl.registerLazySingleton(() => MantenimientoRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PrestamosRemoteDataSource(sl()));
  sl.registerLazySingleton(() => SalonesRemoteDataSource(sl()));
  sl.registerLazySingleton(() => SalonesAdminRemoteDataSource(sl()));
  sl.registerLazySingleton(() => StatsRemoteDataSource(sl()));

  // Repositorios (se registran como su interfaz de dominio)
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<RecursosRepository>(
      () => RecursosRepositoryImpl(sl()));
  sl.registerLazySingleton<PrestamosRepository>(
      () => PrestamosRepositoryImpl(sl()));
  sl.registerLazySingleton<SalonesRepository>(
      () => SalonesRepositoryImpl(sl()));
  sl.registerLazySingleton<CatalogoRepository>(() => CatalogoRepositoryImpl(sl()));
  sl.registerLazySingleton<DisponibilidadRepository>(() => DisponibilidadRepositoryImpl(sl()));
  sl.registerLazySingleton<SalonesAdminRepository>(
      () => SalonesAdminRepositoryImpl(sl()));

  // Controladores de estado (uno por sesión de app)
  sl.registerLazySingleton(() => AuthController(sl(), sl()));
  sl.registerLazySingleton(() {
    // Al cerrar sesión se olvidan las fotos descargadas (eran visibles por los permisos de
    // quien estaba conectado).
    final cache = CacheFotos(sl());
    final auth = sl<AuthController>();
    auth.addListener(() {
      if (auth.usuario == null) cache.vaciar();
    });
    return cache;
  });
  // Roles y permisos (ADR-0018): solicitudes por rol y pantallas del administrador.
  sl.registerLazySingleton<SolicitudesRepository>(() => SolicitudesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SolicitudesController(sl(), bandeja: false),
      instanceName: 'mias');
  sl.registerLazySingleton(() => SolicitudesController(sl(), bandeja: true),
      instanceName: 'bandeja');
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()));
  sl.registerLazySingleton(() => UsuariosController(sl()));
  sl.registerFactory(() => AsignacionesController(sl()));
  sl.registerLazySingleton(() => EstadisticasController(sl()));
  sl.registerLazySingleton(() => RecursosController(sl()));
  sl.registerLazySingleton(() => MantenimientoController(sl()));
  sl.registerLazySingleton(() => PrestamosController(sl()));
  sl.registerLazySingleton(() => SalonesController(sl()));
  sl.registerLazySingleton(() => SalonesAdminController(sl()));
  sl.registerLazySingleton(() => StatsController(sl()));
  sl.registerLazySingleton(() => ControlController(sl()));
  sl.registerLazySingleton<AuditoriaRepository>(() => AuditoriaRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AuditoriaController(sl()));
}

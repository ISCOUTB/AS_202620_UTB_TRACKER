import 'package:get_it/get_it.dart';

import '../../features/admin/presentation/admin_usuarios_controller.dart';
import '../../features/auth/data/auth_data.dart';
import '../../features/auth/domain/auth_domain.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/prestamos/data/prestamos_data.dart';
import '../../features/prestamos/domain/repositories/prestamos_repository.dart';
import '../../features/prestamos/presentation/prestamos_controller.dart';
import '../../features/recursos/data/recursos_data.dart';
import '../../features/recursos/domain/repositories/recursos_repository.dart';
import '../../features/recursos/presentation/recursos_controller.dart';
import '../../features/salones/data/salones_data.dart';
import '../../features/salones/domain/repositories/salones_repository.dart';
import '../../features/salones/presentation/salones_controller.dart';
import '../../features/salones_admin/data/salones_admin_data.dart';
import '../../features/salones_admin/domain/repositories/salones_admin_repository.dart';
import '../../features/salones_admin/presentation/salones_admin_controller.dart';
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
  sl.registerLazySingleton(() => PrestamosRemoteDataSource(sl()));
  sl.registerLazySingleton(() => SalonesRemoteDataSource(sl()));
  sl.registerLazySingleton(() => SalonesAdminRemoteDataSource(sl()));

  // Repositorios (se registran como su interfaz de dominio)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<RecursosRepository>(() => RecursosRepositoryImpl(sl()));
  sl.registerLazySingleton<PrestamosRepository>(() => PrestamosRepositoryImpl(sl()));
  sl.registerLazySingleton<SalonesRepository>(() => SalonesRepositoryImpl(sl()));
  sl.registerLazySingleton<SalonesAdminRepository>(() => SalonesAdminRepositoryImpl(sl()));

  // Controladores de estado (uno por sesión de app)
  sl.registerLazySingleton(() => AuthController(sl(), sl()));
  sl.registerLazySingleton(() => AdminUsuariosController(sl()));
  sl.registerLazySingleton(() => RecursosController(sl()));
  sl.registerLazySingleton(() => PrestamosController(sl()));
  sl.registerLazySingleton(() => SalonesController(sl()));
  sl.registerLazySingleton(() => SalonesAdminController(sl()));
}

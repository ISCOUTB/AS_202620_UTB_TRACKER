# Graph Report - AS_202620_UTB_TRACKER  (2026-10-26)

## Corpus Check
- 166 files · ~75,056 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 27 file(s) not represented in the graph (top: (none) 7, .xml 7, .properties 3)

## Summary
- 2197 nodes · 3601 edges · 143 communities (111 shown, 32 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 129 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bf1debcd`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- Usuario
- Recurso
- routers/salones_admin.py
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- NotificadorSimulado
- UTB Tracker
- Escenarios de calidad
- logging_middleware
- Ficha del problema — UTB Tracker
- arc42.md
- routers/auth.py
- test_loans.py
- routers/horarios.py
- resilience.py
- test_resources.py
- salon_detalle_page.dart
- test_messaging.py
- c4_nivel1.md
- run.sh
- widgets.dart
- crear_recurso_page.dart
- worker.py
- app_theme.dart
- home_page.dart
- actividad_page.dart
- salon.dart
- controladores_test.dart
- recursos_controller.dart
- panel_administrativo_page.dart
- equipos_page.dart
- solicitar_prestamo_sheet.dart
- recurso_detalle_page.dart
- main.py
- demo_mensajeria.py
- obtener_disponibilidad
- salones_page.dart
- test_auth.py
- shell_page.dart
- listar_prestamos
- with
- auth_controller.dart
- recurso.dart
- auth_data.dart
- utilidades.dart
- ocupacion.dart
- api_client.dart
- login_page.dart
- salones_data.dart
- pubspec.yaml
- api_client_test.dart
- injection.dart
- services/salones.py
- salones_controller.dart
- admin_usuarios_controller.dart
- prestamos_controller.dart
- auth_domain.dart
- PayloadPrestamoCreado
- services/prestamos_salon.py
- listar_prestamos_salon
- prestamos_data.dart
- StatefulWidget
- recursos_data.dart
- salones_repository.dart
- api_exception.dart
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- prestamo.dart
- test_horarios.py
- routers/salones.py
- token_storage.dart
- mensajeria/README.md
- salon_control_page.dart
- Cómo Ejecutar en PowerShell (Comandos Reales)
- recursos_repository.dart
- api_config.dart
- prestamos_repository.dart
- UTB Tracker — app móvil (Flutter)
- analysis_options.yaml
- 0001 - Estilo arquitectónico: Monolito Modular
- 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)
- ADR-0004: Seguridad y Autenticación — JWT Autofirmado
- ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios
- Estrategia de solución
- Introducción y objetivos
- Contexto y alcance
- FlutterActivity
- get_db
- salon_control_controller.dart
- services/salones_admin.py
- salones_admin_controller.dart
- salones_admin_test.dart
- StatelessWidget
- services/auth.py
- salones_admin_data.dart
- win32_window.cpp
- FlutterWindow
- State
- sqlalchemy
- filtros_sheet.dart
- uber_widgets.dart
- test_salones_admin.py
- health_check
- plano_salones.dart
- reporte_salon_sheet.dart
- utils.cpp
- salones_admin_estilos.dart
- Win32Window
- NotificadorBase
- test_performance.py
- salones_admin_repository.dart
- manifest.json
- test_main.py
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- .MessageHandler
- Aspectos — UTB Tracker
- security.py
- flutter_window.cpp
- require_role
- SalonesAdminRepository
- Point
- Size

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 54 edges
2. `Usuario` - 31 edges
3. `MensajeOutbox` - 25 edges
4. `Win32Window` - 21 edges
5. `procesar_pendientes()` - 19 edges
6. `Horario` - 18 edges
7. `NotificadorSimulado` - 17 edges
8. `Salon` - 17 edges
9. `_procesar_un_mensaje()` - 15 edges
10. `PrestamoSalon` - 15 edges

## Surprising Connections (you probably didn't know these)
- `8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6)` --references--> `CircuitBreaker`  [INFERRED]
  docs/arc42/arc42.md → app/core/resilience.py
- `2.2 Campos del Payload (`PayloadPrestamoCreado`)` --references--> `PayloadPrestamoCreado`  [INFERRED]
  docs/mensajeria/contrato-prestamo-creado.md → app/messaging/events.py
- `4. Requisitos para Transición a Producción` --references--> `NotificadorBase`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py
- `1. Simplificaciones Asumidas en el Diseño` --references--> `NotificadorSimulado`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py
- `2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial` --references--> `_calcular_siguiente_intento()`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py

## Import Cycles
- None detected.

## Communities (143 total, 32 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.25
Nodes (8): Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View, Vista de ejecución

### Community 1 - "Usuario"
Cohesion: 0.12
Nodes (13): Usuario, IdempotenciaRegistro, Prestamo, Recurso, Reporte, Riesgos y deudas técnicas, main(), utc() (+5 more)

### Community 2 - "Recurso"
Cohesion: 0.25
Nodes (8): Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, Vista general del sistema, White Box *prestamos*, White Box *recursos*

### Community 3 - "routers/salones_admin.py"
Cohesion: 0.06
Nodes (35): actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), obtener_ocupacion(), registrar_presencia(), CategoriaRecurso, DiaSemana (+27 more)

### Community 4 - "with"
Cohesion: 0.06
Nodes (34): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+26 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 6 - "NotificadorSimulado"
Cohesion: 0.13
Nodes (10): NotificadorSimulado, _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo(), test_mensaje_muerto_al_superar_max_intentos(), test_rechazo_explicito_si_version_de_contrato_no_soportada(), test_reintentos_backoff_exponencial_sin_sleep() (+2 more)

### Community 7 - "UTB Tracker"
Cohesion: 0.22
Nodes (8): Base de datos, Corte vertical ejecutable (S4), Cómo arrancar (un solo comando), Estructura (Monolito Modular), Prueba automatizada (misma regla, sin necesidad de tener el servidor corriendo a mano):, Prueba manual (con el servidor corriendo):, Pruebas, UTB Tracker

### Community 8 - "Escenarios de calidad"
Cohesion: 0.17
Nodes (10): Descripción general de los requisitos de calidad, Escenarios de calidad, QS-01 — Disponibilidad, QS-02 — Rendimiento (tiempo de respuesta), QS-03 — Rendimiento (concurrencia), QS-04 — Seguridad, QS-05 — Usabilidad, QS-06 — Confiabilidad de los datos (+2 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.20
Nodes (5): Decisiones arquitectónicas, Restricciones arquitectónicas, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "routers/auth.py"
Cohesion: 0.11
Nodes (15): delete_user_endpoint(), get_user_endpoint(), get_users_endpoint(), login_endpoint(), me_endpoint(), register_endpoint(), update_user_role_endpoint(), TokenResponse (+7 more)

### Community 13 - "test_loans.py"
Cohesion: 0.29
Nodes (5): _crear_recurso(), test_devolver_prestamo(), test_devolver_prestamo_ya_devuelto_rechaza(), test_no_permite_prestar_recurso_no_disponible(), test_prestamo_exitoso_cambia_estado_del_recurso()

### Community 14 - "routers/horarios.py"
Cohesion: 0.08
Nodes (19): Horario, actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate (+11 more)

### Community 15 - "resilience.py"
Cohesion: 0.06
Nodes (23): CircuitBreaker, wrapper(), CircuitBreakerOpenException, CircuitBreakerState, with_retry(), decorator(), wrapper(), 8.1 Patrón de Capas y Control de Erosión Arquitectónica (+15 more)

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.06
Nodes (34): _abrirAgregarHorario, _abrirSolicitudPrestamo, _auth, build, _cambiarDia, _cargandoDatos, _cargarTodo, createState (+26 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.14
Nodes (11): MensajeOutbox, _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker(), test_idempotencia_http_con_x_idempotency_key(), test_outbox_se_inserta_en_misma_transaccion_que_prestamo(), test_rollback_no_deja_mensaje_en_outbox(), test_rollback_real_forzando_fallo_en_commit() (+3 more)

### Community 23 - "widgets.dart"
Cohesion: 0.07
Nodes (22): accion, build, child, color, colorDeEstado, colorDePrestamo, detalle, figura (+14 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.09
Nodes (21): AdminUsuariosController, PrestamosController, build, _categoria, CrearRecursoPage, _CrearRecursoPageState, createState, dispose (+13 more)

### Community 25 - "worker.py"
Cohesion: 0.18
Nodes (7): _calcular_siguiente_intento(), _marcar_muerto(), procesar_pendientes(), _procesar_un_mensaje(), _resolver_email(), _run_loop(), 2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial

### Community 26 - "app_theme.dart"
Cohesion: 0.06
Nodes (28): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+20 more)

### Community 27 - "home_page.dart"
Cohesion: 0.07
Nodes (29): _abrirFiltros, _alcance, _auth, _buscar, controlador, createState, _DatosTarjeta, detalle (+21 more)

### Community 28 - "actividad_page.dart"
Cohesion: 0.09
Nodes (19): ActividadPage, _ActividadPageState, ahora, _alcance, _auth, _confirmarDevolucion, createState, _cuerpo (+11 more)

### Community 29 - "salon.dart"
Cohesion: 0.07
Nodes (27): activo, capacidad, createdAt, diaNombre, diaSemana, disponible, edificio, estado (+19 more)

### Community 30 - "controladores_test.dart"
Cohesion: 0.07
Nodes (18): actualizarRolUsuario, crear, datos, devolver, fallo, iniciarSesion, listar, listarUsuarios (+10 more)

### Community 31 - "recursos_controller.dart"
Cohesion: 0.08
Nodes (23): _busqueda, _carga, cargar, _categoria, crear, disponiblesDe, _error, _estado (+15 more)

### Community 32 - "panel_administrativo_page.dart"
Cohesion: 0.09
Nodes (16): _abrirCambiarRol, _auth, build, _busquedaCtrl, _controller, createState, dispose, initState (+8 more)

### Community 33 - "equipos_page.dart"
Cohesion: 0.09
Nodes (19): build, build, build, _auth, build, _buscar, _ChipsActivos, createState (+11 more)

### Community 34 - "solicitar_prestamo_sheet.dart"
Cohesion: 0.08
Nodes (24): _auth, _authRepo, build, _buscando, _buscarPrestatario, _clave, _confirmar, createState (+16 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.09
Nodes (22): build, createState, _Dato, _descCtrl, dispose, _enviando, _enviar, _estado (+14 more)

### Community 37 - "demo_mensajeria.py"
Cohesion: 0.22
Nodes (5): NotificacionProcesada, PrestamoCreate, crear_prestamo(), main(), setup_logger()

### Community 38 - "obtener_disponibilidad"
Cohesion: 0.13
Nodes (6): actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon()

### Community 39 - "salones_page.dart"
Cohesion: 0.09
Nodes (21): _abrirCrearSalon, _auth, _busquedaCtrl, _capacidadCtrl, _construirCuerpo, _CrearSalonSheet, _CrearSalonSheetState, createState (+13 more)

### Community 40 - "test_auth.py"
Cohesion: 0.08
Nodes (7): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_registro_fuerza_rol_usuario_utb()

### Community 41 - "shell_page.dart"
Cohesion: 0.09
Nodes (15): _BarraPildora, build, createState, _filtroActividad, _indice, initState, _ir, _items (+7 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.12
Nodes (5): crear_prestamo(), devolver_prestamo(), listar_prestamos(), devolver_prestamo(), listar_prestamos()

### Community 43 - "with"
Cohesion: 0.09
Nodes (21): defaults, runs-on, steps, run, jobs, build, name, permissions (+13 more)

### Community 44 - "auth_controller.dart"
Cohesion: 0.10
Nodes (16): _api, autenticado, _cargando, cerrarSesion, comprobarServidor, _ejecutar, _error, esAdministrador (+8 more)

### Community 45 - "recurso.dart"
Cohesion: 0.09
Nodes (17): categoria, categoriaCodigo, CategoriaRecurso, codigo, creables, desde, disponible, estado (+9 more)

### Community 46 - "auth_data.dart"
Cohesion: 0.10
Nodes (19): actualizarRolUsuario, _api, AuthRemoteDataSource, desdeJson, _identificar, iniciarSesion, _intentarUsuario, listarUsuarios (+11 more)

### Community 47 - "utilidades.dart"
Cohesion: 0.10
Nodes (20): abs, azar, bytes, cantidad, d, describirPlazo, _dos, endsWith (+12 more)

### Community 48 - "ocupacion.dart"
Cohesion: 0.05
Nodes (41): abierto, clase, ClaseActual, creadoEn, descripcion, desde, enUso, estado (+33 more)

### Community 49 - "api_client.dart"
Cohesion: 0.10
Nodes (14): _azar, _baseUrl, _cabeceras, cerrar, _client, _conReintentos, delete, _enviar (+6 more)

### Community 50 - "login_page.dart"
Cohesion: 0.06
Nodes (29): accion, _auth, autofill, build, _cambiarModo, clave, _continuar, controller (+21 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.10
Nodes (17): actualizarEstadoPrestamo, _api, consultarDisponibilidad, crearHorario, crearSalon, desdeJson, FranjaDisponibleModel, HorarioModel (+9 more)

### Community 52 - "pubspec.yaml"
Cohesion: 0.10
Nodes (19): dependencies, flutter, flutter_svg, get_it, http, description, dev_dependencies, flutter_lints (+11 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.13
Nodes (6): ApiException, _json, main, _json, main, main

### Community 54 - "injection.dart"
Cohesion: 0.09
Nodes (3): configurarDependencias, reset, sl

### Community 55 - "services/salones.py"
Cohesion: 0.18
Nodes (7): Salon, actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon()

### Community 56 - "salones_controller.dart"
Cohesion: 0.12
Nodes (13): agregarHorario, _busqueda, _carga, cargar, crear, _error, fijarBusqueda, obtenerDisponibilidad (+5 more)

### Community 57 - "admin_usuarios_controller.dart"
Cohesion: 0.11
Nodes (12): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+4 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.10
Nodes (18): Carga, _carga, cargar, deUsuario, devolver, error, exito, fallo (+10 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.10
Nodes (18): AuthRepositoryImpl, actualizarRolUsuario, AuthRepository, email, id, iniciarSesion, listarUsuarios, nombre (+10 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.13
Nodes (12): EventoPrestamoCreado, PayloadPrestamoCreado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`), 2. Estructura Canónica del Mensaje, 3. Ejemplo Real de Mensaje JSON, 4.1 Cambios Compatibles hacia Atrás (Aditivos) (+4 more)

### Community 61 - "services/prestamos_salon.py"
Cohesion: 0.23
Nodes (8): PrestamoSalon, actualizar_estado_prestamo_salon(), crear_prestamo_salon(), _detectar_conflicto_horario(), _detectar_conflicto_prestamo(), listar_prestamos_salon(), _validar_salon(), _validar_usuario()

### Community 62 - "listar_prestamos_salon"
Cohesion: 0.11
Nodes (6): actualizar_estado_prestamo_salon(), crear_prestamo_salon(), listar_prestamos_salon(), PrestamoSalonCreate, PrestamoSalonResponse, PrestamoSalonUpdate

### Community 63 - "prestamos_data.dart"
Cohesion: 0.15
Nodes (9): ApiClient, _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource (+1 more)

### Community 64 - "StatefulWidget"
Cohesion: 0.13
Nodes (9): _auth, build, createState, initState, _Raiz, _RaizState, UtbTrackerApp, configurarDependencias (+1 more)

### Community 65 - "recursos_data.dart"
Cohesion: 0.15
Nodes (9): _api, crear, desdeJson, listar, obtener, RecursoModel, RecursosRemoteDataSource, _remoto (+1 more)

### Community 66 - "salones_repository.dart"
Cohesion: 0.15
Nodes (11): SalonesRepositoryImpl, actualizarEstadoPrestamo, consultarDisponibilidad, crearHorario, crearSalon, listarHorarios, listarPrestamosSalon, listarSalones (+3 more)

### Community 67 - "api_exception.dart"
Cohesion: 0.18
Nodes (10): _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado, tipo (+2 more)

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.07
Nodes (22): _abrir, _actualizado, _auth, _Aviso, build, _c, _Cabecera, _cargar (+14 more)

### Community 70 - "prestamo.dart"
Cohesion: 0.17
Nodes (10): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+2 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "routers/salones.py"
Cohesion: 0.39
Nodes (5): FranjaDisponible, SalonConDisponibilidad, SalonCreate, SalonResponse, SalonUpdate

### Community 73 - "token_storage.dart"
Cohesion: 0.20
Nodes (6): _archivo, borrarToken, guardarToken, leerToken, _memoriaToken, TokenStorage

### Community 74 - "mensajeria/README.md"
Cohesion: 0.25
Nodes (7): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller)

### Community 76 - "salon_control_page.dart"
Cohesion: 0.07
Nodes (24): acciones, autor, build, _c, cantidad, _colorDeSolicitud, _confirmar, createState (+16 more)

### Community 77 - "Cómo Ejecutar en PowerShell (Comandos Reales)"
Cohesion: 0.22
Nodes (9): 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas), 2. Ejecutar la suite de pruebas de contrato congelado, 3. Ejecutar la demostración interactiva de punta a punta (con base temporal aislada), 4. Ejecutar el worker de polling en modo standalone, Cómo Ejecutar en PowerShell (Comandos Reales), Descripción de la Solución en una Frase, Enlace al Commit, Módulo de Mensajería Asíncrona (Transactional Outbox) (+1 more)

### Community 78 - "recursos_repository.dart"
Cohesion: 0.22
Nodes (7): RecursosRepositoryImpl, crear, listar, obtener, RecursosRepository, reportar, _RecursosFalso

### Community 79 - "api_config.dart"
Cohesion: 0.22
Nodes (5): ApiConfig, _override, reintentosLectura, servidorProduccion, timeout

### Community 80 - "prestamos_repository.dart"
Cohesion: 0.25
Nodes (6): PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository, _PrestamosFalso

### Community 81 - "UTB Tracker — app móvil (Flutter)"
Cohesion: 0.13
Nodes (13): 0007 - Administración de salones: ocupación en vivo, presencia del profesor y reportes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Arquitectura (Clean Architecture, Blueprint FastAPI + Flutter), Banderas útiles (+5 more)

### Community 82 - "analysis_options.yaml"
Cohesion: 0.29
Nodes (6): analyzer, exclude, include, linter, rules, prefer_single_quotes

### Community 83 - "0001 - Estilo arquitectónico: Monolito Modular"
Cohesion: 0.33
Nodes (6): 0001 - Estilo arquitectónico: Monolito Modular, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 84 - "0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)"
Cohesion: 0.33
Nodes (6): 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 85 - "ADR-0004: Seguridad y Autenticación — JWT Autofirmado"
Cohesion: 0.33
Nodes (6): ADR-0004: Seguridad y Autenticación — JWT Autofirmado, Alternativas evaluadas, Consecuencias, Contexto, Decisión, Estado

### Community 86 - "ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios"
Cohesion: 0.33
Nodes (6): ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios, Alternativas evaluadas, Consecuencias, Contexto, Decisión, Estado

### Community 87 - "Estrategia de solución"
Cohesion: 0.50
Nodes (4): Cómo se logran los objetivos de calidad principales, Decisiones tecnológicas, Decisión de estilo arquitectónico, Estrategia de solución

### Community 88 - "Introducción y objetivos"
Cohesion: 0.50
Nodes (4): Descripción general de los requisitos, Introducción y objetivos, Objetivos de calidad, Stakeholders

### Community 89 - "Contexto y alcance"
Cohesion: 0.67
Nodes (3): Contexto de negocio, Contexto técnico, Contexto y alcance

### Community 102 - "get_db"
Cohesion: 0.09
Nodes (14): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso(), actualizar_recurso() (+6 more)

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.08
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "services/salones_admin.py"
Cohesion: 0.23
Nodes (14): PresenciaSalon, ReporteSalon, _a_utc_naive(), actualizar_estado_reporte(), _ahora_campus(), _clase_en_curso(), crear_reporte(), listar_ocupacion() (+6 more)

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.10
Nodes (18): _busqueda, _carga, cargar, _coincide, contar, _error, etiqueta, fijarBusqueda (+10 more)

### Community 106 - "salones_admin_test.dart"
Cohesion: 0.10
Nodes (10): _clase, fallo, _json, listarOcupacion, main, ocupaciones, _ocupacionJson, registrarPresencia (+2 more)

### Community 107 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): _CajaError, _CampoUber, _Marca, _MedidorClave, _Selector, _Buscador, _Cabecera, _Carrusel (+10 more)

### Community 108 - "services/auth.py"
Cohesion: 0.14
Nodes (9): hash_password(), verify_password(), create_user(), get_all_users(), get_me(), get_user_by_id(), login(), logout() (+1 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.11
Nodes (15): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+7 more)

### Community 110 - "win32_window.cpp"
Cohesion: 0.18
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "FlutterWindow"
Cohesion: 0.17
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 112 - "State"
Cohesion: 0.17
Nodes (14): LoginPage, _LoginPageState, PanelSalonesPage, _PanelSalonesPageState, _ReporteSalonSheet, _ReporteSalonSheetState, SalonControlPage, _SalonControlPageState (+6 more)

### Community 113 - "sqlalchemy"
Cohesion: 0.16
Nodes (5): downgrade(), upgrade(), upgrade(), upgrade(), upgrade()

### Community 114 - "filtros_sheet.dart"
Cohesion: 0.12
Nodes (13): build, _categoria, createState, _estado, _FiltrosSheet, _FiltrosSheetState, kTodosLosSalones, mostrarFiltros (+5 more)

### Community 115 - "uber_widgets.dart"
Cohesion: 0.11
Nodes (15): AsaHoja, AvatarIniciales, BotonPildora, build, cargando, color, compacto, estilo (+7 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.21
Nodes (13): _salon_con_clase(), test_confirmar_presencia_se_refleja_en_la_ocupacion(), test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(), test_listar_ocupacion_incluye_todos_los_salones(), test_presencia_requiere_rol_administrador(), test_presencia_se_puede_corregir_sin_duplicar(), test_presencia_sin_clase_en_curso_da_409(), test_prestamo_aprobado_muestra_quien_tiene_el_salon() (+5 more)

### Community 118 - "plano_salones.dart"
Cohesion: 0.13
Nodes (10): _Baldosa, build, _CuadriculaPainter, ocupacion, onTap, paint, PlanoSalones, _porEdificio (+2 more)

### Community 119 - "reporte_salon_sheet.dart"
Cohesion: 0.13
Nodes (10): build, createState, _descripcion, dispose, _enviando, _enviar, _error, mostrarReporteSalonSheet (+2 more)

### Community 120 - "utils.cpp"
Cohesion: 0.13
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 121 - "salones_admin_estilos.dart"
Cohesion: 0.18
Nodes (9): colorDeSituacion, _colorPrestado, d, _dos, etiquetaDeSituacion, formatearHora, h12, haceCuanto (+1 more)

### Community 122 - "Win32Window"
Cohesion: 0.21
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 123 - "NotificadorBase"
Cohesion: 0.22
Nodes (5): NotificadorBase, 1. Simplificaciones Asumidas en el Diseño, 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa, 4. Requisitos para Transición a Producción, Límites del Experimento: Mensajería Asíncrona

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.18
Nodes (8): cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, obtenerOcupacion, registrarPresencia

### Community 126 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.17
Nodes (11): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login pide NOMBRE + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Pruebas, 7. Problemas comunes (+3 more)

### Community 130 - "Aspectos — UTB Tracker"
Cohesion: 0.25
Nodes (8): A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar, A-05 · Declarar, A-06 · Declarar, Aspectos — UTB Tracker, Especificar (escenarios medibles)

### Community 131 - "security.py"
Cohesion: 0.19
Nodes (5): get_current_user(), create_access_token(), create_reset_password_token(), verify_reset_password_token(), verify_token()

### Community 135 - "SalonesAdminRepository"
Cohesion: 0.50
Nodes (3): SalonesAdminRepositoryImpl, SalonesAdminRepository, _RepoFalso

### Community 136 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 137 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **766 isolated node(s):** `_auth`, `build`, `createState`, `initState`, `Figuras` (+761 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1386 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `get_db()` connect `main.py` to `Usuario`, `security.py`, `routers/salones_admin.py`, `get_db`, `obtener_disponibilidad`, `listar_prestamos`, `routers/auth.py`, `routers/horarios.py`, `test_messaging.py`, `health_check`, `listar_prestamos_salon`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_auth`, `build`, `createState` to the rest of the system?**
  _766 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Usuario` be split into smaller, more focused modules?**
  _Cohesion score 0.12043010752688173 - nodes in this community are weakly interconnected._
- **Why does `Riesgos y deudas técnicas` connect `Usuario` to `arc42.md`?**
  _High betweenness centrality (0.065) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Should `routers/salones_admin.py` be split into smaller, more focused modules?**
  _Cohesion score 0.0642243328810493 - nodes in this community are weakly interconnected._
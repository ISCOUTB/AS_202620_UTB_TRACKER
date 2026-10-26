# Graph Report - AS_202620_UTB_TRACKER  (2026-10-26)

## Corpus Check
- 170 files · ~81,094 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 27 file(s) not represented in the graph (top: (none) 7, .xml 7, .properties 3)

## Summary
- 2252 nodes · 3666 edges · 146 communities (117 shown, 29 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 132 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ea2a0306`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- Usuario
- Recurso
- routers/salones_admin.py
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- demo_mensajeria.py
- UTB Tracker
- Escenarios de calidad
- logging_middleware
- Ficha del problema — UTB Tracker
- arc42.md
- services/auth.py
- test_loans.py
- routers/horarios.py
- CircuitBreaker
- test_resources.py
- salon_detalle_page.dart
- test_messaging.py
- c4_nivel1.md
- run.sh
- widgets.dart
- crear_recurso_page.dart
- Diseño de Estrategia de Caché e Invalidación — UTB Tracker
- app_theme.dart
- home_page.dart
- actividad_page.dart
- salon.dart
- controladores_test.dart
- recursos_controller.dart
- package:flutter/material.dart
- equipos_page.dart
- solicitar_prestamo_sheet.dart
- recurso_detalle_page.dart
- main.py
- update_user_role_endpoint
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
- routers/auth.py
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
- conftest.py
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
- test_resilience.py
- salones_admin_data.dart
- win32_window.cpp
- FlutterWindow
- State
- sqlalchemy
- filtros_sheet.dart
- uber_widgets.dart
- test_salones_admin.py
- plano_salones.dart
- reporte_salon_sheet.dart
- utils.cpp
- salones_admin_estilos.dart
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- NotificadorBase
- get_user_endpoint
- salones_admin_repository.dart
- manifest.json
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- .MessageHandler
- Aspectos — UTB Tracker
- security.py
- flutter_window.cpp
- Conceptos transversales (Cross-cutting Concepts)
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- test_circuit_breaker_transiciones_de_estado
- Point
- resilience.py
- devolver_prestamo
- 4. Brechas Conocidas y Mejoras Propuestas
- SalonesAdminRepository

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 54 edges
2. `Usuario` - 31 edges
3. `MensajeOutbox` - 25 edges
4. `Win32Window` - 21 edges
5. `procesar_pendientes()` - 19 edges
6. `Horario` - 18 edges
7. `NotificadorSimulado` - 17 edges
8. `Salon` - 17 edges
9. `PrestamoSalon` - 16 edges
10. `_procesar_un_mensaje()` - 15 edges

## Surprising Connections (you probably didn't know these)
- `8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6)` --references--> `CircuitBreaker`  [INFERRED]
  docs/arc42/arc42.md → app/core/resilience.py
- `2. Matriz de Operaciones y Garantías de Consistencia` --references--> `PrestamoSalon`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/models/salon_models.py
- `2.2 Campos del Payload (`PayloadPrestamoCreado`)` --references--> `PayloadPrestamoCreado`  [INFERRED]
  docs/mensajeria/contrato-prestamo-creado.md → app/messaging/events.py
- `4. Requisitos para Transición a Producción` --references--> `NotificadorBase`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py
- `1. Simplificaciones Asumidas en el Diseño` --references--> `NotificadorSimulado`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py

## Import Cycles
- None detected.

## Communities (146 total, 29 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.25
Nodes (8): Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View, Vista de ejecución

### Community 1 - "Usuario"
Cohesion: 0.18
Nodes (9): require_role(), Usuario, IdempotenciaRegistro, Prestamo, Recurso, Reporte, Riesgos y deudas técnicas, main() (+1 more)

### Community 2 - "Recurso"
Cohesion: 0.25
Nodes (8): Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, Vista general del sistema, White Box *prestamos*, White Box *recursos*

### Community 3 - "routers/salones_admin.py"
Cohesion: 0.11
Nodes (17): actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), obtener_ocupacion(), registrar_presencia(), EstadoReporteSalon, ClaseActual (+9 more)

### Community 4 - "with"
Cohesion: 0.06
Nodes (34): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+26 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 6 - "demo_mensajeria.py"
Cohesion: 0.13
Nodes (10): MensajeOutbox, NotificacionProcesada, _marcar_muerto(), procesar_pendientes(), _procesar_un_mensaje(), _resolver_email(), _run_loop(), crear_prestamo() (+2 more)

### Community 7 - "UTB Tracker"
Cohesion: 0.22
Nodes (8): Base de datos, Corte vertical ejecutable (S4), Cómo arrancar (un solo comando), Estructura (Monolito Modular), Prueba automatizada (misma regla, sin necesidad de tener el servidor corriendo a mano):, Prueba manual (con el servidor corriendo):, Pruebas, UTB Tracker

### Community 8 - "Escenarios de calidad"
Cohesion: 0.17
Nodes (10): Descripción general de los requisitos de calidad, Escenarios de calidad, QS-01 — Disponibilidad, QS-02 — Rendimiento (tiempo de respuesta), QS-03 — Rendimiento (concurrencia), QS-04 — Seguridad, QS-05 — Usabilidad, QS-06 — Confiabilidad de los datos (+2 more)

### Community 9 - "logging_middleware"
Cohesion: 0.20
Nodes (3): logging_middleware(), health_check(), Tabla de trazabilidad

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.19
Nodes (5): Decisiones arquitectónicas, Restricciones arquitectónicas, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "services/auth.py"
Cohesion: 0.17
Nodes (9): verify_password(), delete_user(), get_all_users(), get_me(), get_user_by_id(), login(), logout(), update_user_role() (+1 more)

### Community 13 - "test_loans.py"
Cohesion: 0.29
Nodes (5): _crear_recurso(), test_devolver_prestamo(), test_devolver_prestamo_ya_devuelto_rechaza(), test_no_permite_prestar_recurso_no_disponible(), test_prestamo_exitoso_cambia_estado_del_recurso()

### Community 14 - "routers/horarios.py"
Cohesion: 0.08
Nodes (19): Horario, actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate (+11 more)

### Community 15 - "CircuitBreaker"
Cohesion: 0.19
Nodes (7): CircuitBreaker, wrapper(), decorator(), wrapper(), Formato, Registro, Uso de IA - Tractar

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.06
Nodes (34): _abrirAgregarHorario, _abrirSolicitudPrestamo, _auth, build, _cambiarDia, _cargandoDatos, _cargarTodo, createState (+26 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.07
Nodes (20): NotificadorSimulado, _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo(), _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker() (+12 more)

### Community 23 - "widgets.dart"
Cohesion: 0.07
Nodes (22): accion, build, child, color, colorDeEstado, colorDePrestamo, detalle, figura (+14 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.11
Nodes (15): build, _categoria, CrearRecursoPage, _CrearRecursoPageState, createState, dispose, _error, _form (+7 more)

### Community 25 - "Diseño de Estrategia de Caché e Invalidación — UTB Tracker"
Cohesion: 0.11
Nodes (18): 1.1 Regla Central de Oro (Aislamiento de Invariantes), 1.2 Endpoints Incluidos en Caché, 1.3 Endpoints Excluidos de Caché, 1. Alcance y Reglas de Integridad, 2.1 En Proceso vs. Redis Distribuido, 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia, 2. Topología de Caché y Decisión de Ubicación, 3.1 Formato Canónico de Claves (+10 more)

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

### Community 32 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (14): AdminUsuariosController, _abrirCambiarRol, _auth, build, _busquedaCtrl, _controller, createState, dispose (+6 more)

### Community 33 - "equipos_page.dart"
Cohesion: 0.09
Nodes (19): build, build, build, _auth, build, _buscar, _ChipsActivos, createState (+11 more)

### Community 34 - "solicitar_prestamo_sheet.dart"
Cohesion: 0.08
Nodes (24): _auth, _authRepo, build, _buscando, _buscarPrestatario, _clave, _confirmar, createState (+16 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.09
Nodes (22): build, createState, _Dato, _descCtrl, dispose, _enviando, _enviar, _estado (+14 more)

### Community 36 - "main.py"
Cohesion: 0.14
Nodes (3): PrestamoSalonCreate, PrestamoSalonResponse, PrestamoSalonUpdate

### Community 37 - "update_user_role_endpoint"
Cohesion: 0.20
Nodes (5): delete_user_endpoint(), get_users_endpoint(), login_endpoint(), register_endpoint(), update_user_role_endpoint()

### Community 38 - "obtener_disponibilidad"
Cohesion: 0.08
Nodes (16): get_db(), actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon(), FranjaDisponible (+8 more)

### Community 39 - "salones_page.dart"
Cohesion: 0.09
Nodes (21): _abrirCrearSalon, _auth, _busquedaCtrl, _capacidadCtrl, _construirCuerpo, _CrearSalonSheet, _CrearSalonSheetState, createState (+13 more)

### Community 40 - "test_auth.py"
Cohesion: 0.08
Nodes (7): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_registro_fuerza_rol_usuario_utb()

### Community 41 - "shell_page.dart"
Cohesion: 0.07
Nodes (19): AuthController, _BarraPildora, build, createState, _filtroActividad, _indice, initState, _ir (+11 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.16
Nodes (3): crear_prestamo(), devolver_prestamo(), listar_prestamos()

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
Nodes (31): accion, _auth, autofill, build, _cambiarModo, clave, _continuar, controller (+23 more)

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

### Community 55 - "routers/auth.py"
Cohesion: 0.27
Nodes (7): TokenResponse, UserMeResponse, UserResponse, UsuarioCreate, UsuarioDelete, UsuarioLogin, UsuarioRoleUpdate

### Community 56 - "salones_controller.dart"
Cohesion: 0.12
Nodes (14): Carga, agregarHorario, _busqueda, _carga, cargar, crear, _error, fijarBusqueda (+6 more)

### Community 57 - "admin_usuarios_controller.dart"
Cohesion: 0.13
Nodes (12): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+4 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.11
Nodes (17): _carga, cargar, deUsuario, devolver, error, exito, fallo, filtrarPorEstado (+9 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.10
Nodes (18): AuthRepositoryImpl, actualizarRolUsuario, AuthRepository, email, id, iniciarSesion, listarUsuarios, nombre (+10 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.16
Nodes (12): EventoPrestamoCreado, PayloadPrestamoCreado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`), 2. Estructura Canónica del Mensaje, 3. Ejemplo Real de Mensaje JSON, 4.1 Cambios Compatibles hacia Atrás (Aditivos) (+4 more)

### Community 61 - "services/prestamos_salon.py"
Cohesion: 0.19
Nodes (9): PrestamoSalon, Salon, actualizar_estado_prestamo_salon(), crear_prestamo_salon(), _detectar_conflicto_horario(), _detectar_conflicto_prestamo(), listar_prestamos_salon(), _validar_salon() (+1 more)

### Community 62 - "listar_prestamos_salon"
Cohesion: 0.15
Nodes (3): actualizar_estado_prestamo_salon(), crear_prestamo_salon(), listar_prestamos_salon()

### Community 63 - "prestamos_data.dart"
Cohesion: 0.15
Nodes (9): ApiClient, _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource (+1 more)

### Community 64 - "StatefulWidget"
Cohesion: 0.20
Nodes (5): _auth, build, createState, initState, UtbTrackerApp

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
Nodes (24): _abrir, _actualizado, _auth, build, _c, _cargar, controller, createState (+16 more)

### Community 70 - "prestamo.dart"
Cohesion: 0.17
Nodes (10): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+2 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "conftest.py"
Cohesion: 0.12
Nodes (7): hash_password(), create_user(), admin_headers(), auth_headers(), client(), db_session(), _get_token()

### Community 73 - "token_storage.dart"
Cohesion: 0.20
Nodes (6): _archivo, borrarToken, guardarToken, leerToken, _memoriaToken, TokenStorage

### Community 74 - "mensajeria/README.md"
Cohesion: 0.22
Nodes (7): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller)

### Community 76 - "salon_control_page.dart"
Cohesion: 0.07
Nodes (26): acciones, autor, build, _c, cantidad, _colorDeSolicitud, _confirmar, createState (+18 more)

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
Cohesion: 0.05
Nodes (35): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso(), CategoriaRecurso (+27 more)

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.08
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "services/salones_admin.py"
Cohesion: 0.24
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

### Community 108 - "test_resilience.py"
Cohesion: 0.19
Nodes (5): with_retry(), _crear_recurso(), test_idempotencia_prestamo_con_misma_clave(), test_with_retry_exito_tras_fallo_transitorio(), test_with_retry_lanza_excepcion_al_superar_maximo()

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.11
Nodes (15): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+7 more)

### Community 110 - "win32_window.cpp"
Cohesion: 0.18
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "FlutterWindow"
Cohesion: 0.14
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 112 - "State"
Cohesion: 0.17
Nodes (14): _Raiz, _RaizState, PanelAdministrativoPage, _PanelAdministrativoPageState, CuentaPage, _CuentaPageState, ShellPage, _ShellPageState (+6 more)

### Community 113 - "sqlalchemy"
Cohesion: 0.16
Nodes (5): downgrade(), upgrade(), upgrade(), upgrade(), upgrade()

### Community 114 - "filtros_sheet.dart"
Cohesion: 0.12
Nodes (13): build, _categoria, createState, _estado, _FiltrosSheet, _FiltrosSheetState, kTodosLosSalones, mostrarFiltros (+5 more)

### Community 115 - "uber_widgets.dart"
Cohesion: 0.12
Nodes (15): AsaHoja, AvatarIniciales, BotonPildora, build, cargando, color, compacto, estilo (+7 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.21
Nodes (13): _salon_con_clase(), test_confirmar_presencia_se_refleja_en_la_ocupacion(), test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(), test_listar_ocupacion_incluye_todos_los_salones(), test_presencia_requiere_rol_administrador(), test_presencia_se_puede_corregir_sin_duplicar(), test_presencia_sin_clase_en_curso_da_409(), test_prestamo_aprobado_muestra_quien_tiene_el_salon() (+5 more)

### Community 118 - "plano_salones.dart"
Cohesion: 0.13
Nodes (10): _Baldosa, build, _CuadriculaPainter, ocupacion, onTap, paint, PlanoSalones, _porEdificio (+2 more)

### Community 119 - "reporte_salon_sheet.dart"
Cohesion: 0.13
Nodes (12): build, createState, _descripcion, dispose, _enviando, _enviar, _error, mostrarReporteSalonSheet (+4 more)

### Community 120 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 121 - "salones_admin_estilos.dart"
Cohesion: 0.17
Nodes (9): colorDeSituacion, _colorPrestado, d, _dos, etiquetaDeSituacion, formatearHora, h12, haceCuanto (+1 more)

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "NotificadorBase"
Cohesion: 0.17
Nodes (7): _calcular_siguiente_intento(), NotificadorBase, 1. Simplificaciones Asumidas en el Diseño, 2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial, 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa, 4. Requisitos para Transición a Producción, Límites del Experimento: Mensajería Asíncrona

### Community 124 - "get_user_endpoint"
Cohesion: 0.22
Nodes (7): get_user_endpoint(), me_endpoint(), 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Estrategia de Datos y Eventos — UTB Tracker

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.18
Nodes (8): cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, obtenerOcupacion, registrarPresencia

### Community 126 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.17
Nodes (11): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login pide NOMBRE + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Pruebas, 7. Problemas comunes (+3 more)

### Community 129 - ".MessageHandler"
Cohesion: 0.19
Nodes (5): EnableFullDpiSupportIfAvailable(), Win32Window, child_content_, quit_on_close_, window_handle_

### Community 130 - "Aspectos — UTB Tracker"
Cohesion: 0.25
Nodes (8): A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar, A-05 · Declarar, A-06 · Declarar, Aspectos — UTB Tracker, Especificar (escenarios medibles)

### Community 131 - "security.py"
Cohesion: 0.25
Nodes (5): get_current_user(), create_access_token(), create_reset_password_token(), verify_reset_password_token(), verify_token()

### Community 133 - "Conceptos transversales (Cross-cutting Concepts)"
Cohesion: 0.20
Nodes (10): 8.1 Patrón de Capas y Control de Erosión Arquitectónica, 8.2 Seguridad, Hashing y Autenticación, 8.3 Observabilidad y Logging Estructurado, 8.4 Evaluación de Inteligencia Artificial Generativa en el Producto (req. 9.9), 8.5 Resiliencia, Timeouts y Reintentos (S11 — req. 11.1 y 11.2), 8.6 Idempotencia y Prevención de Condiciones de Carrera (S11 — req. 11.3 y R-02), 8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6), 8.8 Estrategia de Consistencia de Datos (+2 more)

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.22
Nodes (9): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+1 more)

### Community 136 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 144 - "4. Brechas Conocidas y Mejoras Propuestas"
Cohesion: 0.40
Nodes (5): 4. Brechas Conocidas y Mejoras Propuestas, Brecha B-01: Doble Reserva Concurrente de Salones, Brecha B-02: Inserción de Horarios Solapados, Brecha B-03: Doble Devolución de Préstamo (*Race Condition*), Brecha B-05: Inoperancia de Bloqueo Pesimista en Entornos SQLite

### Community 145 - "SalonesAdminRepository"
Cohesion: 0.50
Nodes (3): SalonesAdminRepositoryImpl, SalonesAdminRepository, _RepoFalso

## Knowledge Gaps
- **766 isolated node(s):** `_auth`, `build`, `createState`, `initState`, `Figuras` (+761 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1421 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **29 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Riesgos y deudas técnicas` connect `Usuario` to `arc42.md`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_auth`, `build`, `createState` to the rest of the system?**
  _766 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `routers/salones_admin.py` be split into smaller, more focused modules?**
  _Cohesion score 0.10931174089068826 - nodes in this community are weakly interconnected._
- **Why does `Usuario` connect `Usuario` to `security.py`, `main.py`, `demo_mensajeria.py`, `get_db`, `conftest.py`, `services/salones_admin.py`, `services/auth.py`, `services/prestamos_salon.py`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Should `with` be split into smaller, more focused modules?**
  _Cohesion score 0.06218487394957983 - nodes in this community are weakly interconnected._
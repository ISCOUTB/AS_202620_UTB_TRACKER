# Graph Report - AS_202620_UTB_TRACKER  (2026-11-13)

## Corpus Check
- 193 files · ~102,140 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 27 file(s) not represented in the graph (top: (none) 7, .xml 7, .properties 3)

## Summary
- 2608 nodes · 4359 edges · 152 communities (121 shown, 31 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 181 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `60570b9d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- Usuario
- Recurso
- registrar_presencia
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- demo_mensajeria.py
- UTB Tracker
- worker.py
- Aspectos — UTB Tracker
- Ficha del problema — UTB Tracker
- arc42.md
- services/auth.py
- datetime
- routers/horarios.py
- test_resilience.py
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
- recurso_models.py
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
- Horario
- PrestamoSalon
- prestamos_data.dart
- Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02
- recursos_data.dart
- Modelado de Amenazas y Plan de Mitigación — UTB Tracker
- api_exception.dart
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- prestamo.dart
- test_horarios.py
- client
- package:flutter/foundation.dart
- mensajeria/README.md
- salon_control_page.dart
- Análisis de dependencias y gestión de secretos
- recursos_repository.dart
- token_storage.dart
- app_theme.dart
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
- routers/salones_admin.py
- enums.py
- salones_admin_data.dart
- win32_window.cpp
- FlutterWindow
- State
- sqlalchemy_orm
- filtros_sheet.dart
- uber_widgets.dart
- test_salones_admin.py
- json
- stats_data.dart
- mantenimiento_data.dart
- utils.cpp
- package:flutter/material.dart
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- NotificadorBase
- Estrategia de Datos y Eventos — UTB Tracker
- salones_admin_repository.dart
- manifest.json
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- .MessageHandler
- fcm_registration.dart
- get_current_user
- flutter_window.cpp
- _run_loop
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- bom.json
- Point
- resilience.py
- services/loans.py
- mantenimiento_controller.dart
- Política y Modelo de Privacidad de Datos — UTB Tracker
- Win32Window
- actualizar_mantenimiento
- stats_controller.dart
- ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)
- get_user_endpoint

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 69 edges
2. `Usuario` - 35 edges
3. `MensajeOutbox` - 34 edges
4. `Salon` - 22 edges
5. `PrestamoSalon` - 21 edges
6. `Win32Window` - 21 edges
7. `procesar_pendientes()` - 20 edges
8. `Horario` - 20 edges
9. `NotificadorSimulado` - 19 edges
10. `_procesar_un_mensaje()` - 19 edges

## Surprising Connections (you probably didn't know these)
- `1.1 ¿Qué estamos construyendo?` --references--> `NotificadorBase`  [INFERRED]
  docs/seguridad/modelo-amenazas.md → app/messaging/worker.py
- `2. Matriz de Operaciones y Garantías de Consistencia` --references--> `PrestamoSalon`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/models/salon_models.py
- `3. Metodología de Verificación en el Repositorio` --references--> `get_user_endpoint()`  [INFERRED]
  docs/datos/README.md → app/routers/auth.py
- `Brecha B-04: Registro de Nombres de Usuario Duplicados` --references--> `login()`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/services/auth.py
- `Decisión` --references--> `get_user_by_id()`  [INFERRED]
  docs/adr/0008-control-acceso-granular-recurso.md → app/services/auth.py

## Import Cycles
- None detected.

## Communities (152 total, 31 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.25
Nodes (8): Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View, Vista de ejecución

### Community 1 - "Usuario"
Cohesion: 0.12
Nodes (11): require_role(), hash_password(), Usuario, Reporte, PresenciaSalon, Salon, create_user(), Riesgos y deudas técnicas (+3 more)

### Community 2 - "Recurso"
Cohesion: 0.25
Nodes (8): Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, Vista general del sistema, White Box *prestamos*, White Box *recursos*

### Community 3 - "registrar_presencia"
Cohesion: 0.20
Nodes (6): actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), obtener_ocupacion(), registrar_presencia()

### Community 4 - "with"
Cohesion: 0.06
Nodes (36): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+28 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 6 - "demo_mensajeria.py"
Cohesion: 0.18
Nodes (4): NotificacionProcesada, crear_prestamo(), main(), setup_logger()

### Community 7 - "UTB Tracker"
Cohesion: 0.14
Nodes (14): API pública, Arquitectura del proyecto, Backend: monolito modular y capas, Desarrollo local, Despliegue, Estado actual, Estructura, Flujo de una operación (+6 more)

### Community 8 - "worker.py"
Cohesion: 0.15
Nodes (15): _calcular_siguiente_intento(), _construir_notificacion(), _descartar_duplicado(), _enviar_notificacion(), _leer_payload(), _marcar_enviado(), _marcar_muerto(), NotificadorConPush (+7 more)

### Community 9 - "Aspectos — UTB Tracker"
Cohesion: 0.11
Nodes (11): logging_middleware(), health_check(), A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar, A-05 · Declarar, A-06 · Declarar (+3 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.20
Nodes (5): Decisiones arquitectónicas, Restricciones arquitectónicas, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "services/auth.py"
Cohesion: 0.14
Nodes (18): verify_password(), create_access_token(), create_refresh_token(), create_reset_password_token(), verify_refresh_token(), verify_reset_password_token(), verify_token(), delete_user() (+10 more)

### Community 13 - "datetime"
Cohesion: 0.14
Nodes (10): FranjaDisponible, SalonConDisponibilidad, SalonCreate, SalonResponse, SalonUpdate, actualizar_salon(), crear_salon(), eliminar_salon() (+2 more)

### Community 14 - "routers/horarios.py"
Cohesion: 0.10
Nodes (10): actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate, HorarioCreate (+2 more)

### Community 15 - "test_resilience.py"
Cohesion: 0.06
Nodes (25): CircuitBreaker, wrapper(), CircuitBreakerOpenException, with_retry(), decorator(), wrapper(), 8.10 Arquitectura de Seguridad y Privacidad (S13), 8.1 Patrón de Capas y Control de Erosión Arquitectónica (+17 more)

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.04
Nodes (46): _abrirAgregarHorario, _abrirSolicitudPrestamo, _auth, build, _cambiarDia, _cancelarSolicitud, _cargandoDatos, _cargarTodo (+38 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.10
Nodes (17): MensajeOutbox, NotificadorSimulado, _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker(), test_idempotencia_http_con_x_idempotency_key(), test_mensaje_muerto_al_superar_max_intentos(), test_outbox_se_inserta_en_misma_transaccion_que_prestamo() (+9 more)

### Community 23 - "widgets.dart"
Cohesion: 0.05
Nodes (39): _CajaError, _CampoUber, _Marca, _MedidorClave, _Selector, _Buscador, _Cabecera, _Carrusel (+31 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.11
Nodes (16): build, _categoria, CrearRecursoPage, _CrearRecursoPageState, createState, dispose, _error, _form (+8 more)

### Community 25 - "Diseño de Estrategia de Caché e Invalidación — UTB Tracker"
Cohesion: 0.11
Nodes (18): 1.1 Regla Central de Oro (Aislamiento de Invariantes), 1.2 Endpoints Incluidos en Caché, 1.3 Endpoints Excluidos de Caché, 1. Alcance y Reglas de Integridad, 2.1 En Proceso vs. Redis Distribuido, 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia, 2. Topología de Caché y Decisión de Ubicación, 3.1 Formato Canónico de Claves (+10 more)

### Community 26 - "app_theme.dart"
Cohesion: 0.12
Nodes (14): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+6 more)

### Community 27 - "home_page.dart"
Cohesion: 0.06
Nodes (32): _abrirFiltros, _alcance, _auth, _buscar, controlador, createState, _DatosTarjeta, detalle (+24 more)

### Community 28 - "recurso_models.py"
Cohesion: 0.16
Nodes (8): IdempotenciaRegistro, MantenimientoRecurso, Prestamo, Recurso, resumen(), actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 29 - "salon.dart"
Cohesion: 0.07
Nodes (27): activo, capacidad, createdAt, diaNombre, diaSemana, disponible, edificio, estado (+19 more)

### Community 30 - "controladores_test.dart"
Cohesion: 0.07
Nodes (19): actualizarRolUsuario, crear, datos, devolver, fallo, iniciarSesion, listar, listarUsuarios (+11 more)

### Community 31 - "recursos_controller.dart"
Cohesion: 0.08
Nodes (23): _busqueda, _carga, cargar, _categoria, crear, disponiblesDe, _error, _estado (+15 more)

### Community 32 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (13): AdminUsuariosController, _abrirCambiarRol, _auth, build, _busquedaCtrl, _controller, createState, dispose (+5 more)

### Community 33 - "equipos_page.dart"
Cohesion: 0.06
Nodes (27): _auth, build, createState, initState, build, build, _auth, build (+19 more)

### Community 34 - "solicitar_prestamo_sheet.dart"
Cohesion: 0.09
Nodes (22): _auth, _authRepo, build, _buscando, _buscarPrestatario, _clave, _confirmar, createState (+14 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.08
Nodes (22): build, createState, _Dato, _descCtrl, dispose, _enviando, _enviar, _estado (+14 more)

### Community 37 - "update_user_role_endpoint"
Cohesion: 0.18
Nodes (11): get_db(), _client_key(), delete_user_endpoint(), forgot_password_endpoint(), get_users_endpoint(), login_endpoint(), refresh_endpoint(), register_endpoint() (+3 more)

### Community 38 - "obtener_disponibilidad"
Cohesion: 0.13
Nodes (6): actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon()

### Community 39 - "salones_page.dart"
Cohesion: 0.06
Nodes (32): _abrirCrearSalon, _abrirSolicitud, _auth, _busquedaCtrl, _capacidadCtrl, _construirCuerpo, _CrearSalonSheet, _CrearSalonSheetState (+24 more)

### Community 40 - "test_auth.py"
Cohesion: 0.05
Nodes (25): Descripción general de los requisitos de calidad, Escenarios de calidad, QS-01 — Disponibilidad, QS-02 — Rendimiento (tiempo de respuesta), QS-03 — Rendimiento (concurrencia), QS-04 — Seguridad, QS-05 — Usabilidad, QS-06 — Confiabilidad de los datos (+17 more)

### Community 41 - "shell_page.dart"
Cohesion: 0.05
Nodes (35): AuthController, _BarraPildora, build, createState, _filtroActividad, _indice, initState, _ir (+27 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.14
Nodes (5): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_vencidos(), marcar_vencidos_job()

### Community 43 - "with"
Cohesion: 0.09
Nodes (21): defaults, runs-on, steps, run, jobs, build, name, permissions (+13 more)

### Community 44 - "auth_controller.dart"
Cohesion: 0.08
Nodes (21): actualizarPerfil, _api, autenticado, _cargando, cerrarSesion, comprobarServidor, _ejecutar, _error (+13 more)

### Community 45 - "recurso.dart"
Cohesion: 0.09
Nodes (17): categoria, categoriaCodigo, CategoriaRecurso, codigo, creables, desde, disponible, estado (+9 more)

### Community 46 - "auth_data.dart"
Cohesion: 0.09
Nodes (21): actualizarRolUsuario, _api, AuthRemoteDataSource, desdeJson, _identificar, iniciarSesion, _intentarUsuario, listarUsuarios (+13 more)

### Community 47 - "utilidades.dart"
Cohesion: 0.10
Nodes (20): abs, azar, bytes, cantidad, d, describirPlazo, _dos, endsWith (+12 more)

### Community 48 - "ocupacion.dart"
Cohesion: 0.05
Nodes (41): abierto, clase, ClaseActual, creadoEn, descripcion, desde, enUso, estado (+33 more)

### Community 49 - "api_client.dart"
Cohesion: 0.11
Nodes (14): _azar, _baseUrl, _cabeceras, cerrar, _client, _conReintentos, delete, _enviar (+6 more)

### Community 50 - "login_page.dart"
Cohesion: 0.06
Nodes (31): accion, _auth, autofill, build, _cambiarModo, clave, _continuar, controller (+23 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.10
Nodes (18): actualizarEstadoPrestamo, _api, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, desdeJson, FranjaDisponibleModel (+10 more)

### Community 52 - "pubspec.yaml"
Cohesion: 0.09
Nodes (22): dependencies, firebase_core, firebase_messaging, flutter, flutter_secure_storage, flutter_svg, get_it, http (+14 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.13
Nodes (6): ApiException, _json, main, _json, main, main

### Community 54 - "injection.dart"
Cohesion: 0.04
Nodes (21): configurarDependencias, reset, sl, PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository (+13 more)

### Community 55 - "routers/auth.py"
Cohesion: 0.22
Nodes (11): FcmTokenRequest, ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest, TokenResponse, UserMeResponse, UserResponse, UsuarioCreate (+3 more)

### Community 56 - "salones_controller.dart"
Cohesion: 0.11
Nodes (14): Carga, agregarHorario, _busqueda, cancelarPrestamoSalon, _carga, cargar, crear, _error (+6 more)

### Community 57 - "admin_usuarios_controller.dart"
Cohesion: 0.12
Nodes (15): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+7 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.11
Nodes (17): _carga, cargar, deUsuario, devolver, error, exito, fallo, filtrarPorEstado (+9 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.12
Nodes (16): actualizarRolUsuario, email, id, iniciarSesion, listarUsuarios, nombre, obtenerUsuario, registrar (+8 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.12
Nodes (15): EventoDominio, EventoPrestamoCreado, PayloadPrestamoCreado, PayloadPrestamoDevuelto, PayloadRecursoReportado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`) (+7 more)

### Community 61 - "Horario"
Cohesion: 0.21
Nodes (9): Horario, actualizar_horario(), crear_horario(), crear_horarios_bulk(), _detectar_conflicto(), eliminar_horario(), listar_horarios(), obtener_horario() (+1 more)

### Community 62 - "PrestamoSalon"
Cohesion: 0.07
Nodes (19): PrestamoSalon, actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon(), expirar_prestamos_pendientes(), listar_prestamos_salon(), obtener_prestamo_salon(), PrestamoSalonCreate (+11 more)

### Community 63 - "prestamos_data.dart"
Cohesion: 0.17
Nodes (8): _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource, _remoto

### Community 64 - "Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02"
Cohesion: 0.10
Nodes (19): 1. Escenarios de Calidad Evaluados (arc42 Sección 10), 2.1 Scripts Utilizados, 2.2 Endpoints Medidos, 2.3 Requisitos para Reproducir, 2.4 Comandos de Reproducción, 2. Método de Medición, 3. Entorno de Ejecución, 4.1 Resumen Tabular (+11 more)

### Community 65 - "recursos_data.dart"
Cohesion: 0.17
Nodes (9): _api, crear, desdeJson, listar, obtener, RecursoModel, RecursosRemoteDataSource, _remoto (+1 more)

### Community 66 - "Modelado de Amenazas y Plan de Mitigación — UTB Tracker"
Cohesion: 0.12
Nodes (15): 1.1 ¿Qué estamos construyendo?, 1.2 ¿Qué puede salir mal?, 1.3 ¿Qué hacemos al respecto?, 1.4 ¿Hicimos un buen trabajo?, 1. Las Cuatro Preguntas del Modelado de Amenazas, 2.1 Catálogo de Activos, 2.2 Fronteras de Confianza (Trust Boundaries), 2.3 Diagrama de Fronteras de Confianza (Mermaid) (+7 more)

### Community 67 - "api_exception.dart"
Cohesion: 0.17
Nodes (10): _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado, tipo (+2 more)

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.04
Nodes (42): _abrir, _actualizado, _auth, _Aviso, build, _c, _Cabecera, _cargar (+34 more)

### Community 70 - "prestamo.dart"
Cohesion: 0.18
Nodes (10): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+2 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "client"
Cohesion: 0.20
Nodes (5): admin_headers(), auth_headers(), client(), db_session(), _get_token()

### Community 74 - "mensajeria/README.md"
Cohesion: 0.11
Nodes (16): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller), 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas) (+8 more)

### Community 76 - "salon_control_page.dart"
Cohesion: 0.07
Nodes (27): acciones, autor, build, _c, cantidad, _colorDeSolicitud, _confirmar, createState (+19 more)

### Community 77 - "Análisis de dependencias y gestión de secretos"
Cohesion: 0.13
Nodes (11): Alcance, Análisis de dependencias y gestión de secretos, Auditoría en CI, Pruebas y base de datos, Secretos y correo, Verificación de despliegue, 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos (+3 more)

### Community 78 - "recursos_repository.dart"
Cohesion: 0.22
Nodes (7): RecursosRepositoryImpl, crear, listar, obtener, RecursosRepository, reportar, _RecursosFalso

### Community 79 - "token_storage.dart"
Cohesion: 0.11
Nodes (11): ApiConfig, _override, reintentosLectura, servidorProduccion, timeout, borrarToken, _clave, guardarToken (+3 more)

### Community 80 - "app_theme.dart"
Cohesion: 0.13
Nodes (14): AppColors, AppTheme, borde, danado, disponible, fondo, mantenimiento, neutro (+6 more)

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
Nodes (30): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso(), MantenimientoRecursoCreate (+22 more)

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.08
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "services/salones_admin.py"
Cohesion: 0.25
Nodes (14): ReporteSalon, _a_utc_naive(), actualizar_estado_reporte(), _ahora_campus(), _clase_en_curso(), crear_reporte(), listar_ocupacion(), listar_reportes() (+6 more)

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.10
Nodes (18): _busqueda, _carga, cargar, _coincide, contar, _error, etiqueta, fijarBusqueda (+10 more)

### Community 106 - "salones_admin_test.dart"
Cohesion: 0.10
Nodes (10): _clase, fallo, _json, listarOcupacion, main, ocupaciones, _ocupacionJson, registrarPresencia (+2 more)

### Community 107 - "routers/salones_admin.py"
Cohesion: 0.29
Nodes (8): ClaseActual, OcupacionSalon, PresenciaResponse, PresenciaUpdate, PrestamoActual, ReporteSalonCreate, ReporteSalonResponse, ReporteSalonUpdate

### Community 108 - "enums.py"
Cohesion: 0.32
Nodes (9): CategoriaRecurso, DiaSemana, EstadoPrestamo, EstadoPrestamoSalon, EstadoRecurso, EstadoReporteSalon, EstadoSalon, RolUsuario (+1 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.11
Nodes (15): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+7 more)

### Community 110 - "win32_window.cpp"
Cohesion: 0.16
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "FlutterWindow"
Cohesion: 0.17
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 112 - "State"
Cohesion: 0.09
Nodes (30): _Raiz, _RaizState, PanelAdministrativoPage, _PanelAdministrativoPageState, LoginPage, _LoginPageState, CuentaPage, _CuentaPageState (+22 more)

### Community 113 - "sqlalchemy_orm"
Cohesion: 0.08
Nodes (7): downgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade()

### Community 114 - "filtros_sheet.dart"
Cohesion: 0.12
Nodes (13): build, _categoria, createState, _estado, _FiltrosSheet, _FiltrosSheetState, kTodosLosSalones, mostrarFiltros (+5 more)

### Community 115 - "uber_widgets.dart"
Cohesion: 0.12
Nodes (15): AsaHoja, AvatarIniciales, BotonPildora, build, cargando, color, compacto, estilo (+7 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.21
Nodes (13): _salon_con_clase(), test_confirmar_presencia_se_refleja_en_la_ocupacion(), test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(), test_listar_ocupacion_incluye_todos_los_salones(), test_presencia_requiere_rol_administrador(), test_presencia_se_puede_corregir_sin_duplicar(), test_presencia_sin_clase_en_curso_da_409(), test_prestamo_aprobado_muestra_quien_tiene_el_salon() (+5 more)

### Community 117 - "json"
Cohesion: 0.21
Nodes (4): _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo()

### Community 118 - "stats_data.dart"
Cohesion: 0.14
Nodes (12): _api, DashboardStats, equiposDisponibles, fromJson, _int, prestamosActivos, reportesAbiertos, resumen (+4 more)

### Community 119 - "mantenimiento_data.dart"
Cohesion: 0.14
Nodes (13): ApiClient, actualizar, _api, descripcion, estado, fechaProgramada, fromJson, id (+5 more)

### Community 120 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 121 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (14): _auth, build, createState, initState, UtbTrackerApp, colorDeSituacion, _colorPrestado, d (+6 more)

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "NotificadorBase"
Cohesion: 0.14
Nodes (6): NotificadorBase, NotificadorFCM, 1. Simplificaciones Asumidas en el Diseño, 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa, 4. Requisitos para Transición a Producción, Límites del Experimento: Mensajería Asíncrona

### Community 124 - "Estrategia de Datos y Eventos — UTB Tracker"
Cohesion: 0.40
Nodes (5): 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Estrategia de Datos y Eventos — UTB Tracker

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.13
Nodes (11): SalonesAdminRepositoryImpl, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, obtenerOcupacion (+3 more)

### Community 126 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 127 - "time"
Cohesion: 0.12
Nodes (7): ejecutar_corrida(), ejecutar_peticion(), main(), obtener_token(), percentil(), test_concurrencia_prestamos_mismo_recurso_postgresql(), test_rendimiento_latencia_p95_salud()

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.17
Nodes (11): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login pide NOMBRE + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Pruebas, 7. Problemas comunes (+3 more)

### Community 130 - "fcm_registration.dart"
Cohesion: 0.15
Nodes (7): FcmRegistration, FcmTokenRegistrar, _messaging, _registrar, start, stop, _tokenSubscription

### Community 133 - "_run_loop"
Cohesion: 0.20
Nodes (5): crear_notificador(), crear_notificador_push(), NotificadorSMTP, _run_loop(), Patrones de diseño utilizados

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.13
Nodes (15): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+7 more)

### Community 135 - "bom.json"
Cohesion: 0.17
Nodes (11): bomFormat, components, dependencies, metadata, timestamp, tools, $schema, serialNumber (+3 more)

### Community 136 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 143 - "services/loans.py"
Cohesion: 0.14
Nodes (7): publicar_evento(), devolver_prestamo(), listar_prestamos(), marcar_prestamos_vencidos(), _obtener_recurso_con_bloqueo(), _resolver_correlation_id(), _verificar_idempotencia()

### Community 144 - "mantenimiento_controller.dart"
Cohesion: 0.18
Nodes (7): actualizar, _cargando, cargar, _error, _items, MantenimientoController, _remote

### Community 146 - "Política y Modelo de Privacidad de Datos — UTB Tracker"
Cohesion: 0.18
Nodes (11): 1. Marco Legal y Principios de Tratamiento, 2. Inventario Exhaustivo de Datos Personales en el Modelo de Datos, 3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios, 3.2 Correo en Logs del Notificador Simulado, 3.3 Datos en Carga Útil del Outbox, 3.4 Campo `profesor` en Horarios Académicos, 3. Análisis de Minimización de Datos y Brechas Detectadas, 4. Hallazgos de Privacidad Ligados al Modelado de Amenazas (+3 more)

### Community 147 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 148 - "actualizar_mantenimiento"
Cohesion: 0.27
Nodes (3): actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 149 - "stats_controller.dart"
Cohesion: 0.20
Nodes (6): _cargando, cargar, _error, _remote, _stats, StatsController

### Community 150 - "ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)"
Cohesion: 0.29
Nodes (7): ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR), Alternativas Evaluadas, Consecuencias, Contexto, Decisión, Estado, Fecha

## Knowledge Gaps
- **851 isolated node(s):** `_auth`, `build`, `createState`, `initState`, `Figuras` (+846 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1636 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **31 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Riesgos y deudas técnicas` connect `Usuario` to `arc42.md`, `recurso_models.py`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_auth`, `build`, `createState` to the rest of the system?**
  _851 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Usuario` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Why does `get_db()` connect `update_user_role_endpoint` to `get_current_user`, `main.py`, `registrar_presencia`, `get_db`, `obtener_disponibilidad`, `client`, `Aspectos — UTB Tracker`, `listar_prestamos`, `routers/salones_admin.py`, `datetime`, `routers/horarios.py`, `sqlalchemy_orm`, `test_messaging.py`, `actualizar_mantenimiento`, `routers/auth.py`, `get_user_endpoint`, `recurso_models.py`, `PrestamoSalon`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Are the 18 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Should `with` be split into smaller, more focused modules?**
  _Cohesion score 0.05855855855855856 - nodes in this community are weakly interconnected._
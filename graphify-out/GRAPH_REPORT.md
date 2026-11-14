# Graph Report - AS_202620_UTB_TRACKER  (2026-11-14)

## Corpus Check
- 208 files · ~117,854 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 36 file(s) not represented in the graph (top: (none) 11, .xml 11, .properties 3)

## Summary
- 2954 nodes · 4845 edges · 212 communities (144 shown, 68 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 120 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `544e88f4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- require_role
- Recurso
- services/salones_admin.py
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- UTB Tracker
- worker.py
- Aspectos — UTB Tracker
- Ficha del problema — UTB Tracker
- arc42.md
- utb_ui.dart
- package:flutter/material.dart
- routers/horarios.py
- CircuitBreaker
- test_resources.py
- salon_detalle_page.dart
- test_messaging.py
- c4_nivel1.md
- run.sh
- control_page.dart
- crear_recurso_page.dart
- Diseño de Estrategia de Caché e Invalidación — UTB Tracker
- app_theme.dart
- home_page.dart
- salon.dart
- controladores_test.dart
- recursos_controller.dart
- auditoria.dart
- equipos_page.dart
- json
- recurso_detalle_page.dart
- get_db
- get_db
- services/salones.py
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
- StatelessWidget
- registrar
- admin_usuarios_controller.dart
- prestamos_controller.dart
- auth_domain.dart
- PayloadPrestamoCreado
- control_controller.dart
- listar_prestamos_salon
- prestamos_data.dart
- Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02
- demo_mensajeria.py
- Modelado de Amenazas y Plan de Mitigación — UTB Tracker
- api_exception.dart
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- services/auditoria.py
- test_horarios.py
- conftest.py
- _run_loop
- ChangeNotifier
- salon_control_page.dart
- Análisis de dependencias y gestión de secretos
- recursos_repository.dart
- token_storage.dart
- schemas/salones.py
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
- listar_recursos
- salon_control_controller.dart
- salones_admin_controller.dart
- salones_admin_test.dart
- control_test.dart
- cuenta_page.dart
- salones_admin_data.dart
- win32_window.cpp
- FlutterWindow
- sqlalchemy
- mensajeria/README.md
- salones_controller.dart
- package:flutter/material.dart
- test_salones_admin.py
- json
- salones_repository.dart
- stats_data.dart
- utils.cpp
- flutter_window.cpp
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- services/auth.py
- Estrategia de Datos y Eventos — UTB Tracker
- salones_admin_repository.dart
- manifest.json
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- .MessageHandler
- fcm_registration.dart
- get_current_user
- generated_plugin_registrant.cc
- recursos_data.dart
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- bom.json
- List
- services/resources.py
- 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes
- Win32Window
- Política y Modelo de Privacidad de Datos — UTB Tracker
- _AgregarHorarioSheet
- Conceptos transversales (Cross-cutting Concepts)
- api
- ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)
- SalonDetallePage
- schemas.py
- environment
- worker
- services/maintenance.py
- _SolicitarPrestamoSalonSheet
- web
- test_resilience.py
- 4. Tabla de Amenazas Priorizadas (P × I)
- DateTime
- Escenarios de calidad
- db
- Identidad visual de UTB Tracker
- x-backend
- filtros_sheet.dart
- 0012 - Empaquetar el sistema en contenedores con Docker Compose
- healthcheck
- time
- seed
- mantenimiento_data.dart
- routers/prestamos_salon.py
- Win32Window
- env.py
- NotificadorBase
- prestamos_repository.dart
- crear_recurso
- 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción
- Evidencia: la prueba de contrato falla ante un cambio incompatible
- 1. Las Cuatro Preguntas del Modelado de Amenazas
- test_circuit_breaker_transiciones_de_estado
- AuthRepository

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 73 edges
2. `registrar()` - 31 edges
3. `Usuario` - 30 edges
4. `MensajeOutbox` - 24 edges
5. `Win32Window` - 21 edges
6. `NotificadorSimulado` - 19 edges
7. `procesar_pendientes()` - 19 edges
8. `_procesar_un_mensaje()` - 19 edges
9. `Recurso` - 17 edges
10. `Salon` - 16 edges

## Surprising Connections (you probably didn't know these)
- `8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6)` --references--> `CircuitBreaker`  [INFERRED]
  docs/arc42/arc42.md → app/core/resilience.py
- `2. Matriz de Operaciones y Garantías de Consistencia` --references--> `PrestamoSalon`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/models/salon_models.py
- `1.1 ¿Qué estamos construyendo?` --references--> `NotificadorBase`  [INFERRED]
  docs/seguridad/modelo-amenazas.md → app/messaging/worker.py
- `3. Metodología de Verificación en el Repositorio` --references--> `get_user_endpoint()`  [INFERRED]
  docs/datos/README.md → app/routers/auth.py
- `Decisión` --references--> `get_user_by_id()`  [INFERRED]
  docs/adr/0008-control-acceso-granular-recurso.md → app/services/auth.py

## Import Cycles
- None detected.

## Communities (212 total, 68 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.22
Nodes (9): Despliegue reproducible con Docker Compose (ADR-0012), Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View (+1 more)

### Community 2 - "Recurso"
Cohesion: 0.25
Nodes (8): Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, Vista general del sistema, White Box *prestamos*, White Box *recursos*

### Community 3 - "services/salones_admin.py"
Cohesion: 0.05
Nodes (47): PresenciaSalon, ReporteSalon, health_check(), actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), listar_todos_los_reportes() (+39 more)

### Community 4 - "with"
Cohesion: 0.06
Nodes (36): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+28 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 7 - "UTB Tracker"
Cohesion: 0.13
Nodes (15): API pública, Arquitectura del proyecto, Backend: monolito modular y capas, Desarrollo local, Despliegue, Ejecutar con Docker (ADR-0012), Estado actual, Estructura (+7 more)

### Community 8 - "worker.py"
Cohesion: 0.16
Nodes (14): MensajeOutbox, _calcular_siguiente_intento(), _construir_notificacion(), _descartar_duplicado(), _enviar_notificacion(), _leer_payload(), _marcar_enviado(), _marcar_muerto() (+6 more)

### Community 9 - "Aspectos — UTB Tracker"
Cohesion: 0.20
Nodes (10): A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar, A-05 · Declarar, A-06 · Declarar, A-07 · Declarar, A-08 · Declarar (+2 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.17
Nodes (6): Decisiones arquitectónicas, Restricciones arquitectónicas, Riesgos y deudas técnicas, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "utb_ui.dart"
Cohesion: 0.05
Nodes (33): _CuadriculaPainter, accion, _Arcos, build, _c, child, color, createState (+25 more)

### Community 13 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (22): _auth, build, createState, initState, _Raiz, _RaizState, UtbTrackerApp, _abrirCambiarRol (+14 more)

### Community 14 - "routers/horarios.py"
Cohesion: 0.07
Nodes (18): actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate, HorarioCreate (+10 more)

### Community 15 - "CircuitBreaker"
Cohesion: 0.18
Nodes (7): CircuitBreaker, wrapper(), decorator(), wrapper(), Formato, Registro, Uso de IA - Tractar

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.04
Nodes (43): _abrirAgregarHorario, _abrirSolicitudPrestamo, _auth, build, _cambiarDia, _cancelarSolicitud, _cargandoDatos, _cargarTodo (+35 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.09
Nodes (17): NotificadorSimulado, procesar_pendientes(), _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker(), test_idempotencia_http_con_x_idempotency_key(), test_mensaje_muerto_al_superar_max_intentos(), test_outbox_se_inserta_en_misma_transaccion_que_prestamo() (+9 more)

### Community 23 - "control_page.dart"
Cohesion: 0.08
Nodes (23): _auth, build, _cambiar, _colorSolicitud, _contenido, _control, ControlPage, _ControlPageState (+15 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.07
Nodes (19): build, _categoria, createState, dispose, _error, _form, _guardando, _guardar (+11 more)

### Community 25 - "Diseño de Estrategia de Caché e Invalidación — UTB Tracker"
Cohesion: 0.11
Nodes (18): 1.1 Regla Central de Oro (Aislamiento de Invariantes), 1.2 Endpoints Incluidos en Caché, 1.3 Endpoints Excluidos de Caché, 1. Alcance y Reglas de Integridad, 2.1 En Proceso vs. Redis Distribuido, 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia, 2. Topología de Caché y Decisión de Ubicación, 3.1 Formato Canónico de Claves (+10 more)

### Community 26 - "app_theme.dart"
Cohesion: 0.04
Nodes (39): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+31 more)

### Community 27 - "home_page.dart"
Cohesion: 0.07
Nodes (26): _auth, build, codigo, _CodigoSalon, color, createState, destacada, _destacadaAuxiliar (+18 more)

### Community 29 - "salon.dart"
Cohesion: 0.06
Nodes (31): activo, capacidad, createdAt, diaNombre, diaSemana, disponible, edificio, estado (+23 more)

### Community 30 - "controladores_test.dart"
Cohesion: 0.07
Nodes (19): actualizarRolUsuario, crear, datos, devolver, fallo, iniciarSesion, listar, listarUsuarios (+11 more)

### Community 31 - "recursos_controller.dart"
Cohesion: 0.08
Nodes (23): _busqueda, _carga, cargar, _categoria, crear, disponiblesDe, _error, _estado (+15 more)

### Community 32 - "auditoria.dart"
Cohesion: 0.11
Nodes (18): accion, actorNombre, _api, AuditoriaRepository, AuditoriaRepositoryImpl, _carga, cargar, detalle (+10 more)

### Community 33 - "equipos_page.dart"
Cohesion: 0.08
Nodes (23): _cuerpoAuxiliar, _cuerpoUsuario, _auth, build, _buscar, _CabeceraSalon, _ChipsActivos, codigo (+15 more)

### Community 34 - "json"
Cohesion: 0.25
Nodes (14): _auditoria(), _login(), _salon_con_clase(), test_confirmar_presencia_deja_quien_cuando_y_que(), test_crud_de_salones_y_horarios_se_audita(), test_el_auxiliar_no_ve_la_bitacora(), test_el_cambio_de_rol_registra_quien_lo_hizo(), test_exportar_csv_trae_encabezado_y_filas() (+6 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.09
Nodes (23): _auth, _AvisoEstado, build, createState, _Dato, _descCtrl, dispose, _enviando (+15 more)

### Community 37 - "get_db"
Cohesion: 0.10
Nodes (23): _client_key(), delete_user_endpoint(), forgot_password_endpoint(), get_user_endpoint(), get_users_endpoint(), login_endpoint(), me_endpoint(), refresh_endpoint() (+15 more)

### Community 38 - "services/salones.py"
Cohesion: 0.08
Nodes (10): actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon(), actualizar_salon(), eliminar_salon() (+2 more)

### Community 39 - "salones_page.dart"
Cohesion: 0.05
Nodes (44): LoginPage, _LoginPageState, CrearRecursoPage, _CrearRecursoPageState, MantenimientoPage, _MantenimientoPageState, PanelSalonesPage, _PanelSalonesPageState (+36 more)

### Community 40 - "test_auth.py"
Cohesion: 0.09
Nodes (7): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_registro_fuerza_rol_usuario_utb()

### Community 41 - "shell_page.dart"
Cohesion: 0.12
Nodes (10): _BarraInferior, build, createState, _indice, _ir, _irSalones, _items, onTap (+2 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.08
Nodes (10): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_vencidos(), marcar_vencidos_job(), devolver_prestamo(), listar_prestamos(), marcar_prestamos_vencidos() (+2 more)

### Community 43 - "with"
Cohesion: 0.09
Nodes (21): defaults, runs-on, steps, run, jobs, build, name, permissions (+13 more)

### Community 44 - "auth_controller.dart"
Cohesion: 0.08
Nodes (21): actualizarPerfil, _api, autenticado, _cargando, cerrarSesion, comprobarServidor, _ejecutar, _error (+13 more)

### Community 45 - "recurso.dart"
Cohesion: 0.07
Nodes (23): categoria, categoriaCodigo, CategoriaRecurso, codigo, creables, descripcion, desde, disponible (+15 more)

### Community 46 - "auth_data.dart"
Cohesion: 0.09
Nodes (21): actualizarRolUsuario, _api, AuthRemoteDataSource, desdeJson, _identificar, iniciarSesion, _intentarUsuario, listarUsuarios (+13 more)

### Community 47 - "utilidades.dart"
Cohesion: 0.10
Nodes (20): abs, azar, bytes, cantidad, d, describirPlazo, _dos, endsWith (+12 more)

### Community 48 - "ocupacion.dart"
Cohesion: 0.04
Nodes (42): abierto, clase, ClaseActual, creadoEn, descripcion, desde, enUso, estado (+34 more)

### Community 49 - "api_client.dart"
Cohesion: 0.10
Nodes (15): _azar, _baseUrl, _cabeceras, cerrar, _client, _conReintentos, delete, _enviar (+7 more)

### Community 50 - "login_page.dart"
Cohesion: 0.06
Nodes (31): accion, _auth, autofill, build, _cambiarModo, clave, _continuar, controller (+23 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.10
Nodes (18): actualizarEstadoPrestamo, _api, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, desdeJson, FranjaDisponibleModel (+10 more)

### Community 52 - "pubspec.yaml"
Cohesion: 0.04
Nodes (45): color, icon_background_color, image, dependencies, firebase_core, firebase_messaging, flutter, flutter_secure_storage (+37 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.13
Nodes (6): ApiException, _json, main, _json, main, main

### Community 54 - "injection.dart"
Cohesion: 0.07
Nodes (3): configurarDependencias, reset, sl

### Community 55 - "StatelessWidget"
Cohesion: 0.06
Nodes (35): _CajaError, _CampoUber, _Marca, _MedidorClave, _Selector, EncabezadoDegradado, FilaLineaTiempo, Indicador (+27 more)

### Community 56 - "registrar"
Cohesion: 0.26
Nodes (7): RegistroAuditoria, exportar_csv(), _filtrar(), listar(), registrar(), registrar_y_confirmar(), _request_id()

### Community 57 - "admin_usuarios_controller.dart"
Cohesion: 0.10
Nodes (14): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+6 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.07
Nodes (27): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+19 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.12
Nodes (16): actualizarRolUsuario, email, id, iniciarSesion, listarUsuarios, nombre, obtenerUsuario, registrar (+8 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.13
Nodes (15): EventoDominio, EventoPrestamoCreado, PayloadPrestamoCreado, PayloadPrestamoDevuelto, PayloadRecursoReportado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`) (+7 more)

### Community 61 - "control_controller.dart"
Cohesion: 0.12
Nodes (12): _accion, cambiarSolicitud, _carga, cargar, _error, pendientes, _repo, _reportes (+4 more)

### Community 62 - "listar_prestamos_salon"
Cohesion: 0.07
Nodes (14): actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), expirar_prestamos_pendientes(), listar_prestamos_salon(), obtener_prestamo_salon(), actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon() (+6 more)

### Community 63 - "prestamos_data.dart"
Cohesion: 0.17
Nodes (8): _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource, _remoto

### Community 64 - "Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02"
Cohesion: 0.10
Nodes (19): 1. Escenarios de Calidad Evaluados (arc42 Sección 10), 2.1 Scripts Utilizados, 2.2 Endpoints Medidos, 2.3 Requisitos para Reproducir, 2.4 Comandos de Reproducción, 2. Método de Medición, 3. Entorno de Ejecución, 4.1 Resumen Tabular (+11 more)

### Community 65 - "demo_mensajeria.py"
Cohesion: 0.19
Nodes (5): NotificacionProcesada, crear_prestamo(), _resolver_correlation_id(), main(), setup_logger()

### Community 66 - "Modelado de Amenazas y Plan de Mitigación — UTB Tracker"
Cohesion: 0.18
Nodes (10): 2.1 Catálogo de Activos, 2.2 Fronteras de Confianza (Trust Boundaries), 2.3 Diagrama de Fronteras de Confianza (Mermaid), 2. Activos y Fronteras de Confianza, 3. Análisis STRIDE por Elemento y Flujo, 5. Amenazas Aceptadas (Justificación Arquitectónica), A-01: Ausencia de Garantía de Orden Cronológico Global en Mensajes Outbox, A-02: Entrega Al Menos Una Vez (At-Least-Once) con Potenciales Duplicados por Caída del Worker (+2 more)

### Community 67 - "api_exception.dart"
Cohesion: 0.18
Nodes (10): _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado, tipo (+2 more)

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.04
Nodes (45): _abrir, _actualizado, _auth, _Aviso, build, _c, _Cabecera, _cargar (+37 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "conftest.py"
Cohesion: 0.15
Nodes (6): test_health_check(), admin_headers(), auth_headers(), client(), db_session(), _get_token()

### Community 73 - "_run_loop"
Cohesion: 0.12
Nodes (7): crear_notificador(), crear_notificador_push(), NotificadorConPush, NotificadorFCM, NotificadorSMTP, _run_loop(), Patrones de diseño utilizados

### Community 74 - "ChangeNotifier"
Cohesion: 0.20
Nodes (9): AdminUsuariosController, AuditoriaController, ControlController, PrestamosController, MantenimientoController, SalonControlController, SalonesAdminController, SalonesController (+1 more)

### Community 76 - "salon_control_page.dart"
Cohesion: 0.06
Nodes (29): acciones, autor, build, _c, cantidad, _colorDeSolicitud, _confirmar, createState (+21 more)

### Community 77 - "Análisis de dependencias y gestión de secretos"
Cohesion: 0.13
Nodes (11): Alcance, Análisis de dependencias y gestión de secretos, Auditoría en CI, Pruebas y base de datos, Secretos y correo, Verificación de despliegue, 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos (+3 more)

### Community 78 - "recursos_repository.dart"
Cohesion: 0.22
Nodes (7): RecursosRepositoryImpl, crear, listar, obtener, RecursosRepository, reportar, _RecursosFalso

### Community 79 - "token_storage.dart"
Cohesion: 0.11
Nodes (11): ApiConfig, _override, reintentosLectura, servidorProduccion, timeout, borrarToken, _clave, guardarToken (+3 more)

### Community 80 - "schemas/salones.py"
Cohesion: 0.21
Nodes (6): AuditoriaResponse, FranjaDisponible, SalonConDisponibilidad, SalonCreate, SalonResponse, SalonUpdate

### Community 81 - "UTB Tracker — app móvil (Flutter)"
Cohesion: 0.25
Nodes (7): Arquitectura (Clean Architecture, Blueprint FastAPI + Flutter), Banderas útiles, Cómo correrla, Dirección del API ("el laberinto de la red local", Blueprint), Figuras, Qué usa del backend, UTB Tracker — app móvil (Flutter)

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

### Community 102 - "listar_recursos"
Cohesion: 0.16
Nodes (5): actualizar_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso()

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.08
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.10
Nodes (18): _busqueda, _carga, cargar, _coincide, contar, _error, etiqueta, fijarBusqueda (+10 more)

### Community 106 - "salones_admin_test.dart"
Cohesion: 0.12
Nodes (10): _clase, fallo, _json, listarOcupacion, main, ocupaciones, _ocupacionJson, registrarPresencia (+2 more)

### Community 107 - "control_test.dart"
Cohesion: 0.10
Nodes (13): SalonesAdminRepositoryImpl, SalonesAdminRepository, cambiarEstadoSolicitud, cambios, _json, listarTodasLasSolicitudes, listarTodosLosReportes, main (+5 more)

### Community 108 - "cuenta_page.dart"
Cohesion: 0.06
Nodes (24): AuditoriaPage, _AuditoriaPageState, build, _c, _color, createState, _cuerpo, initState (+16 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.10
Nodes (17): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+9 more)

### Community 110 - "win32_window.cpp"
Cohesion: 0.17
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "FlutterWindow"
Cohesion: 0.17
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 112 - "sqlalchemy"
Cohesion: 0.12
Nodes (8): downgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade()

### Community 113 - "mensajeria/README.md"
Cohesion: 0.11
Nodes (16): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller), 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas) (+8 more)

### Community 114 - "salones_controller.dart"
Cohesion: 0.12
Nodes (14): Carga, agregarHorario, _busqueda, cancelarPrestamoSalon, _carga, cargar, crear, _error (+6 more)

### Community 115 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (24): colorDeSituacion, _colorPrestado, d, _dos, etiquetaDeSituacion, formatearHora, h12, haceCuanto (+16 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.11
Nodes (22): 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad, _salon_con_clase() (+14 more)

### Community 117 - "json"
Cohesion: 0.22
Nodes (4): _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo()

### Community 118 - "salones_repository.dart"
Cohesion: 0.14
Nodes (12): SalonesRepositoryImpl, actualizarEstadoPrestamo, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, listarHorarios, listarPrestamosSalon (+4 more)

### Community 119 - "stats_data.dart"
Cohesion: 0.14
Nodes (13): ApiClient, _api, DashboardStats, equiposDisponibles, fromJson, _int, prestamosActivos, reportesAbiertos (+5 more)

### Community 120 - "utils.cpp"
Cohesion: 0.17
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "services/auth.py"
Cohesion: 0.13
Nodes (21): hash_password(), verify_password(), create_access_token(), create_refresh_token(), create_reset_password_token(), verify_refresh_token(), verify_reset_password_token(), verify_token() (+13 more)

### Community 124 - "Estrategia de Datos y Eventos — UTB Tracker"
Cohesion: 0.40
Nodes (5): 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Estrategia de Datos y Eventos — UTB Tracker

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.15
Nodes (10): cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, listarTodasLasSolicitudes, listarTodosLosReportes (+2 more)

### Community 126 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 127 - "time"
Cohesion: 0.20
Nodes (5): ejecutar_corrida(), ejecutar_peticion(), main(), obtener_token(), percentil()

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.15
Nodes (12): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login pide NOMBRE + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Instalar la app en un celular Android (APK), 7. Pruebas (+4 more)

### Community 130 - "fcm_registration.dart"
Cohesion: 0.13
Nodes (8): FcmRegistration, FcmTokenRegistrar, _injected, _messaging, _registrar, start, stop, _tokenSubscription

### Community 131 - "get_current_user"
Cohesion: 0.22
Nodes (4): get_current_user(), 4. Tabla de Amenazas Priorizadas (P × I), test_login_exitoso_genera_jwt(), test_registro_usuario_exitoso()

### Community 133 - "recursos_data.dart"
Cohesion: 0.15
Nodes (9): _api, crear, desdeJson, listar, obtener, RecursoModel, RecursosRemoteDataSource, _remoto (+1 more)

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.13
Nodes (15): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+7 more)

### Community 135 - "bom.json"
Cohesion: 0.17
Nodes (11): bomFormat, components, dependencies, metadata, timestamp, tools, $schema, serialNumber (+3 more)

### Community 137 - "List"
Cohesion: 0.11
Nodes (11): actualizar, _cargando, cargar, _error, _items, _remote, _cargando, cargar (+3 more)

### Community 143 - "services/resources.py"
Cohesion: 0.19
Nodes (7): publicar_evento(), actualizar_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso()

### Community 144 - "0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes"
Cohesion: 0.33
Nodes (6): 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 145 - "Win32Window"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 146 - "Política y Modelo de Privacidad de Datos — UTB Tracker"
Cohesion: 0.18
Nodes (11): 1. Marco Legal y Principios de Tratamiento, 2. Inventario Exhaustivo de Datos Personales en el Modelo de Datos, 3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios, 3.2 Correo en Logs del Notificador Simulado, 3.3 Datos en Carga Útil del Outbox, 3.4 Campo `profesor` en Horarios Académicos, 3. Análisis de Minimización de Datos y Brechas Detectadas, 4. Hallazgos de Privacidad Ligados al Modelado de Amenazas (+3 more)

### Community 148 - "Conceptos transversales (Cross-cutting Concepts)"
Cohesion: 0.18
Nodes (11): 8.10 Arquitectura de Seguridad y Privacidad (S13), 8.1 Patrón de Capas y Control de Erosión Arquitectónica, 8.2 Seguridad, Hashing y Autenticación, 8.3 Observabilidad y Logging Estructurado, 8.4 Evaluación de Inteligencia Artificial Generativa en el Producto (req. 9.9), 8.5 Resiliencia, Timeouts y Reintentos (S11 — req. 11.1 y 11.2), 8.6 Idempotencia y Prevención de Condiciones de Carrera (S11 — req. 11.3 y R-02), 8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6) (+3 more)

### Community 149 - "api"
Cohesion: 0.22
Nodes (8): build, ports, restart, name, services, api, volumes, datos-postgres

### Community 150 - "ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)"
Cohesion: 0.29
Nodes (7): ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR), Alternativas Evaluadas, Consecuencias, Contexto, Decisión, Estado, Fecha

### Community 152 - "schemas.py"
Cohesion: 0.20
Nodes (10): MantenimientoRecursoCreate, MantenimientoRecursoOut, PaginatedResponse, PrestamoCreate, PrestamoDevolver, PrestamoOut, RecursoOut, RecursoUpdate (+2 more)

### Community 153 - "environment"
Cohesion: 0.56
Nodes (9): environment, CORS_ORIGINS, DATABASE_URL, ENVIRONMENT, FORGET_PWD_SECRET_KEY, SECRET_KEY, environment, environment (+1 more)

### Community 155 - "worker"
Cohesion: 0.25
Nodes (8): condition, api, depends_on, worker, build, command, depends_on, restart

### Community 156 - "services/maintenance.py"
Cohesion: 0.20
Nodes (7): actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos(), MantenimientoRecursoUpdate, actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 158 - "web"
Cohesion: 0.25
Nodes (8): API_BASE_URL, args, context, web, build, depends_on, ports, restart

### Community 163 - "test_resilience.py"
Cohesion: 0.13
Nodes (7): CircuitBreakerOpenException, CircuitBreakerState, with_retry(), _crear_recurso(), test_idempotencia_prestamo_con_misma_clave(), test_with_retry_exito_tras_fallo_transitorio(), test_with_retry_lanza_excepcion_al_superar_maximo()

### Community 165 - "4. Tabla de Amenazas Priorizadas (P × I)"
Cohesion: 0.29
Nodes (5): _crear_recurso(), test_devolver_prestamo(), test_devolver_prestamo_ya_devuelto_rechaza(), test_no_permite_prestar_recurso_no_disponible(), test_prestamo_exitoso_cambia_estado_del_recurso()

### Community 167 - "DateTime"
Cohesion: 0.10
Nodes (11): IdempotenciaRegistro, MantenimientoRecurso, Prestamo, Recurso, Reporte, Horario, PrestamoSalon, Salon (+3 more)

### Community 168 - "Escenarios de calidad"
Cohesion: 0.17
Nodes (10): Descripción general de los requisitos de calidad, Escenarios de calidad, QS-01 — Disponibilidad, QS-02 — Rendimiento (tiempo de respuesta), QS-03 — Rendimiento (concurrencia), QS-04 — Seguridad, QS-05 — Usabilidad, QS-06 — Confiabilidad de los datos (+2 more)

### Community 171 - "db"
Cohesion: 0.25
Nodes (8): environment, image, restart, volumes, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, db

### Community 172 - "Identidad visual de UTB Tracker"
Cohesion: 0.29
Nodes (6): Colores, Dónde se aplica, Identidad visual de UTB Tracker, Lenguaje visual (ADR-0011), Símbolo, Tono

### Community 176 - "x-backend"
Cohesion: 0.29
Nodes (7): depends_on, condition, db, x-backend, build, depends_on, restart

### Community 180 - "filtros_sheet.dart"
Cohesion: 0.14
Nodes (13): build, _categoria, createState, _estado, _FiltrosSheet, _FiltrosSheetState, kTodosLosSalones, mostrarFiltros (+5 more)

### Community 196 - "0012 - Empaquetar el sistema en contenedores con Docker Compose"
Cohesion: 0.29
Nodes (6): 0012 - Empaquetar el sistema en contenedores con Docker Compose, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 197 - "healthcheck"
Cohesion: 0.53
Nodes (6): healthcheck, healthcheck, interval, retries, test, timeout

### Community 198 - "time"
Cohesion: 0.15
Nodes (3): logging_middleware(), test_concurrencia_prestamos_mismo_recurso_postgresql(), test_rendimiento_latencia_p95_salud()

### Community 199 - "seed"
Cohesion: 0.40
Nodes (5): build, command, profiles, restart, seed

### Community 200 - "mantenimiento_data.dart"
Cohesion: 0.15
Nodes (12): actualizar, _api, descripcion, estado, fechaProgramada, fromJson, id, listar (+4 more)

### Community 201 - "routers/prestamos_salon.py"
Cohesion: 0.26
Nodes (4): crear_prestamo_salon(), PrestamoSalonCreate, PrestamoSalonResponse, PrestamoSalonUpdate

### Community 202 - "Win32Window"
Cohesion: 0.21
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 204 - "NotificadorBase"
Cohesion: 0.25
Nodes (5): NotificadorBase, 1. Simplificaciones Asumidas en el Diseño, 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa, 4. Requisitos para Transición a Producción, Límites del Experimento: Mensajería Asíncrona

### Community 205 - "prestamos_repository.dart"
Cohesion: 0.25
Nodes (6): PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository, _PrestamosFalso

### Community 206 - "crear_recurso"
Cohesion: 0.40
Nodes (3): crear_recurso(), RecursoCreate, crear_recurso()

### Community 207 - "0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción"
Cohesion: 0.33
Nodes (6): 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 208 - "Evidencia: la prueba de contrato falla ante un cambio incompatible"
Cohesion: 0.40
Nodes (4): Con el cambio incompatible presente, Después de revertir el cambio, Evidencia: la prueba de contrato falla ante un cambio incompatible, Por qué esto demuestra que la prueba cumple su función

### Community 209 - "1. Las Cuatro Preguntas del Modelado de Amenazas"
Cohesion: 0.40
Nodes (5): 1.1 ¿Qué estamos construyendo?, 1.2 ¿Qué puede salir mal?, 1.3 ¿Qué hacemos al respecto?, 1.4 ¿Hicimos un buen trabajo?, 1. Las Cuatro Preguntas del Modelado de Amenazas

### Community 211 - "AuthRepository"
Cohesion: 0.67
Nodes (3): AuthRepositoryImpl, AuthRepository, _AuthFalso

## Knowledge Gaps
- **928 isolated node(s):** `_Modo`, `_form`, `_nombre`, `_email`, `_password` (+923 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1850 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **68 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Riesgos y deudas técnicas` connect `arc42.md` to `services/auth.py`, `DateTime`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_Modo`, `_form`, `_nombre` to the rest of the system?**
  _928 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `services/salones_admin.py` be split into smaller, more focused modules?**
  _Cohesion score 0.05393258426966292 - nodes in this community are weakly interconnected._
- **Why does `Usuario` connect `services/auth.py` to `demo_mensajeria.py`, `services/salones_admin.py`, `get_db`, `DateTime`, `worker.py`, `conftest.py`, `arc42.md`, `registrar`?**
  _High betweenness centrality (0.073) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `registrar()` (e.g. with `Consecuencias` and `Decisión`) actually correct?**
  _`registrar()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Should `with` be split into smaller, more focused modules?**
  _Cohesion score 0.05855855855855856 - nodes in this community are weakly interconnected._
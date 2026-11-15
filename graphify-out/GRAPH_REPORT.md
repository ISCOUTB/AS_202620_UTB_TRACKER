# Graph Report - AS_202620_UTB_TRACKER  (2026-11-14)

## Corpus Check
- 246 files · ~147,751 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 36 file(s) not represented in the graph (top: (none) 11, .xml 11, .properties 3)

## Summary
- 3589 nodes · 6318 edges · 190 communities (158 shown, 32 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 282 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0e799141`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- package:flutter/material.dart
- Recurso
- routers/salones_admin.py
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- salon_models.py
- UTB Tracker
- worker.py
- Aspectos — UTB Tracker
- Ficha del problema — UTB Tracker
- arc42.md
- stats_data.dart
- auth_controller_test.dart
- listar_horarios
- figuras.dart
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
- test_salones_tipo_equipamiento.py
- salon.dart
- controladores_test.dart
- recursos_controller.dart
- auditoria.dart
- equipos_page.dart
- json
- recurso_detalle_page.dart
- main.py
- routers/auth.py
- services/salones.py
- salones_page.dart
- test_auth.py
- escala.dart
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
- shell_page.dart
- prestamos_controller.dart
- auth_domain.dart
- PayloadPrestamoCreado
- control_controller.dart
- listar_prestamos_salon
- prestamos_data.dart
- Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02
- test_perfil.py
- Modelado de Amenazas y Plan de Mitigación — UTB Tracker
- correo.py
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- services/auditoria.py
- test_horarios.py
- services/perfil.py
- _run_loop
- security.py
- salon_control_page.dart
- Análisis de dependencias y gestión de secretos
- recursos_repository.dart
- token_storage.dart
- services/salones_admin.py
- UTB Tracker — app móvil (Flutter)
- analysis_options.yaml
- 0001 - Estilo arquitectónico: Monolito Modular
- 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)
- ADR-0004: Seguridad y Autenticación — JWT Autofirmado
- ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios
- Estrategia de solución
- schemas/salones.py
- Evidencia: la prueba de contrato falla ante un cambio incompatible
- FlutterActivity
- services/resources.py
- salon_control_controller.dart
- registrar_presencia
- salones_admin_controller.dart
- test_main.py
- control_test.dart
- cuenta_page.dart
- salones_admin_data.dart
- win32_window.cpp
- FlutterWindow
- sqlalchemy
- enums.py
- salones_controller.dart
- package:flutter/material.dart
- test_salones_admin.py
- json
- salones_repository.dart
- mantenimiento_data.dart
- utils.cpp
- Size
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- services/auth.py
- Estrategia de Datos y Eventos — UTB Tracker
- salones_admin_repository.dart
- manifest.json
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- .MessageHandler
- fcm_registration.dart
- get_db
- generated_plugin_registrant.cc
- _TransicionSuave
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- bom.json
- admin_usuarios_controller.dart
- 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes
- Point
- Política y Modelo de Privacidad de Datos — UTB Tracker
- seed
- ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)
- reporte_salon_sheet.dart
- schemas.py
- environment
- worker
- services/maintenance.py
- web
- test_correo_verificado.py
- schemas/perfil.py
- test_resilience.py
- 4. Tabla de Amenazas Priorizadas (P × I)
- seed_demo.py
- Escenarios de calidad
- db
- Identidad visual de UTB Tracker
- x-backend
- datetime
- api_config.dart
- 0012 - Empaquetar el sistema en contenedores con Docker Compose
- healthcheck
- time
- escala_test.dart
- verificar_correo_endpoint
- Win32Window
- mensajeria/README.md
- prestamos_repository.dart
- preferencias.dart
- tipo_salon_campos.dart
- 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos
- login
- plantillas_correo.py
- politica.dart
- test_identidad.py
- test_persistencia_cuentas.py
- ProveedorDesarrollo
- logging_middleware
- update_user_role_endpoint
- get_current_user
- 0015 - Servicio de correo con plantillas y entrega por el outbox
- Correo real y worker en el servidor oficial (ADR-0015)
- 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción
- require_role

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 80 edges
2. `Usuario` - 58 edges
3. `registrar()` - 43 edges
4. `MensajeOutbox` - 39 edges
5. `Salon` - 29 edges
6. `procesar_pendientes()` - 27 edges
7. `Recurso` - 26 edges
8. `NotificadorSimulado` - 25 edges
9. `4. Tabla de Amenazas Priorizadas (P × I)` - 25 edges
10. `PrestamoSalon` - 23 edges

## Surprising Connections (you probably didn't know these)
- `1.1 ¿Qué estamos construyendo?` --references--> `NotificadorBase`  [INFERRED]
  docs/seguridad/modelo-amenazas.md → app/messaging/worker.py
- `2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial` --references--> `_calcular_siguiente_intento()`  [INFERRED]
  docs/mensajeria/limites-del-experimento.md → app/messaging/worker.py
- `2. Matriz de Operaciones y Garantías de Consistencia` --references--> `PrestamoSalon`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/models/salon_models.py
- `3. Metodología de Verificación en el Repositorio` --references--> `get_user_endpoint()`  [INFERRED]
  docs/datos/README.md → app/routers/auth.py
- `Consecuencias` --references--> `registrar()`  [INFERRED]
  docs/adr/0010-auditoria.md → app/services/auditoria.py

## Import Cycles
- None detected.

## Communities (190 total, 32 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.22
Nodes (9): Despliegue reproducible con Docker Compose (ADR-0012), Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View (+1 more)

### Community 1 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (25): AuditoriaController, build, _c, _color, createState, _cuerpo, initState, AvisoVerificacion (+17 more)

### Community 2 - "Recurso"
Cohesion: 0.20
Nodes (10): cuenta y correo (ADR-0014, ADR-0015, ADR-0016), Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, salones: tipo y equipamiento (ADR-0017), Vista general del sistema (+2 more)

### Community 3 - "routers/salones_admin.py"
Cohesion: 0.29
Nodes (8): ClaseActual, OcupacionSalon, PresenciaResponse, PresenciaUpdate, PrestamoActual, ReporteSalonCreate, ReporteSalonResponse, ReporteSalonUpdate

### Community 4 - "with"
Cohesion: 0.06
Nodes (36): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+28 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 6 - "salon_models.py"
Cohesion: 0.08
Nodes (19): Horario, PrestamoSalon, actualizar_horario(), crear_horario(), crear_horarios_bulk(), _detectar_conflicto(), eliminar_horario(), listar_horarios() (+11 more)

### Community 7 - "UTB Tracker"
Cohesion: 0.12
Nodes (16): API pública, Arquitectura del proyecto, Backend: monolito modular y capas, Desarrollo local, Despliegue, Despliegue y Acceso Público, Ejecutar con Docker (ADR-0012), Estado actual (+8 more)

### Community 8 - "worker.py"
Cohesion: 0.15
Nodes (16): NotificacionProcesada, _calcular_siguiente_intento(), _construir_notificacion(), _descartar_duplicado(), _leer_payload(), _marcar_enviado(), _marcar_muerto(), _preferencia_permite() (+8 more)

### Community 9 - "Aspectos — UTB Tracker"
Cohesion: 0.17
Nodes (12): A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar, A-05 · Declarar, A-06 · Declarar, A-07 · Declarar, A-08 · Declarar (+4 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.12
Nodes (13): Contexto de negocio, Contexto técnico, Contexto y alcance, Decisiones arquitectónicas, Descripción general de los requisitos, Introducción y objetivos, Objetivos de calidad, Restricciones arquitectónicas (+5 more)

### Community 12 - "stats_data.dart"
Cohesion: 0.09
Nodes (18): _api, DashboardStats, equiposDisponibles, fromJson, _int, prestamosActivos, reportesAbiertos, resumen (+10 more)

### Community 13 - "auth_controller_test.dart"
Cohesion: 0.06
Nodes (32): FcmRegistration, AuthRepositoryImpl, AuthRepository, actualizarRolUsuario, _AuthFalso, crear, falloRegistro, _FcmFalso (+24 more)

### Community 14 - "listar_horarios"
Cohesion: 0.13
Nodes (6): actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario()

### Community 15 - "figuras.dart"
Cohesion: 0.13
Nodes (14): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+6 more)

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.04
Nodes (49): _abrirAgregarHorario, _abrirSolicitudPrestamo, _AgregarHorarioSheet, _AgregarHorarioSheetState, _auth, build, _cambiarDia, _cancelarSolicitud (+41 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.10
Nodes (20): MensajeOutbox, publicar_evento(), NotificadorSimulado, procesar_pendientes(), _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker(), test_idempotencia_http_con_x_idempotency_key() (+12 more)

### Community 23 - "control_page.dart"
Cohesion: 0.08
Nodes (23): _auth, build, _cambiar, _colorSolicitud, _contenido, _control, ControlPage, _ControlPageState (+15 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.12
Nodes (15): build, _categoria, CrearRecursoPage, _CrearRecursoPageState, createState, dispose, _error, _form (+7 more)

### Community 25 - "Diseño de Estrategia de Caché e Invalidación — UTB Tracker"
Cohesion: 0.11
Nodes (18): 1.1 Regla Central de Oro (Aislamiento de Invariantes), 1.2 Endpoints Incluidos en Caché, 1.3 Endpoints Excluidos de Caché, 1. Alcance y Reglas de Integridad, 2.1 En Proceso vs. Redis Distribuido, 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia, 2. Topología de Caché y Decisión de Ubicación, 3.1 Formato Canónico de Claves (+10 more)

### Community 26 - "app_theme.dart"
Cohesion: 0.08
Nodes (24): AppColors, AppTheme, borde, build, child, danado, degradado, disponible (+16 more)

### Community 27 - "home_page.dart"
Cohesion: 0.06
Nodes (33): AdminUsuariosController, AuthController, ControlController, _auth, build, codigo, _CodigoSalon, color (+25 more)

### Community 28 - "test_salones_tipo_equipamiento.py"
Cohesion: 0.16
Nodes (16): 0017 - Tipo de salón y equipamiento calculado desde los recursos, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad, _recursos() (+8 more)

### Community 29 - "salon.dart"
Cohesion: 0.04
Nodes (44): activo, api, capacidad, categoria, createdAt, descripcion, desdeApi, diaNombre (+36 more)

### Community 30 - "controladores_test.dart"
Cohesion: 0.07
Nodes (20): actualizarRolUsuario, crear, datos, devolver, fallo, iniciarSesion, listar, listarUsuarios (+12 more)

### Community 31 - "recursos_controller.dart"
Cohesion: 0.08
Nodes (23): _busqueda, _carga, cargar, _categoria, crear, disponiblesDe, _error, _estado (+15 more)

### Community 32 - "auditoria.dart"
Cohesion: 0.11
Nodes (18): accion, actorNombre, _api, AuditoriaRepository, AuditoriaRepositoryImpl, _carga, cargar, detalle (+10 more)

### Community 33 - "equipos_page.dart"
Cohesion: 0.04
Nodes (45): _cuerpoAuxiliar, _cuerpoUsuario, _auth, build, _buscar, _CabeceraSalon, _ChipsActivos, codigo (+37 more)

### Community 34 - "json"
Cohesion: 0.25
Nodes (14): _auditoria(), _login(), _salon_con_clase(), test_confirmar_presencia_deja_quien_cuando_y_que(), test_crud_de_salones_y_horarios_se_audita(), test_el_auxiliar_no_ve_la_bitacora(), test_el_cambio_de_rol_registra_quien_lo_hizo(), test_exportar_csv_trae_encabezado_y_filas() (+6 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.05
Nodes (39): _abrirCambiarRol, _auth, build, _busquedaCtrl, _controller, createState, dispose, initState (+31 more)

### Community 36 - "main.py"
Cohesion: 0.10
Nodes (5): AuditoriaResponse, HorarioBulkCreate, HorarioCreate, HorarioResponse, HorarioUpdate

### Community 37 - "routers/auth.py"
Cohesion: 0.15
Nodes (14): CambiarCorreoRequest, FcmTokenRequest, ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest, TokenResponse, UserMeResponse, UserResponse (+6 more)

### Community 38 - "services/salones.py"
Cohesion: 0.13
Nodes (6): actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon()

### Community 39 - "salones_page.dart"
Cohesion: 0.06
Nodes (36): _abrirCrearSalon, _abrirSolicitud, _auth, _busquedaCtrl, _capacidadCtrl, _construirCuerpo, _CrearSalonSheet, _CrearSalonSheetState (+28 more)

### Community 40 - "test_auth.py"
Cohesion: 0.08
Nodes (9): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_login_exitoso_genera_jwt(), test_registro_fuerza_rol_usuario_utb() (+1 more)

### Community 41 - "escala.dart"
Cohesion: 0.08
Nodes (16): _auth, build, createState, initState, _Raiz, _RaizState, UtbTrackerApp, build (+8 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.08
Nodes (12): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_vencidos(), marcar_vencidos_job(), crear_prestamo(), devolver_prestamo(), listar_prestamos() (+4 more)

### Community 43 - "with"
Cohesion: 0.09
Nodes (21): defaults, runs-on, steps, run, jobs, build, name, permissions (+13 more)

### Community 44 - "auth_controller.dart"
Cohesion: 0.05
Nodes (38): actualizarPerfil, _adoptarTokens, _api, autenticado, _aviso, cambiarPassword, cambiarServidor, _cargando (+30 more)

### Community 45 - "recurso.dart"
Cohesion: 0.07
Nodes (23): categoria, categoriaCodigo, CategoriaRecurso, codigo, creables, descripcion, desde, disponible (+15 more)

### Community 46 - "auth_data.dart"
Cohesion: 0.08
Nodes (22): actualizarRolUsuario, _api, AuthRemoteDataSource, desdeJson, _identificar, iniciarSesion, _intentarUsuario, listarUsuarios (+14 more)

### Community 47 - "utilidades.dart"
Cohesion: 0.10
Nodes (20): abs, azar, bytes, cantidad, d, describirPlazo, _dos, endsWith (+12 more)

### Community 48 - "ocupacion.dart"
Cohesion: 0.04
Nodes (42): abierto, clase, ClaseActual, creadoEn, descripcion, desde, enUso, estado (+34 more)

### Community 49 - "api_client.dart"
Cohesion: 0.07
Nodes (23): _azar, baseUrl, _baseUrlFijo, _cabeceras, cerrar, _client, _conReintentos, delete (+15 more)

### Community 50 - "login_page.dart"
Cohesion: 0.04
Nodes (44): auth, clave, correo, enviado, form, mostrarCambiarCorreo, accion, _auth (+36 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.10
Nodes (19): actualizarEstadoPrestamo, actualizarTipoYDescripcion, _api, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, desdeJson (+11 more)

### Community 52 - "pubspec.yaml"
Cohesion: 0.04
Nodes (45): color, icon_background_color, image, dependencies, firebase_core, firebase_messaging, flutter, flutter_secure_storage (+37 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.08
Nodes (18): ApiException, _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado (+10 more)

### Community 54 - "injection.dart"
Cohesion: 0.07
Nodes (3): configurarDependencias, reset, sl

### Community 55 - "StatelessWidget"
Cohesion: 0.03
Nodes (71): _CampoUber, _Marca, _Selector, _Chip, _Fila, _Seccion, _Titulo, accion (+63 more)

### Community 56 - "registrar"
Cohesion: 0.17
Nodes (9): _prohibir_actualizar(), _prohibir_borrar(), RegistroAuditoria, exportar_csv(), _filtrar(), listar(), registrar(), registrar_y_confirmar() (+1 more)

### Community 57 - "shell_page.dart"
Cohesion: 0.11
Nodes (10): _BarraInferior, build, createState, _indice, _ir, _irSalones, _items, onTap (+2 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.07
Nodes (27): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+19 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.07
Nodes (25): actualizarRolUsuario, colorAvatar, dependencia, email, emailVerificado, id, iniciarSesion, listarUsuarios (+17 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.13
Nodes (15): EventoDominio, EventoPrestamoCreado, PayloadPrestamoCreado, PayloadPrestamoDevuelto, PayloadRecursoReportado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`) (+7 more)

### Community 61 - "control_controller.dart"
Cohesion: 0.12
Nodes (12): _accion, cambiarSolicitud, _carga, cargar, _error, pendientes, _repo, _reportes (+4 more)

### Community 62 - "listar_prestamos_salon"
Cohesion: 0.09
Nodes (9): actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon(), expirar_prestamos_pendientes(), listar_prestamos_salon(), obtener_prestamo_salon(), PrestamoSalonCreate, PrestamoSalonResponse (+1 more)

### Community 63 - "prestamos_data.dart"
Cohesion: 0.17
Nodes (8): _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource, _remoto

### Community 64 - "Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02"
Cohesion: 0.10
Nodes (19): 1. Escenarios de Calidad Evaluados (arc42 Sección 10), 2.1 Scripts Utilizados, 2.2 Endpoints Medidos, 2.3 Requisitos para Reproducir, 2.4 Comandos de Reproducción, 2. Método de Medición, 3. Entorno de Ejecución, 4.1 Resumen Tabular (+11 more)

### Community 65 - "test_perfil.py"
Cohesion: 0.19
Nodes (14): Trazabilidad, _acciones(), buzon(), _entregar(), _plantillas(), _sesion(), test_cambiar_password_cierra_las_demas_sesiones(), test_cambio_de_correo_solo_al_abrir_el_enlace_y_avisa_al_anterior() (+6 more)

### Community 66 - "Modelado de Amenazas y Plan de Mitigación — UTB Tracker"
Cohesion: 0.12
Nodes (15): 1.1 ¿Qué estamos construyendo?, 1.2 ¿Qué puede salir mal?, 1.3 ¿Qué hacemos al respecto?, 1.4 ¿Hicimos un buen trabajo?, 1. Las Cuatro Preguntas del Modelado de Amenazas, 2.1 Catálogo de Activos, 2.2 Fronteras de Confianza (Trust Boundaries), 2.3 Diagrama de Fronteras de Confianza (Mermaid) (+7 more)

### Community 67 - "correo.py"
Cohesion: 0.18
Nodes (7): correo_valido(), normalizar_correo(), _correo(), _construir(), encolar(), categoria(), renderizar()

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.04
Nodes (41): _abrir, activo, _actualizado, _auth, _Aviso, build, _c, _Cabecera (+33 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "services/perfil.py"
Cohesion: 0.16
Nodes (3): emitir_tokens(), cambiar_password(), cerrar_sesiones()

### Community 73 - "_run_loop"
Cohesion: 0.07
Nodes (14): crear_notificador(), crear_notificador_push(), _enviar_notificacion(), NotificadorBase, NotificadorConPush, NotificadorFCM, NotificadorSMTP, _run_loop() (+6 more)

### Community 74 - "security.py"
Cohesion: 0.19
Nodes (12): crear_token_proposito(), create_access_token(), create_refresh_token(), create_reset_password_token(), leer_access_token(), leer_refresh_token(), _leer_sesion(), Sujeto (+4 more)

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
Cohesion: 0.13
Nodes (11): borrarToken, _clave, _claveRefresh, _claveServidor, guardarServidor, guardarTokens, leerRefresh, leerServidor (+3 more)

### Community 80 - "services/salones_admin.py"
Cohesion: 0.09
Nodes (27): ReporteSalon, Salon, SalonCreate, adjuntar(), calcular(), filtro_con_equipo(), sugerir_tipo(), actualizar_salon() (+19 more)

### Community 81 - "UTB Tracker — app móvil (Flutter)"
Cohesion: 0.13
Nodes (13): 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Arquitectura (Clean Architecture, Blueprint FastAPI + Flutter), Banderas útiles (+5 more)

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

### Community 88 - "schemas/salones.py"
Cohesion: 0.23
Nodes (6): EquipoCategoria, FranjaDisponible, _recortar_descripcion(), SalonConDisponibilidad, SalonResponse, SalonUpdate

### Community 89 - "Evidencia: la prueba de contrato falla ante un cambio incompatible"
Cohesion: 0.40
Nodes (4): Con el cambio incompatible presente, Después de revertir el cambio, Evidencia: la prueba de contrato falla ante un cambio incompatible, Por qué esto demuestra que la prueba cumple su función

### Community 102 - "services/resources.py"
Cohesion: 0.09
Nodes (14): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso(), actualizar_recurso() (+6 more)

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.09
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "registrar_presencia"
Cohesion: 0.18
Nodes (7): actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), listar_todos_los_reportes(), obtener_ocupacion(), registrar_presencia()

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.08
Nodes (22): _busqueda, _carga, cargar, _coincide, _conEquipo, contar, _error, etiqueta (+14 more)

### Community 107 - "control_test.dart"
Cohesion: 0.06
Nodes (24): cambiarEstadoSolicitud, cambios, _json, listarTodasLasSolicitudes, listarTodosLosReportes, main, pidioReportes, _reporte (+16 more)

### Community 108 - "cuenta_page.dart"
Cohesion: 0.06
Nodes (33): _abrir, _auth, build, _Cabecera, _cambiarPassword, child, color, colorDeHex (+25 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.10
Nodes (17): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+9 more)

### Community 110 - "win32_window.cpp"
Cohesion: 0.17
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "FlutterWindow"
Cohesion: 0.12
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 112 - "sqlalchemy"
Cohesion: 0.07
Nodes (12): downgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade() (+4 more)

### Community 113 - "enums.py"
Cohesion: 0.29
Nodes (9): DiaSemana, EstadoPrestamo, EstadoPrestamoSalon, EstadoRecurso, EstadoReporteSalon, EstadoSalon, RolUsuario, TipoReporteSalon (+1 more)

### Community 114 - "salones_controller.dart"
Cohesion: 0.11
Nodes (15): Carga, actualizarTipoYDescripcion, agregarHorario, _busqueda, cancelarPrestamoSalon, _carga, cargar, crear (+7 more)

### Community 115 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (15): AsaHoja, AvatarIniciales, BotonPildora, build, cargando, color, compacto, estilo (+7 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.17
Nodes (16): Trazabilidad, _salon_con_clase(), test_confirmar_presencia_se_refleja_en_la_ocupacion(), test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(), test_listar_ocupacion_incluye_todos_los_salones(), test_presencia_requiere_rol_administrador(), test_presencia_se_puede_corregir_sin_duplicar(), test_presencia_sin_clase_en_curso_da_409() (+8 more)

### Community 117 - "json"
Cohesion: 0.32
Nodes (4): _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo()

### Community 118 - "salones_repository.dart"
Cohesion: 0.13
Nodes (13): SalonesRepositoryImpl, actualizarEstadoPrestamo, actualizarTipoYDescripcion, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, listarHorarios (+5 more)

### Community 119 - "mantenimiento_data.dart"
Cohesion: 0.08
Nodes (22): ApiClient, actualizar, _api, descripcion, estado, fechaProgramada, fromJson, id (+14 more)

### Community 120 - "utils.cpp"
Cohesion: 0.13
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 121 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "services/auth.py"
Cohesion: 0.12
Nodes (22): leer_token_proposito(), Usuario, TokenUsado, abrir_enlace_correo(), _ahora(), aplicar_nueva_password(), buscar_por_correo(), _buscar_por_nombre() (+14 more)

### Community 124 - "Estrategia de Datos y Eventos — UTB Tracker"
Cohesion: 0.40
Nodes (5): 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Estrategia de Datos y Eventos — UTB Tracker

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.12
Nodes (15): SalonesAdminRepositoryImpl, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, listarTodasLasSolicitudes (+7 more)

### Community 126 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 127 - "time"
Cohesion: 0.18
Nodes (6): ejecutar_corrida(), ejecutar_peticion(), main(), obtener_token(), percentil(), test_rendimiento_latencia_p95_salud()

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.13
Nodes (14): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login acepta el NOMBRE o el CORREO + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Instalar la app en un celular Android (APK), 7. Pruebas (+6 more)

### Community 130 - "fcm_registration.dart"
Cohesion: 0.14
Nodes (7): FcmTokenRegistrar, _injected, _messaging, _registrar, start, stop, _tokenSubscription

### Community 131 - "get_db"
Cohesion: 0.19
Nodes (15): get_db(), actualizar_perfil_endpoint(), cambiar_correo_endpoint(), cambiar_password_endpoint(), cerrar_sesiones_endpoint(), desactivar_cuenta_endpoint(), forgot_password_endpoint(), get_user_endpoint() (+7 more)

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.13
Nodes (15): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+7 more)

### Community 135 - "bom.json"
Cohesion: 0.17
Nodes (11): bomFormat, components, dependencies, metadata, timestamp, tools, $schema, serialNumber (+3 more)

### Community 137 - "admin_usuarios_controller.dart"
Cohesion: 0.07
Nodes (20): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+12 more)

### Community 144 - "0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes"
Cohesion: 0.25
Nodes (7): 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad

### Community 145 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 146 - "Política y Modelo de Privacidad de Datos — UTB Tracker"
Cohesion: 0.17
Nodes (12): 1. Marco Legal y Principios de Tratamiento, 2. Inventario Exhaustivo de Datos Personales en el Modelo de Datos, 3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios, 3.2 Correo en Logs del Notificador Simulado, 3.3 Datos en Carga Útil del Outbox, 3.4 Campo `profesor` en Horarios Académicos, 3. Análisis de Minimización de Datos y Brechas Detectadas, 4. Hallazgos de Privacidad Ligados al Modelado de Amenazas (+4 more)

### Community 149 - "seed"
Cohesion: 0.18
Nodes (10): name, build, command, profiles, restart, volumes, services, seed (+2 more)

### Community 150 - "ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)"
Cohesion: 0.29
Nodes (7): ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR), Alternativas Evaluadas, Consecuencias, Contexto, Decisión, Estado, Fecha

### Community 151 - "reporte_salon_sheet.dart"
Cohesion: 0.08
Nodes (21): build, createState, _descripcion, dispose, _enviando, _enviar, _error, mostrarReporteSalonSheet (+13 more)

### Community 152 - "schemas.py"
Cohesion: 0.19
Nodes (12): CategoriaRecurso, MantenimientoRecursoOut, MantenimientoRecursoUpdate, PaginatedResponse, PrestamoCreate, PrestamoDevolver, PrestamoOut, RecursoCreate (+4 more)

### Community 153 - "environment"
Cohesion: 0.34
Nodes (20): environment, CORREOS_DIR, CORS_ORIGINS, DATABASE_URL, EMAIL_TOKEN_SECRET_KEY, ENVIRONMENT, FORGET_PWD_SECRET_KEY, SECRET_KEY (+12 more)

### Community 155 - "worker"
Cohesion: 0.22
Nodes (9): condition, api, depends_on, worker, build, command, depends_on, restart (+1 more)

### Community 156 - "services/maintenance.py"
Cohesion: 0.19
Nodes (8): MantenimientoRecurso, actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos(), MantenimientoRecursoCreate, actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 158 - "web"
Cohesion: 0.25
Nodes (8): API_BASE_URL, args, context, web, build, depends_on, ports, restart

### Community 160 - "test_correo_verificado.py"
Cohesion: 0.16
Nodes (27): Trazabilidad, 4. Tabla de Amenazas Priorizadas (P × I), _acciones(), _correos(), _entregar(), _login(), _registrar(), test_alerta_si_entra_tras_varios_fallos() (+19 more)

### Community 162 - "schemas/perfil.py"
Cohesion: 0.13
Nodes (8): normalizar_nombre(), Canal, Notificaciones, PerfilResponse, PerfilUpdate, Preferencias, SesionRenovada, actualizar_perfil()

### Community 163 - "test_resilience.py"
Cohesion: 0.05
Nodes (26): CircuitBreaker, wrapper(), CircuitBreakerOpenException, CircuitBreakerState, with_retry(), decorator(), wrapper(), 8.10 Arquitectura de Seguridad y Privacidad (S13) (+18 more)

### Community 165 - "4. Tabla de Amenazas Priorizadas (P × I)"
Cohesion: 0.29
Nodes (5): _crear_recurso(), test_devolver_prestamo(), test_devolver_prestamo_ya_devuelto_rechaza(), test_no_permite_prestar_recurso_no_disponible(), test_prestamo_exitoso_cambia_estado_del_recurso()

### Community 167 - "seed_demo.py"
Cohesion: 0.11
Nodes (10): hash_password(), verify_password(), Reporte, PresenciaSalon, resumen(), inventario(), limpiar(), main() (+2 more)

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
Cohesion: 0.15
Nodes (13): build, depends_on, ports, restart, volumes, condition, db, api (+5 more)

### Community 179 - "datetime"
Cohesion: 0.07
Nodes (10): IdempotenciaRegistro, Prestamo, Recurso, sembrar(), admin_headers(), auth_headers(), client(), db_session() (+2 more)

### Community 185 - "api_config.dart"
Cohesion: 0.10
Nodes (14): ApiConfig, baseUrl, describir, _elegido, elegir, esOficial, _override, permiteCambiarServidor (+6 more)

### Community 196 - "0012 - Empaquetar el sistema en contenedores con Docker Compose"
Cohesion: 0.29
Nodes (6): 0012 - Empaquetar el sistema en contenedores con Docker Compose, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 197 - "healthcheck"
Cohesion: 0.53
Nodes (6): healthcheck, healthcheck, interval, retries, test, timeout

### Community 199 - "escala_test.dart"
Cohesion: 0.10
Nodes (13): configurarDependencias, _json, main, _nombreLargo, _ocupacion, _pintar, _preparar, pump (+5 more)

### Community 200 - "verificar_correo_endpoint"
Cohesion: 0.16
Nodes (9): _html(), me_endpoint(), restablecer_pagina_endpoint(), verificar_correo_endpoint(), correo_cambiado(), correo_verificado(), enlace_invalido(), formulario_restablecer() (+1 more)

### Community 202 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 203 - "mensajeria/README.md"
Cohesion: 0.11
Nodes (16): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller), 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas) (+8 more)

### Community 205 - "prestamos_repository.dart"
Cohesion: 0.25
Nodes (6): PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository, _PrestamosFalso

### Community 206 - "preferencias.dart"
Cohesion: 0.11
Nodes (16): aJson, api, aviso, avisos, CanalAviso, CategoriaAviso, conAviso, conPantallaInicio (+8 more)

### Community 207 - "tipo_salon_campos.dart"
Cohesion: 0.12
Nodes (15): build, CamposTipoSalon, createState, descripcion, dispose, _EditarTipoSheet, _EditarTipoSheetState, _error (+7 more)

### Community 208 - "0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos"
Cohesion: 0.29
Nodes (6): 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 209 - "login"
Cohesion: 0.13
Nodes (14): IntentoLimitado, login(), reenviar_verificacion(), ocultar_correo(), _ahora(), anotar(), contar(), exigir() (+6 more)

### Community 210 - "plantillas_correo.py"
Cohesion: 0.41
Nodes (13): bienvenida(), _boton(), cambio_correo_aviso(), cambio_correo_nuevo(), cambio_password(), _codigo(), _e(), _enlace_seguro() (+5 more)

### Community 211 - "politica.dart"
Cohesion: 0.13
Nodes (11): _correo, correoValido, errorPassword, msgCorreoInvalido, msgPasswordCorta, msgPasswordIgualCorreo, msgPasswordIgualNombre, normalizarCorreo (+3 more)

### Community 212 - "test_identidad.py"
Cohesion: 0.21
Nodes (13): error_password(), _mensajes(), _registrar(), test_campo_faltante_en_espanol(), test_correo_con_salto_de_linea_se_rechaza(), test_correo_se_guarda_normalizado(), test_error_de_login_no_revela_si_la_cuenta_existe(), test_indice_unico_frena_correos_repetidos_en_la_base() (+5 more)

### Community 213 - "test_persistencia_cuentas.py"
Cohesion: 0.28
Nodes (4): _apagar(), _levantar(), _puerto_libre(), test_cuenta_registrada_sobrevive_al_reinicio_de_la_api()

### Community 214 - "ProveedorDesarrollo"
Cohesion: 0.14
Nodes (7): crear_proveedor(), enviar(), Proveedor, ProveedorDesarrollo, ProveedorSMTP, Decisión, buzon()

### Community 215 - "logging_middleware"
Cohesion: 0.14
Nodes (5): logging_middleware(), _mensaje_422(), validacion_en_espanol(), health_check(), Tabla de trazabilidad

### Community 216 - "update_user_role_endpoint"
Cohesion: 0.22
Nodes (3): delete_user_endpoint(), get_users_endpoint(), update_user_role_endpoint()

### Community 220 - "get_current_user"
Cohesion: 0.12
Nodes (12): get_current_user(), require_verified(), sesion_vigente(), usuario_de_sujeto(), refresh_access_token(), 0014 - Autenticación con correo verificado, identidad normalizada y tokens por id, Alternativas consideradas, Consecuencias (+4 more)

### Community 221 - "0015 - Servicio de correo con plantillas y entrega por el outbox"
Cohesion: 0.14
Nodes (11): 0015 - Servicio de correo con plantillas y entrega por el outbox, Alternativas consideradas, Consecuencias, Contexto, Estado, 0016 - Perfil personalizable y preferencias guardadas en el servidor, Alternativas consideradas, Consecuencias (+3 more)

### Community 222 - "Correo real y worker en el servidor oficial (ADR-0015)"
Cohesion: 0.33
Nodes (5): 1. Variables nuevas en el `.env` del servidor, 2. Proveedor de correo recomendado, 3. Servicio systemd del worker, 4. Comprobar, Correo real y worker en el servidor oficial (ADR-0015)

### Community 223 - "0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción"
Cohesion: 0.29
Nodes (6): 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

## Knowledge Gaps
- **1129 isolated node(s):** `_auth`, `build`, `createState`, `initState`, `Figuras` (+1124 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2181 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Riesgos y deudas técnicas` connect `arc42.md` to `services/auth.py`, `datetime`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_auth`, `build`, `createState` to the rest of the system?**
  _1129 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05641025641025641 - nodes in this community are weakly interconnected._
- **Why does `get_db()` connect `get_db` to `routers/salones_admin.py`, `main.py`, `routers/auth.py`, `services/auditoria.py`, `services/resources.py`, `verificar_correo_endpoint`, `services/salones.py`, `listar_prestamos`, `registrar_presencia`, `seed_demo.py`, `listar_horarios`, `services/maintenance.py`, `test_messaging.py`, `datetime`, `logging_middleware`, `update_user_role_endpoint`, `get_current_user`, `listar_prestamos_salon`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 37 INFERRED edges - model-reasoned connections that need verification._
- **Should `with` be split into smaller, more focused modules?**
  _Cohesion score 0.05855855855855856 - nodes in this community are weakly interconnected._
# Graph Report - AS_202620_UTB_TRACKER  (2026-11-16)

## Corpus Check
- 269 files · ~164,822 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 10, .example 1, .properties 1)

## Summary
- 4033 nodes · 7428 edges · 198 communities (162 shown, 36 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 340 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `788b900a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- StatelessWidget
- Recurso
- ../core/theme/app_theme.dart
- with
- 0003 - Estrategia de integración: síncrona (REST sobre HTTP)
- Salon
- UTB Tracker
- worker.py
- Horario
- Ficha del problema — UTB Tracker
- arc42.md
- stats_data.dart
- auth_controller_test.dart
- preferencias.dart
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
- typing
- routers/auth.py
- routers/salones.py
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
- flutter_launcher_icons
- api_client_test.dart
- injection.dart
- StatelessWidget
- registrar
- asignaciones_page.dart
- prestamos_controller.dart
- auth_domain.dart
- PayloadPrestamoCreado
- control_controller.dart
- listar_prestamos_salon
- test_foto_perfil.py
- Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02
- test_perfil.py
- Modelado de Amenazas y Plan de Mitigación — UTB Tracker
- services/salones_admin.py
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- services/auditoria.py
- test_horarios.py
- admin_data.dart
- _run_loop
- security.py
- salon_control_page.dart
- Análisis de dependencias y gestión de secretos
- admin_controllers.dart
- token_storage.dart
- services/asignaciones.py
- normalizar_correo
- 0001 - Estilo arquitectónico: Monolito Modular
- 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)
- ADR-0004: Seguridad y Autenticación — JWT Autofirmado
- ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios
- Estrategia de solución
- PrestamoSalon
- routers/asignaciones.py
- pubspec.yaml
- listar_usuarios
- dependencies
- listar_recursos
- salon_control_controller.dart
- test_rol_por_correo.py
- salones_admin_controller.dart
- conftest.py
- control_test.dart
- cuenta_page.dart
- salones_admin_data.dart
- demo_mensajeria.py
- foto_perfil_sheet.dart
- sqlalchemy
- foto_perfil.dart
- salones_controller.dart
- uber_widgets.dart
- test_salones_admin.py
- perfil_foto_test.dart
- salones_repository.dart
- mantenimiento_data.dart
- test_correo_institucional.py
- Usuario
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- services/auth.py
- registrar_presencia
- salones_admin_repository.dart
- shell_page.dart
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- datetime
- fcm_registration.dart
- get_db
- asignaciones_test.dart
- test_resilience.py
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- enums.py
- String?
- routers/salones_admin.py
- prestamos_data.dart
- 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes
- 0020 - Foto de perfil: miniatura limpia en una tabla aparte
- Política y Modelo de Privacidad de Datos — UTB Tracker
- Conceptos transversales (Cross-cutting Concepts)
- 0019 - Solo correos institucionales y rol por asignación verificada
- seed
- ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)
- reporte_salon_sheet.dart
- resilience.py
- environment
- obtener
- Matriz de permisos — UTB Tracker (ADR-0018)
- schemas.py
- Arquitectura de Seguridad y Privacidad — UTB Tracker
- web
- leer_cuerpo_limitado
- test_correo_verificado.py
- 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes
- schemas/perfil.py
- CircuitBreaker
- Introducción y objetivos
- 4. Tabla de Amenazas Priorizadas (P × I)
- Contexto y alcance
- respuesta
- Escenarios de calidad
- Registro
- test_concurrencia_prestamos_mismo_recurso_postgresql
- db
- Identidad visual de UTB Tracker
- require_role
- AdminRepository
- x-backend
- politica.dart
- 0012 - Empaquetar el sistema en contenedores con Docker Compose
- healthcheck
- escala_test.dart
- verificar_correo_endpoint
- mensajeria/README.md
- prestamos_repository.dart
- registrar
- test_identidad.py
- test_persistencia_cuentas.py
- correo.py
- logging_middleware
- 0016 - Perfil personalizable y preferencias guardadas en el servidor
- Correo real y worker en el servidor oficial (ADR-0015)

## God Nodes (most connected - your core abstractions)
1. `Usuario` - 96 edges
2. `get_db()` - 96 edges
3. `registrar()` - 52 edges
4. `MensajeOutbox` - 41 edges
5. `4. Tabla de Amenazas Priorizadas (P × I)` - 32 edges
6. `Salon` - 29 edges
7. `procesar_pendientes()` - 27 edges
8. `Recurso` - 26 edges
9. `NotificadorSimulado` - 25 edges
10. `normalizar_correo()` - 24 edges

## Surprising Connections (you probably didn't know these)
- `1. Solo correos institucionales en correos NUEVOS` --references--> `error_correo_nuevo()`  [INFERRED]
  docs/adr/0019-correo-institucional-y-rol-por-asignacion.md → app/core/politica.py
- `3. Metodología de Verificación en el Repositorio` --references--> `get_user_endpoint()`  [INFERRED]
  docs/datos/README.md → app/routers/auth.py
- `3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios` --references--> `UserResponse`  [INFERRED]
  docs/seguridad/privacidad.md → app/schemas/auth.py
- `Contexto` --references--> `create_user()`  [INFERRED]
  docs/adr/0014-autenticacion-correo-verificado-y-tokens-por-id.md → app/services/auth.py
- `Brecha B-04: Registro de Nombres de Usuario Duplicados` --references--> `login()`  [INFERRED]
  docs/datos/consistencia-por-operacion.md → app/services/auth.py

## Import Cycles
- None detected.

## Communities (198 total, 36 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.18
Nodes (11): Despliegue reproducible con Docker Compose (ADR-0012), Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Escenario 4 — Solicitud de salón por rol (ADR-0018), Escenario 5 — Registro institucional y rol por asignación (ADR-0019), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1 (+3 more)

### Community 1 - "StatelessWidget"
Cohesion: 0.04
Nodes (45): AvatarPerfil, _AvisoCorreoAntiguo, _Cabecera, _Chip, _Fila, _ModoPrueba, _RolSoloLectura, _Seccion (+37 more)

### Community 2 - "Recurso"
Cohesion: 0.18
Nodes (11): cuenta y correo (ADR-0014, ADR-0015, ADR-0016), Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, roles y permisos (ADR-0018), salones: tipo y equipamiento (ADR-0017) (+3 more)

### Community 3 - "../core/theme/app_theme.dart"
Cohesion: 0.05
Nodes (30): _auth, build, createState, initState, UtbTrackerApp, AuthController, auth, clave (+22 more)

### Community 4 - "with"
Cohesion: 0.06
Nodes (36): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+28 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.13
Nodes (12): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, 1. Resumen Ejecutivo (5 Líneas) (+4 more)

### Community 6 - "Salon"
Cohesion: 0.06
Nodes (24): IdempotenciaRegistro, Prestamo, Recurso, Reporte, Horario, PresenciaSalon, Salon, resumen() (+16 more)

### Community 7 - "UTB Tracker"
Cohesion: 0.12
Nodes (16): API pública, Arquitectura del proyecto, Backend: monolito modular y capas, Desarrollo local, Despliegue, Despliegue y Acceso Público, Ejecutar con Docker (ADR-0012), Estado actual (+8 more)

### Community 8 - "worker.py"
Cohesion: 0.16
Nodes (16): NotificacionProcesada, _aplicar_preferencias(), _calcular_siguiente_intento(), _construir_notificacion(), _descartar_duplicado(), _enviar_notificacion(), _leer_payload(), _marcar_enviado() (+8 more)

### Community 9 - "Horario"
Cohesion: 0.07
Nodes (18): actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate, HorarioCreate (+10 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.15
Nodes (5): Decisiones arquitectónicas, Restricciones arquitectónicas, Riesgos y deudas técnicas, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "stats_data.dart"
Cohesion: 0.15
Nodes (12): _api, DashboardStats, equiposDisponibles, fromJson, _int, prestamosActivos, reportesAbiertos, resumen (+4 more)

### Community 13 - "auth_controller_test.dart"
Cohesion: 0.06
Nodes (29): AuthRepositoryImpl, AuthRepository, actualizarRolUsuario, _AuthFalso, crear, falloRegistro, iniciarSesion, listarUsuarios (+21 more)

### Community 14 - "preferencias.dart"
Cohesion: 0.11
Nodes (16): aJson, api, aviso, avisos, CanalAviso, CategoriaAviso, conAviso, conPantallaInicio (+8 more)

### Community 15 - "figuras.dart"
Cohesion: 0.12
Nodes (14): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+6 more)

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.04
Nodes (49): _abrirAgregarHorario, _abrirSolicitudPrestamo, _AgregarHorarioSheet, _AgregarHorarioSheetState, _auth, build, _cambiarDia, _cancelarSolicitud (+41 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.11
Nodes (18): MensajeOutbox, NotificadorSimulado, procesar_pendientes(), _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker(), test_idempotencia_http_con_x_idempotency_key(), test_mensaje_muerto_al_superar_max_intentos() (+10 more)

### Community 23 - "control_page.dart"
Cohesion: 0.08
Nodes (23): _auth, build, _cambiar, _colorSolicitud, _contenido, _control, ControlPage, _ControlPageState (+15 more)

### Community 24 - "crear_recurso_page.dart"
Cohesion: 0.06
Nodes (29): build, _categoria, CrearRecursoPage, _CrearRecursoPageState, createState, dispose, _error, _form (+21 more)

### Community 25 - "Diseño de Estrategia de Caché e Invalidación — UTB Tracker"
Cohesion: 0.11
Nodes (18): 1.1 Regla Central de Oro (Aislamiento de Invariantes), 1.2 Endpoints Incluidos en Caché, 1.3 Endpoints Excluidos de Caché, 1. Alcance y Reglas de Integridad, 2.1 En Proceso vs. Redis Distribuido, 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia, 2. Topología de Caché y Decisión de Ubicación, 3.1 Formato Canónico de Claves (+10 more)

### Community 26 - "app_theme.dart"
Cohesion: 0.07
Nodes (25): AppColors, AppTheme, borde, build, child, danado, degradado, disponible (+17 more)

### Community 27 - "home_page.dart"
Cohesion: 0.05
Nodes (32): _auth, _bandeja, build, codigo, color, createState, _cuerpoAuxiliar, _cuerpoUsuario (+24 more)

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
Cohesion: 0.05
Nodes (34): AuditoriaPage, _AuditoriaPageState, build, _c, _color, createState, _cuerpo, initState (+26 more)

### Community 34 - "json"
Cohesion: 0.17
Nodes (18): _auditoria(), _login(), _salon_con_clase(), test_confirmar_presencia_deja_quien_cuando_y_que(), test_crud_de_salones_y_horarios_se_audita(), test_el_auxiliar_no_ve_la_bitacora(), test_el_cambio_de_rol_registra_quien_lo_hizo(), test_exportar_csv_trae_encabezado_y_filas() (+10 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.09
Nodes (23): _auth, _AvisoEstado, build, createState, _Dato, _descCtrl, dispose, _enviando (+15 more)

### Community 36 - "typing"
Cohesion: 0.08
Nodes (7): MantenimientoRecurso, AuditoriaResponse, CambioRol, _ahora(), actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 37 - "routers/auth.py"
Cohesion: 0.16
Nodes (12): CambiarCorreoRequest, FcmTokenRequest, ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest, TokenResponse, UserMeResponse, UserResponse (+4 more)

### Community 38 - "routers/salones.py"
Cohesion: 0.09
Nodes (14): actualizar_salon(), crear_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon(), TipoSalon, EquipoCategoria (+6 more)

### Community 39 - "salones_page.dart"
Cohesion: 0.04
Nodes (51): _abrirCrearSalon, _abrirSolicitud, _auth, _busquedaCtrl, _capacidadCtrl, _construirCuerpo, _CrearSalonSheet, _CrearSalonSheetState (+43 more)

### Community 40 - "test_auth.py"
Cohesion: 0.08
Nodes (9): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_login_exitoso_genera_jwt(), test_registro_fuerza_rol_usuario_utb() (+1 more)

### Community 41 - "escala.dart"
Cohesion: 0.14
Nodes (9): build, child, Escala, EscalaGlobal, factor, factorTexto, interfaz, tamanoTexto (+1 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.14
Nodes (5): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_vencidos(), marcar_vencidos_job()

### Community 43 - "with"
Cohesion: 0.09
Nodes (21): defaults, runs-on, steps, run, jobs, build, name, permissions (+13 more)

### Community 44 - "auth_controller.dart"
Cohesion: 0.04
Nodes (44): actualizarPerfil, _adoptarTokens, _api, autenticado, _aviso, cambiarPassword, cambiarServidor, _cargando (+36 more)

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
Nodes (26): _azar, baseUrl, _baseUrlFijo, _cabeceras, cerrar, _client, _conReintentos, delete (+18 more)

### Community 50 - "login_page.dart"
Cohesion: 0.05
Nodes (37): accion, _auth, autofill, ayuda, build, _CajaError, _cambiarModo, _CampoUber (+29 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.10
Nodes (19): actualizarEstadoPrestamo, actualizarTipoYDescripcion, _api, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, desdeJson (+11 more)

### Community 52 - "flutter_launcher_icons"
Cohesion: 0.17
Nodes (12): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, adaptive_icon_foreground_inset, android, image_path, ios, web (+4 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.08
Nodes (18): ApiException, _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado (+10 more)

### Community 54 - "injection.dart"
Cohesion: 0.06
Nodes (3): configurarDependencias, reset, sl

### Community 55 - "StatelessWidget"
Cohesion: 0.04
Nodes (41): accion, Aparecer, _AparecerState, build, _c, child, color, createState (+33 more)

### Community 56 - "registrar"
Cohesion: 0.27
Nodes (6): RegistroAuditoria, exportar_csv(), _filtrar(), listar(), registrar_y_confirmar(), _request_id()

### Community 57 - "asignaciones_page.dart"
Cohesion: 0.04
Nodes (52): _Raiz, _RaizState, asignacion, AsignacionesPage, _AsignacionesPageState, build, _c, _cargo (+44 more)

### Community 58 - "prestamos_controller.dart"
Cohesion: 0.07
Nodes (27): devuelto, estadoEn, EstadoPrestamo, fechaDevolucionEsperada, fechaDevolucionReal, fechaPrestamo, id, Prestamo (+19 more)

### Community 59 - "auth_domain.dart"
Cohesion: 0.05
Nodes (33): actualizarRolUsuario, cargo, colorAvatar, conFoto, correoInstitucional, dependencia, email, emailVerificado (+25 more)

### Community 60 - "PayloadPrestamoCreado"
Cohesion: 0.13
Nodes (15): EventoDominio, EventoPrestamoCreado, PayloadPrestamoCreado, PayloadPrestamoDevuelto, PayloadRecursoReportado, 1. Identificación del Evento, 2.1 Campos del Sobre (`EventoPrestamoCreado`), 2.2 Campos del Payload (`PayloadPrestamoCreado`) (+7 more)

### Community 61 - "control_controller.dart"
Cohesion: 0.12
Nodes (12): _accion, cambiarSolicitud, _carga, cargar, _error, pendientes, _repo, _reportes (+4 more)

### Community 62 - "listar_prestamos_salon"
Cohesion: 0.11
Nodes (6): actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon(), expirar_prestamos_pendientes(), listar_prestamos_salon(), obtener_prestamo_salon()

### Community 63 - "test_foto_perfil.py"
Cohesion: 0.10
Nodes (31): FotoPerfil, _app1_solo_orientacion(), ImagenInvalida, ImagenLimpia, limpiar(), _limpiar_jpeg(), _limpiar_png(), _orientacion_exif() (+23 more)

### Community 64 - "Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02"
Cohesion: 0.10
Nodes (19): 1. Escenarios de Calidad Evaluados (arc42 Sección 10), 2.1 Scripts Utilizados, 2.2 Endpoints Medidos, 2.3 Requisitos para Reproducir, 2.4 Comandos de Reproducción, 2. Método de Medición, 3. Entorno de Ejecución, 4.1 Resumen Tabular (+11 more)

### Community 65 - "test_perfil.py"
Cohesion: 0.18
Nodes (15): publicar_evento(), Trazabilidad, _acciones(), _entregar(), _plantillas(), _sesion(), test_cambiar_password_cierra_las_demas_sesiones(), test_cambio_de_correo_solo_al_abrir_el_enlace_y_avisa_al_anterior() (+7 more)

### Community 66 - "Modelado de Amenazas y Plan de Mitigación — UTB Tracker"
Cohesion: 0.12
Nodes (15): 1.1 ¿Qué estamos construyendo?, 1.2 ¿Qué puede salir mal?, 1.3 ¿Qué hacemos al respecto?, 1.4 ¿Hicimos un buen trabajo?, 1. Las Cuatro Preguntas del Modelado de Amenazas, 2.1 Catálogo de Activos, 2.2 Fronteras de Confianza (Trust Boundaries), 2.3 Diagrama de Fronteras de Confianza (Mermaid) (+7 more)

### Community 67 - "services/salones_admin.py"
Cohesion: 0.19
Nodes (15): ReporteSalon, _a_utc_naive(), actualizar_estado_reporte(), _ahora_campus(), _clase_en_curso(), crear_reporte(), listar_ocupacion(), listar_reportes() (+7 more)

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.04
Nodes (41): _abrir, activo, _actualizado, _auth, _Aviso, build, _c, _Cabecera (+33 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "admin_data.dart"
Cohesion: 0.05
Nodes (43): activo, actualizadas, _api, aplicado, asignaciones, AsignacionRol, cambiarEstado, cambiarRol (+35 more)

### Community 73 - "_run_loop"
Cohesion: 0.08
Nodes (13): crear_notificador(), crear_notificador_push(), NotificadorBase, NotificadorConPush, NotificadorFCM, NotificadorSMTP, _run_loop(), 1. Simplificaciones Asumidas en el Diseño (+5 more)

### Community 74 - "security.py"
Cohesion: 0.12
Nodes (17): get_current_user(), sesion_vigente(), usuario_de_sujeto(), crear_token_proposito(), create_access_token(), create_refresh_token(), create_reset_password_token(), leer_access_token() (+9 more)

### Community 76 - "salon_control_page.dart"
Cohesion: 0.06
Nodes (29): acciones, autor, build, _c, cantidad, _colorDeSolicitud, _confirmar, createState (+21 more)

### Community 77 - "Análisis de dependencias y gestión de secretos"
Cohesion: 0.33
Nodes (6): Alcance, Análisis de dependencias y gestión de secretos, Auditoría en CI, Pruebas y base de datos, Secretos y correo, Verificación de despliegue

### Community 78 - "admin_controllers.dart"
Cohesion: 0.05
Nodes (35): EstadisticasAdmin, AsignacionesController, buscar, _busqueda, _cambiar, cambiarEstado, cambiarRol, _carga (+27 more)

### Community 79 - "token_storage.dart"
Cohesion: 0.13
Nodes (11): borrarToken, _clave, _claveRefresh, _claveServidor, guardarServidor, guardarTokens, leerRefresh, leerServidor (+3 more)

### Community 80 - "services/asignaciones.py"
Cohesion: 0.13
Nodes (23): AsignacionRol, _a_http(), analizar_lista(), buscar(), _cargo(), correo_comprobado(), _correo_valido(), crear() (+15 more)

### Community 81 - "normalizar_correo"
Cohesion: 0.11
Nodes (16): correo_valido(), dominio_de(), error_correo_nuevo(), error_password(), es_institucional(), normalizar_correo(), normalizar_nombre(), _correo() (+8 more)

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

### Community 89 - "PrestamoSalon"
Cohesion: 0.11
Nodes (13): PrestamoSalon, PrestamoSalonCreate, PrestamoSalonResponse, PrestamoSalonUpdate, actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon(), _detectar_conflicto_horario() (+5 more)

### Community 90 - "routers/asignaciones.py"
Cohesion: 0.12
Nodes (11): crear_asignacion(), editar_asignacion(), eliminar_asignacion(), importar_asignaciones(), listar_asignaciones(), AsignacionCrear, AsignacionEditar, AsignacionRespuesta (+3 more)

### Community 92 - "pubspec.yaml"
Cohesion: 0.08
Nodes (24): color, icon_background_color, image, description, dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_native_splash (+16 more)

### Community 93 - "listar_usuarios"
Cohesion: 0.11
Nodes (8): respuesta_foto(), cambiar_estado(), cambiar_rol(), foto_de_usuario(), listar_usuarios(), rol_automatico(), CambioEstado, UsuarioAdmin

### Community 94 - "dependencies"
Cohesion: 0.20
Nodes (10): dependencies, firebase_core, firebase_messaging, flutter, flutter_secure_storage, flutter_svg, get_it, http (+2 more)

### Community 102 - "listar_recursos"
Cohesion: 0.07
Nodes (17): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), listar_reportes_recurso(), obtener_recurso(), reportar_recurso(), RecursoCreate (+9 more)

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.08
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "test_rol_por_correo.py"
Cohesion: 0.19
Nodes (24): _acciones(), _asignar(), _login(), _me(), _registrar(), test_analizar_lista_unidad(), test_asignacion_solo_con_correo_institucional_y_rol_valido(), test_busqueda_de_asignaciones() (+16 more)

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.08
Nodes (22): _busqueda, _carga, cargar, _coincide, _conEquipo, contar, _error, etiqueta (+14 more)

### Community 106 - "conftest.py"
Cohesion: 0.10
Nodes (8): hash_password(), test_health_check(), admin_headers(), auth_headers(), client(), db_session(), _get_token(), nombres()

### Community 107 - "control_test.dart"
Cohesion: 0.06
Nodes (24): cambiarEstadoSolicitud, cambios, _json, listarTodasLasSolicitudes, listarTodosLosReportes, main, pidioReportes, _reporte (+16 more)

### Community 108 - "cuenta_page.dart"
Cohesion: 0.05
Nodes (35): _abrir, _auth, build, _cambiarPassword, child, color, colorDeHex, coloresAvatar (+27 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.10
Nodes (17): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+9 more)

### Community 110 - "demo_mensajeria.py"
Cohesion: 0.13
Nodes (9): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_prestamos_vencidos(), _obtener_recurso_con_bloqueo(), _resolver_correlation_id(), _verificar_idempotencia(), main() (+1 more)

### Community 111 - "foto_perfil_sheet.dart"
Cohesion: 0.08
Nodes (24): _auth, build, calidadFoto, camara, createState, elegir, elegirConImagePicker, ElegirImagen (+16 more)

### Community 112 - "sqlalchemy"
Cohesion: 0.07
Nodes (14): downgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade() (+6 more)

### Community 113 - "foto_perfil.dart"
Cohesion: 0.09
Nodes (20): _api, build, CacheFotos, createState, _descargar, didUpdateWidget, _foto, FotoOIniciales (+12 more)

### Community 114 - "salones_controller.dart"
Cohesion: 0.11
Nodes (15): Carga, actualizarTipoYDescripcion, agregarHorario, _busqueda, cancelarPrestamoSalon, _carga, cargar, crear (+7 more)

### Community 115 - "uber_widgets.dart"
Cohesion: 0.12
Nodes (15): AsaHoja, AvatarIniciales, BotonPildora, build, cargando, color, compacto, estilo (+7 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.09
Nodes (27): RecursoOut, 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad (+19 more)

### Community 117 - "perfil_foto_test.dart"
Cohesion: 0.09
Nodes (18): _abrirHoja, configurarDependencias, json, main, _perfil, _peticiones, _pintar, _png (+10 more)

### Community 118 - "salones_repository.dart"
Cohesion: 0.13
Nodes (13): SalonesRepositoryImpl, actualizarEstadoPrestamo, actualizarTipoYDescripcion, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, listarHorarios (+5 more)

### Community 119 - "mantenimiento_data.dart"
Cohesion: 0.06
Nodes (29): ApiClient, actualizar, _api, descripcion, estado, fechaProgramada, fromJson, id (+21 more)

### Community 120 - "test_correo_institucional.py"
Cohesion: 0.16
Nodes (15): leer_dominios(), _cuenta_antigua(), _mensajes(), _registrar(), test_cambio_de_correo_a_no_institucional_rechazado(), test_correos_institucionales_validos(), test_cuenta_antigua_no_institucional_sigue_entrando_y_ve_aviso(), test_cuenta_antigua_puede_pasarse_a_institucional() (+7 more)

### Community 121 - "Usuario"
Cohesion: 0.24
Nodes (12): Usuario, delete_user(), update_user_role(), administradores_activos(), cambiar_estado(), cambiar_rol(), _es_admin_activo(), _invalidar_sesiones() (+4 more)

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "services/auth.py"
Cohesion: 0.10
Nodes (19): leer_token_proposito(), TokenUsado, abrir_enlace_correo(), _ahora(), aplicar_nueva_password(), _buscar_por_nombre(), consumir_token(), create_user() (+11 more)

### Community 124 - "registrar_presencia"
Cohesion: 0.18
Nodes (7): actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), listar_todos_los_reportes(), obtener_ocupacion(), registrar_presencia()

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.12
Nodes (15): SalonesAdminRepositoryImpl, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, listarTodasLasSolicitudes (+7 more)

### Community 126 - "shell_page.dart"
Cohesion: 0.11
Nodes (10): _BarraInferior, build, createState, _indice, _ir, _irSalones, _items, onTap (+2 more)

### Community 127 - "time"
Cohesion: 0.16
Nodes (6): ejecutar_corrida(), ejecutar_peticion(), main(), obtener_token(), percentil(), test_rendimiento_latencia_p95_salud()

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.13
Nodes (14): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login acepta el NOMBRE o el CORREO + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Instalar la app en un celular Android (APK), 7. Pruebas (+6 more)

### Community 130 - "fcm_registration.dart"
Cohesion: 0.12
Nodes (10): FcmRegistration, FcmTokenRegistrar, _injected, _messaging, _registrar, start, stop, _tokenSubscription (+2 more)

### Community 131 - "get_db"
Cohesion: 0.12
Nodes (22): get_db(), actualizar_perfil_endpoint(), cambiar_correo_endpoint(), cambiar_password_endpoint(), cerrar_sesiones_endpoint(), delete_user_endpoint(), desactivar_cuenta_endpoint(), forgot_password_endpoint() (+14 more)

### Community 132 - "asignaciones_test.dart"
Cohesion: 0.12
Nodes (13): _admin, asignaciones, configurarDependencias, cuerpo, importaciones, importarAsignaciones, lista, main (+5 more)

### Community 133 - "test_resilience.py"
Cohesion: 0.16
Nodes (7): with_retry(), decorator(), wrapper(), _crear_recurso(), test_idempotencia_prestamo_con_misma_clave(), test_with_retry_exito_tras_fallo_transitorio(), test_with_retry_lanza_excepcion_al_superar_maximo()

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.12
Nodes (15): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+7 more)

### Community 135 - "enums.py"
Cohesion: 0.30
Nodes (10): CategoriaRecurso, DiaSemana, EstadoPrestamo, EstadoPrestamoSalon, EstadoRecurso, EstadoReporteSalon, EstadoSalon, RolUsuario (+2 more)

### Community 137 - "String?"
Cohesion: 0.09
Nodes (13): actualizar, _cargando, cargar, _error, _items, _remote, _cargando, cargar (+5 more)

### Community 141 - "routers/salones_admin.py"
Cohesion: 0.29
Nodes (8): ClaseActual, OcupacionSalon, PresenciaResponse, PresenciaUpdate, PrestamoActual, ReporteSalonCreate, ReporteSalonResponse, ReporteSalonUpdate

### Community 143 - "prestamos_data.dart"
Cohesion: 0.17
Nodes (8): _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource, _remoto

### Community 144 - "0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes"
Cohesion: 0.25
Nodes (7): 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad

### Community 145 - "0020 - Foto de perfil: miniatura limpia en una tabla aparte"
Cohesion: 0.18
Nodes (11): 0020 - Foto de perfil: miniatura limpia en una tabla aparte, 1. Dónde se guarda: tabla `fotos_perfil`, 2. Endpoints, 3. Validación en el servidor, sin paquetes nuevos (`app/services/imagenes.py`), 4. Privacidad y bitácora, 5. App, Consecuencias, Contexto (+3 more)

### Community 146 - "Política y Modelo de Privacidad de Datos — UTB Tracker"
Cohesion: 0.15
Nodes (13): 1. Marco Legal y Principios de Tratamiento, 2. Inventario Exhaustivo de Datos Personales en el Modelo de Datos, 3.1 Sobreexposición en `UserResponse` y Consulta de Usuarios, 3.2 Correo en Logs del Notificador Simulado, 3.3 Datos en Carga Útil del Outbox, 3.4 Campo `profesor` en Horarios Académicos, 3. Análisis de Minimización de Datos y Brechas Detectadas, 4. Hallazgos de Privacidad Ligados al Modelado de Amenazas (+5 more)

### Community 147 - "Conceptos transversales (Cross-cutting Concepts)"
Cohesion: 0.18
Nodes (11): 8.10 Arquitectura de Seguridad y Privacidad (S13), 8.1 Patrón de Capas y Control de Erosión Arquitectónica, 8.2 Seguridad, Hashing y Autenticación, 8.3 Observabilidad y Logging Estructurado, 8.4 Evaluación de Inteligencia Artificial Generativa en el Producto (req. 9.9), 8.5 Resiliencia, Timeouts y Reintentos (S11 — req. 11.1 y 11.2), 8.6 Idempotencia y Prevención de Condiciones de Carrera (S11 — req. 11.3 y R-02), 8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6) (+3 more)

### Community 148 - "0019 - Solo correos institucionales y rol por asignación verificada"
Cohesion: 0.22
Nodes (9): 0019 - Solo correos institucionales y rol por asignación verificada, 1. Solo correos institucionales en correos NUEVOS, 2. El rol sale de una lista que mantiene el administrador, y solo con el correo comprobado, 3. Lista inicial en producción, sin datos reales en el repositorio, Consecuencias, Contexto, Decisión, Estado (+1 more)

### Community 149 - "seed"
Cohesion: 0.11
Nodes (19): condition, api, name, build, command, depends_on, profiles, restart (+11 more)

### Community 150 - "ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)"
Cohesion: 0.29
Nodes (7): ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR), Alternativas Evaluadas, Consecuencias, Contexto, Decisión, Estado, Fecha

### Community 151 - "reporte_salon_sheet.dart"
Cohesion: 0.08
Nodes (21): build, createState, _descripcion, dispose, _enviando, _enviar, _error, mostrarReporteSalonSheet (+13 more)

### Community 153 - "environment"
Cohesion: 0.32
Nodes (21): environment, CORREOS_DIR, CORS_ORIGINS, DATABASE_URL, DOMINIOS_PERMITIDOS, EMAIL_TOKEN_SECRET_KEY, ENVIRONMENT, FORGET_PWD_SECRET_KEY (+13 more)

### Community 154 - "obtener"
Cohesion: 0.40
Nodes (3): borrar_contenido(), obtener(), quitar()

### Community 155 - "Matriz de permisos — UTB Tracker (ADR-0018)"
Cohesion: 0.33
Nodes (5): Compatibilidad con las APK instaladas, Endpoints, Matriz de permisos — UTB Tracker (ADR-0018), Permisos por rol, Roles

### Community 156 - "schemas.py"
Cohesion: 0.13
Nodes (10): actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos(), MantenimientoRecursoCreate, MantenimientoRecursoOut, MantenimientoRecursoUpdate, PaginatedResponse, PrestamoCreate (+2 more)

### Community 157 - "Arquitectura de Seguridad y Privacidad — UTB Tracker"
Cohesion: 0.40
Nodes (5): 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Arquitectura de Seguridad y Privacidad — UTB Tracker

### Community 158 - "web"
Cohesion: 0.25
Nodes (8): API_BASE_URL, args, context, web, build, depends_on, ports, restart

### Community 160 - "test_correo_verificado.py"
Cohesion: 0.16
Nodes (27): Trazabilidad, 4. Tabla de Amenazas Priorizadas (P × I), _acciones(), _correos(), _entregar(), _login(), _registrar(), test_alerta_si_entra_tras_varios_fallos() (+19 more)

### Community 161 - "0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes"
Cohesion: 0.33
Nodes (6): 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 162 - "schemas/perfil.py"
Cohesion: 0.12
Nodes (9): CambiarPasswordRequest, Canal, FotoEstado, Notificaciones, PasswordRequest, PerfilResponse, PerfilUpdate, Preferencias (+1 more)

### Community 163 - "CircuitBreaker"
Cohesion: 0.18
Nodes (4): CircuitBreaker, wrapper(), CircuitBreakerOpenException, test_circuit_breaker_transiciones_de_estado()

### Community 164 - "Introducción y objetivos"
Cohesion: 0.50
Nodes (4): Descripción general de los requisitos, Introducción y objetivos, Objetivos de calidad, Stakeholders

### Community 165 - "4. Tabla de Amenazas Priorizadas (P × I)"
Cohesion: 0.29
Nodes (5): _crear_recurso(), test_devolver_prestamo(), test_devolver_prestamo_ya_devuelto_rechaza(), test_no_permite_prestar_recurso_no_disponible(), test_prestamo_exitoso_cambia_estado_del_recurso()

### Community 166 - "Contexto y alcance"
Cohesion: 0.67
Nodes (3): Contexto de negocio, Contexto técnico, Contexto y alcance

### Community 168 - "Escenarios de calidad"
Cohesion: 0.17
Nodes (10): Descripción general de los requisitos de calidad, Escenarios de calidad, QS-01 — Disponibilidad, QS-02 — Rendimiento (tiempo de respuesta), QS-03 — Rendimiento (concurrencia), QS-04 — Seguridad, QS-05 — Usabilidad, QS-06 — Confiabilidad de los datos (+2 more)

### Community 169 - "Registro"
Cohesion: 0.50
Nodes (3): Formato, Registro, Uso de IA - Tractar

### Community 171 - "db"
Cohesion: 0.25
Nodes (8): environment, image, restart, volumes, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, db

### Community 172 - "Identidad visual de UTB Tracker"
Cohesion: 0.29
Nodes (6): Colores, Dónde se aplica, Identidad visual de UTB Tracker, Lenguaje visual (ADR-0011), Símbolo, Tono

### Community 174 - "AdminRepository"
Cohesion: 0.67
Nodes (3): AdminRepository, AdminRepositoryImpl, _RepoFalso

### Community 176 - "x-backend"
Cohesion: 0.15
Nodes (13): build, depends_on, ports, restart, volumes, condition, db, api (+5 more)

### Community 185 - "politica.dart"
Cohesion: 0.04
Nodes (34): ApiConfig, baseUrl, describir, _elegido, elegir, esOficial, _override, permiteCambiarServidor (+26 more)

### Community 196 - "0012 - Empaquetar el sistema en contenedores con Docker Compose"
Cohesion: 0.29
Nodes (6): 0012 - Empaquetar el sistema en contenedores con Docker Compose, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 197 - "healthcheck"
Cohesion: 0.53
Nodes (6): healthcheck, healthcheck, interval, retries, test, timeout

### Community 199 - "escala_test.dart"
Cohesion: 0.07
Nodes (18): configurarDependencias, main, _peticiones, _preparar, _servidor, configurarDependencias, _json, main (+10 more)

### Community 200 - "verificar_correo_endpoint"
Cohesion: 0.18
Nodes (8): _html(), restablecer_pagina_endpoint(), verificar_correo_endpoint(), correo_cambiado(), correo_verificado(), enlace_invalido(), formulario_restablecer(), _pagina()

### Community 203 - "mensajeria/README.md"
Cohesion: 0.11
Nodes (16): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller), 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas) (+8 more)

### Community 205 - "prestamos_repository.dart"
Cohesion: 0.25
Nodes (6): PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository, _PrestamosFalso

### Community 209 - "registrar"
Cohesion: 0.09
Nodes (24): verify_password(), IntentoLimitado, registrar(), login(), guardar(), _ahora(), anotar(), contar() (+16 more)

### Community 212 - "test_identidad.py"
Cohesion: 0.12
Nodes (20): require_verified(), 0014 - Autenticación con correo verificado, identidad normalizada y tokens por id, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad (+12 more)

### Community 213 - "test_persistencia_cuentas.py"
Cohesion: 0.25
Nodes (4): _apagar(), _levantar(), _puerto_libre(), test_cuenta_registrada_sobrevive_al_reinicio_de_la_api()

### Community 214 - "correo.py"
Cohesion: 0.06
Nodes (37): _construir(), crear_proveedor(), enviar(), Proveedor, ProveedorDesarrollo, ProveedorSMTP, bienvenida(), _boton() (+29 more)

### Community 215 - "logging_middleware"
Cohesion: 0.07
Nodes (19): logging_middleware(), _mensaje_422(), validacion_en_espanol(), health_check(), A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar (+11 more)

### Community 221 - "0016 - Perfil personalizable y preferencias guardadas en el servidor"
Cohesion: 0.33
Nodes (6): 0016 - Perfil personalizable y preferencias guardadas en el servidor, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 222 - "Correo real y worker en el servidor oficial (ADR-0015)"
Cohesion: 0.33
Nodes (5): 1. Variables nuevas en el `.env` del servidor, 2. Proveedor de correo recomendado, 3. Servicio systemd del worker, 4. Comprobar, Correo real y worker en el servidor oficial (ADR-0015)

## Knowledge Gaps
- **1313 isolated node(s):** `sl`, `configurarDependencias`, `reset`, `_client`, `_baseUrlFijo` (+1308 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2434 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **36 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Usuario` connect `Usuario` to `Salon`, `worker.py`, `arc42.md`, `obtener`, `test_correo_verificado.py`, `typing`, `respuesta`, `require_role`, `registrar`, `test_foto_perfil.py`, `services/salones_admin.py`, `security.py`, `services/asignaciones.py`, `registrar`, `normalizar_correo`, `test_identidad.py`, `test_rol_por_correo.py`, `conftest.py`, `demo_mensajeria.py`, `test_correo_institucional.py`, `services/auth.py`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Are the 65 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 65 INFERRED edges - model-reasoned connections that need verification._
- **What connects `sl`, `configurarDependencias`, `reset` to the rest of the system?**
  _1313 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `StatelessWidget` be split into smaller, more focused modules?**
  _Cohesion score 0.04155844155844156 - nodes in this community are weakly interconnected._
- **Why does `get_db()` connect `get_db` to `typing`, `services/auditoria.py`, `listar_recursos`, `verificar_correo_endpoint`, `Horario`, `security.py`, `listar_prestamos`, `routers/salones.py`, `routers/salones_admin.py`, `Salon`, `conftest.py`, `registrar_presencia`, `test_messaging.py`, `logging_middleware`, `routers/asignaciones.py`, `schemas.py`, `listar_usuarios`, `listar_prestamos_salon`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Should `../core/theme/app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.047895500725689405 - nodes in this community are weakly interconnected._
# Graph Report - AS_202620_UTB_TRACKER  (2026-11-14)

## Corpus Check
- 226 files · ~128,718 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 16 file(s) not represented in the graph (top: (none) 10, .example 1, .properties 1)

## Summary
- 3450 nodes · 6151 edges · 183 communities (154 shown, 29 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 269 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `09aa44c8`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Runtime View
- ../core/theme/app_theme.dart
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
- datetime
- routers/auth.py
- actualizar_salon
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
- schemas.py
- prestamos_controller.dart
- auth_domain.dart
- PayloadPrestamoCreado
- control_controller.dart
- listar_prestamos_salon
- listar_salones
- Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02
- test_perfil.py
- Modelado de Amenazas y Plan de Mitigación — UTB Tracker
- services/salones_admin.py
- ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos
- panel_salones_page.dart
- services/auditoria.py
- test_horarios.py
- recursos_data.dart
- _run_loop
- security.py
- salon_control_page.dart
- Análisis de dependencias y gestión de secretos
- recursos_repository.dart
- token_storage.dart
- services/salones_admin.py
- api_exception.dart
- 0001 - Estilo arquitectónico: Monolito Modular
- 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)
- ADR-0004: Seguridad y Autenticación — JWT Autofirmado
- ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios
- Estrategia de solución
- update_user_role_endpoint
- Evidencia: la prueba de contrato falla ante un cambio incompatible
- listar_recursos
- pubspec.yaml
- flutter_native_splash
- dependencies
- services/resources.py
- salon_control_controller.dart
- SalonesAdminRepository
- salones_admin_controller.dart
- test_main.py
- control_test.dart
- cuenta_page.dart
- salones_admin_data.dart
- dev_dependencies
- _TransicionSuave
- sqlalchemy
- SalonesRepository
- salones_controller.dart
- package:flutter/material.dart
- test_salones_admin.py
- json
- salones_repository.dart
- mantenimiento_data.dart
- ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias
- services/auth.py
- Estrategia de Datos y Eventos — UTB Tracker
- salones_admin_repository.dart
- time
- Cómo ejecutar UTB Tracker en Windows (PowerShell)
- fcm_registration.dart
- get_db
- services/resources.py
- 3. Garantías del Flujo por Eventos (Transactional Outbox)
- admin_usuarios_controller.dart
- 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes
- Política y Modelo de Privacidad de Datos — UTB Tracker
- test_worker_reintenta_si_el_proveedor_falla
- seed
- ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)
- reporte_salon_sheet.dart
- schemas.py
- environment
- 1. Salidas Crudas de Comandos
- worker
- actualizar_mantenimiento
- web
- test_correo_verificado.py
- 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes
- schemas/perfil.py
- test_resilience.py
- Introducción y objetivos
- 4. Tabla de Amenazas Priorizadas (P × I)
- Contexto y alcance
- Escenarios de calidad
- _AgregarHorarioSheet
- SalonDetallePage
- db
- Identidad visual de UTB Tracker
- _SolicitarPrestamoSalonSheet
- x-backend
- NotificadorBase
- api_config.dart
- 0012 - Empaquetar el sistema en contenedores con Docker Compose
- healthcheck
- escala_test.dart
- verificar_correo_endpoint
- Cómo Ejecutar en PowerShell (Comandos Reales)
- prestamos_repository.dart
- tipo_salon_campos.dart
- 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos
- login
- plantillas_correo.py
- politica.dart
- test_identidad.py
- test_persistencia_cuentas.py
- ProveedorDesarrollo
- logging_middleware
- 0016 - Perfil personalizable y preferencias guardadas en el servidor
- Correo real y worker en el servidor oficial (ADR-0015)
- 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción

## God Nodes (most connected - your core abstractions)
1. `get_db()` - 80 edges
2. `Usuario` - 58 edges
3. `registrar()` - 43 edges
4. `MensajeOutbox` - 40 edges
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

## Communities (183 total, 29 thin omitted)

### Community 0 - "Runtime View"
Cohesion: 0.22
Nodes (9): Despliegue reproducible con Docker Compose (ADR-0012), Escenario 1 — Préstamo exitoso, Escenario 2 — Préstamo rechazado (recurso no disponible), Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker), Estimación de costos mensuales (S8 — req. 8.10), Infrastructure Level 1, Infrastructure Level 2, Runtime View (+1 more)

### Community 1 - "../core/theme/app_theme.dart"
Cohesion: 0.15
Nodes (7): build, _Chip, compacto, e, equipamiento, EquipamientoChips, nombreCategoria

### Community 2 - "Recurso"
Cohesion: 0.20
Nodes (10): cuenta y correo (ADR-0014, ADR-0015, ADR-0016), Estructura del sistema, Level 3, Nivel 2, prestamos, recursos, salones: tipo y equipamiento (ADR-0017), Vista general del sistema (+2 more)

### Community 3 - "../core/theme/app_theme.dart"
Cohesion: 0.05
Nodes (25): AuditoriaController, build, _c, _color, createState, _cuerpo, initState, AvisoVerificacion (+17 more)

### Community 4 - "with"
Cohesion: 0.06
Nodes (36): needs, runs-on, steps, DATABASE_URL, POSTGRES_DB, POSTGRES_HOST_AUTH_METHOD, POSTGRES_USER, TEST_DATABASE_URL (+28 more)

### Community 5 - "0003 - Estrategia de integración: síncrona (REST sobre HTTP)"
Cohesion: 0.33
Nodes (6): 0003 - Estrategia de integración: síncrona (REST sobre HTTP), Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 6 - "Salon"
Cohesion: 0.05
Nodes (26): hash_password(), IdempotenciaRegistro, Prestamo, Recurso, Reporte, PrestamoSalon, Salon, resumen() (+18 more)

### Community 7 - "UTB Tracker"
Cohesion: 0.12
Nodes (16): API pública, Arquitectura del proyecto, Backend: monolito modular y capas, Desarrollo local, Despliegue, Despliegue y Acceso Público, Ejecutar con Docker (ADR-0012), Estado actual (+8 more)

### Community 8 - "worker.py"
Cohesion: 0.17
Nodes (15): _aplicar_preferencias(), _calcular_siguiente_intento(), _construir_notificacion(), _descartar_duplicado(), _enviar_notificacion(), _leer_payload(), _marcar_enviado(), _marcar_muerto() (+7 more)

### Community 9 - "Horario"
Cohesion: 0.08
Nodes (19): Horario, actualizar_horario(), crear_horario(), crear_horarios_bulk(), eliminar_horario(), listar_horarios(), obtener_horario(), HorarioBulkCreate (+11 more)

### Community 10 - "Ficha del problema — UTB Tracker"
Cohesion: 0.29
Nodes (6): A quién afecta, Alcance de esta entrega, Ficha del problema — UTB Tracker, Por qué importa ahora, Problema, Qué se propone

### Community 11 - "arc42.md"
Cohesion: 0.15
Nodes (5): Decisiones arquitectónicas, Restricciones arquitectónicas, Diagrama de Contenedores (C4 - Nivel 2) - UTB Tracker, Conclusión, Matriz comparativa de estilos arquitectónicos — UTB Tracker

### Community 12 - "stats_data.dart"
Cohesion: 0.09
Nodes (17): _api, DashboardStats, equiposDisponibles, fromJson, _int, prestamosActivos, reportesAbiertos, resumen (+9 more)

### Community 13 - "auth_controller_test.dart"
Cohesion: 0.07
Nodes (27): FcmRegistration, actualizarRolUsuario, crear, falloRegistro, _FcmFalso, iniciarSesion, listarUsuarios, main (+19 more)

### Community 14 - "preferencias.dart"
Cohesion: 0.11
Nodes (16): aJson, api, aviso, avisos, CanalAviso, CategoriaAviso, conAviso, conPantallaInicio (+8 more)

### Community 15 - "figuras.dart"
Cohesion: 0.13
Nodes (14): aireAc, audio, _base, computador, Figuras, logo, mantenimiento, otros (+6 more)

### Community 17 - "salon_detalle_page.dart"
Cohesion: 0.04
Nodes (43): _abrirAgregarHorario, _abrirSolicitudPrestamo, _auth, build, _cambiarDia, _cancelarSolicitud, _cargandoDatos, _cargarTodo (+35 more)

### Community 18 - "test_messaging.py"
Cohesion: 0.09
Nodes (20): MensajeOutbox, NotificacionProcesada, NotificadorSimulado, procesar_pendientes(), main(), _crear_recurso(), test_consumidor_idempotente_ante_reentrega(), test_desacoplamiento_temporal_sin_worker() (+12 more)

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
Cohesion: 0.04
Nodes (44): AdminUsuariosController, AuthController, ControlController, _auth, build, codigo, _CodigoSalon, color (+36 more)

### Community 28 - "test_salones_tipo_equipamiento.py"
Cohesion: 0.09
Nodes (21): 0017 - Tipo de salón y equipamiento calculado desde los recursos, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad, admin_headers() (+13 more)

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
Nodes (42): _cuerpoAuxiliar, _cuerpoUsuario, _auth, build, _buscar, _CabeceraSalon, _ChipsActivos, codigo (+34 more)

### Community 34 - "json"
Cohesion: 0.26
Nodes (14): _auditoria(), _login(), _salon_con_clase(), test_confirmar_presencia_deja_quien_cuando_y_que(), test_crud_de_salones_y_horarios_se_audita(), test_el_auxiliar_no_ve_la_bitacora(), test_el_cambio_de_rol_registra_quien_lo_hizo(), test_exportar_csv_trae_encabezado_y_filas() (+6 more)

### Community 35 - "recurso_detalle_page.dart"
Cohesion: 0.06
Nodes (33): _abrirCambiarRol, _auth, build, _busquedaCtrl, _controller, createState, dispose, initState (+25 more)

### Community 36 - "datetime"
Cohesion: 0.06
Nodes (15): require_role(), publicar_evento(), AuditoriaResponse, PrestamoSalonCreate, PrestamoSalonResponse, PrestamoSalonUpdate, EquipoCategoria, FranjaDisponible (+7 more)

### Community 37 - "routers/auth.py"
Cohesion: 0.17
Nodes (13): CambiarCorreoRequest, FcmTokenRequest, ForgotPasswordRequest, RefreshTokenRequest, ResetPasswordRequest, TokenResponse, UserMeResponse, UserResponse (+5 more)

### Community 38 - "actualizar_salon"
Cohesion: 0.23
Nodes (3): actualizar_salon(), crear_salon(), eliminar_salon()

### Community 39 - "salones_page.dart"
Cohesion: 0.05
Nodes (42): AuditoriaPage, _AuditoriaPageState, EquiposPage, _EquiposPageState, _abrirCrearSalon, _abrirSolicitud, _auth, _busquedaCtrl (+34 more)

### Community 40 - "test_auth.py"
Cohesion: 0.09
Nodes (7): test_admin_actualizar_rol_usuario(), test_admin_listar_usuarios(), test_eliminar_usuario_sin_rol_admin(), test_endpoint_me(), test_endpoint_me_sin_token(), test_endpoint_protegido_sin_token(), test_registro_fuerza_rol_usuario_utb()

### Community 41 - "escala.dart"
Cohesion: 0.08
Nodes (16): _auth, build, createState, initState, _Raiz, _RaizState, UtbTrackerApp, build (+8 more)

### Community 42 - "listar_prestamos"
Cohesion: 0.08
Nodes (12): crear_prestamo(), devolver_prestamo(), listar_prestamos(), marcar_vencidos(), marcar_vencidos_job(), PrestamoCreate, crear_prestamo(), listar_prestamos() (+4 more)

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
Cohesion: 0.07
Nodes (27): actualizarRolUsuario, _api, AuthRemoteDataSource, AuthRepositoryImpl, desdeJson, _identificar, iniciarSesion, _intentarUsuario (+19 more)

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
Nodes (39): auth, clave, correo, enviado, form, mostrarCambiarCorreo, accion, _auth (+31 more)

### Community 51 - "salones_data.dart"
Cohesion: 0.06
Nodes (28): ApiClient, _api, crear, desdeJson, devolver, listar, PrestamoModel, PrestamosRemoteDataSource (+20 more)

### Community 52 - "flutter_launcher_icons"
Cohesion: 0.17
Nodes (12): flutter_launcher_icons, adaptive_icon_background, adaptive_icon_foreground, adaptive_icon_foreground_inset, android, image_path, ios, web (+4 more)

### Community 53 - "api_client_test.dart"
Cohesion: 0.13
Nodes (7): _json, main, _json, main, _json, main, main

### Community 54 - "injection.dart"
Cohesion: 0.07
Nodes (3): configurarDependencias, reset, sl

### Community 55 - "StatelessWidget"
Cohesion: 0.03
Nodes (71): _CajaError, _CampoUber, _Marca, _Cabecera, _Chip, _Seccion, _Titulo, accion (+63 more)

### Community 56 - "registrar"
Cohesion: 0.19
Nodes (8): _prohibir_actualizar(), _prohibir_borrar(), RegistroAuditoria, exportar_csv(), _filtrar(), listar(), registrar_y_confirmar(), _request_id()

### Community 57 - "schemas.py"
Cohesion: 0.24
Nodes (8): MantenimientoRecurso, MantenimientoRecursoCreate, MantenimientoRecursoUpdate, ReporteCreate, actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos(), reportar_recurso()

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
Cohesion: 0.11
Nodes (6): actualizar_estado_prestamo_salon(), cancelar_prestamo_propio(), crear_prestamo_salon(), expirar_prestamos_pendientes(), listar_prestamos_salon(), obtener_prestamo_salon()

### Community 63 - "listar_salones"
Cohesion: 0.24
Nodes (3): listar_salones(), obtener_disponibilidad(), obtener_salon()

### Community 64 - "Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02"
Cohesion: 0.10
Nodes (19): 1. Escenarios de Calidad Evaluados (arc42 Sección 10), 2.1 Scripts Utilizados, 2.2 Endpoints Medidos, 2.3 Requisitos para Reproducir, 2.4 Comandos de Reproducción, 2. Método de Medición, 3. Entorno de Ejecución, 4.1 Resumen Tabular (+11 more)

### Community 65 - "test_perfil.py"
Cohesion: 0.17
Nodes (15): Trazabilidad, _acciones(), buzon(), _entregar(), _plantillas(), _sesion(), test_cambiar_password_cierra_las_demas_sesiones(), test_cambio_de_correo_solo_al_abrir_el_enlace_y_avisa_al_anterior() (+7 more)

### Community 66 - "Modelado de Amenazas y Plan de Mitigación — UTB Tracker"
Cohesion: 0.12
Nodes (15): 1.1 ¿Qué estamos construyendo?, 1.2 ¿Qué puede salir mal?, 1.3 ¿Qué hacemos al respecto?, 1.4 ¿Hicimos un buen trabajo?, 1. Las Cuatro Preguntas del Modelado de Amenazas, 2.1 Catálogo de Activos, 2.2 Fronteras de Confianza (Trust Boundaries), 2.3 Diagrama de Fronteras de Confianza (Mermaid) (+7 more)

### Community 67 - "services/salones_admin.py"
Cohesion: 0.06
Nodes (44): PresenciaSalon, ReporteSalon, actualizar_reporte(), crear_reporte(), listar_ocupacion(), listar_reportes(), listar_todos_los_reportes(), obtener_ocupacion() (+36 more)

### Community 68 - "ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos"
Cohesion: 0.18
Nodes (11): ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos, Alternativas Evaluadas, Conclusión basada en la Evidencia, Consecuencias, Contexto, Decisión, Estado, Fecha (+3 more)

### Community 69 - "panel_salones_page.dart"
Cohesion: 0.06
Nodes (30): _abrir, activo, _actualizado, _auth, _Aviso, build, _c, _Cabecera (+22 more)

### Community 71 - "test_horarios.py"
Cohesion: 0.31
Nodes (8): _crear_salon(), test_carga_masiva_horarios(), test_conflicto_horario_rechazado(), test_crear_horario(), test_disponibilidad_con_horarios(), test_eliminar_horario(), test_horario_mismo_dia_sin_cruce_acepta(), test_listar_horarios_filtrados()

### Community 72 - "recursos_data.dart"
Cohesion: 0.17
Nodes (9): _api, crear, desdeJson, listar, obtener, RecursoModel, RecursosRemoteDataSource, _remoto (+1 more)

### Community 73 - "_run_loop"
Cohesion: 0.12
Nodes (7): crear_notificador(), crear_notificador_push(), NotificadorConPush, NotificadorFCM, NotificadorSMTP, _run_loop(), Patrones de diseño utilizados

### Community 74 - "security.py"
Cohesion: 0.11
Nodes (16): get_current_user(), require_verified(), usuario_de_sujeto(), crear_token_proposito(), create_access_token(), create_refresh_token(), create_reset_password_token(), leer_access_token() (+8 more)

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
Cohesion: 0.16
Nodes (8): adjuntar(), calcular(), actualizar_salon(), eliminar_salon(), listar_salones(), obtener_disponibilidad(), obtener_salon(), obtener_salon_con_equipamiento()

### Community 81 - "api_exception.dart"
Cohesion: 0.17
Nodes (11): ApiException, _detalle, esDeRed, fromResponse, mensaje, sinConexion, statusCode, tiempoAgotado (+3 more)

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

### Community 88 - "update_user_role_endpoint"
Cohesion: 0.20
Nodes (3): delete_user_endpoint(), get_users_endpoint(), update_user_role_endpoint()

### Community 89 - "Evidencia: la prueba de contrato falla ante un cambio incompatible"
Cohesion: 0.40
Nodes (4): Con el cambio incompatible presente, Después de revertir el cambio, Evidencia: la prueba de contrato falla ante un cambio incompatible, Por qué esto demuestra que la prueba cumple su función

### Community 90 - "listar_recursos"
Cohesion: 0.24
Nodes (3): listar_recursos(), listar_reportes_recurso(), obtener_recurso()

### Community 92 - "pubspec.yaml"
Cohesion: 0.20
Nodes (9): description, environment, sdk, flutter, assets, uses-material-design, name, publish_to (+1 more)

### Community 93 - "flutter_native_splash"
Cohesion: 0.22
Nodes (9): color, icon_background_color, image, flutter_native_splash, android_12, color, image, ios (+1 more)

### Community 94 - "dependencies"
Cohesion: 0.22
Nodes (9): dependencies, firebase_core, firebase_messaging, flutter, flutter_secure_storage, flutter_svg, get_it, http (+1 more)

### Community 102 - "services/resources.py"
Cohesion: 0.21
Nodes (4): actualizar_recurso(), crear_recurso(), eliminar_recurso(), reportar_recurso()

### Community 103 - "salon_control_controller.dart"
Cohesion: 0.09
Nodes (21): _accion, _auth, _carga, cargar, confirmarProfesor, decidirSolicitud, _error, _fallar (+13 more)

### Community 104 - "SalonesAdminRepository"
Cohesion: 0.47
Nodes (5): SalonesAdminRepositoryImpl, SalonesAdminRepository, _RepoFalso, _RepoFalso, _RepoFalso

### Community 105 - "salones_admin_controller.dart"
Cohesion: 0.08
Nodes (22): _busqueda, _carga, cargar, _coincide, _conEquipo, contar, _error, etiqueta (+14 more)

### Community 107 - "control_test.dart"
Cohesion: 0.06
Nodes (24): cambiarEstadoSolicitud, cambios, _json, listarTodasLasSolicitudes, listarTodosLosReportes, main, pidioReportes, _reporte (+16 more)

### Community 108 - "cuenta_page.dart"
Cohesion: 0.06
Nodes (33): _abrir, _auth, build, _cambiarPassword, child, color, colorDeHex, coloresAvatar (+25 more)

### Community 109 - "salones_admin_data.dart"
Cohesion: 0.10
Nodes (17): _api, cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, desdeJson, listarOcupacion, listarReportes, listarSolicitudes (+9 more)

### Community 110 - "dev_dependencies"
Cohesion: 0.33
Nodes (6): dev_dependencies, flutter_launcher_icons, flutter_lints, flutter_native_splash, flutter_test, sdk

### Community 112 - "sqlalchemy"
Cohesion: 0.09
Nodes (12): downgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade(), upgrade() (+4 more)

### Community 114 - "salones_controller.dart"
Cohesion: 0.11
Nodes (15): Carga, actualizarTipoYDescripcion, agregarHorario, _busqueda, cancelarPrestamoSalon, _carga, cargar, crear (+7 more)

### Community 115 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (35): _Baldosa, build, _CuadriculaPainter, ocupacion, onTap, paint, PlanoSalones, _porEdificio (+27 more)

### Community 116 - "test_salones_admin.py"
Cohesion: 0.17
Nodes (16): Trazabilidad, _salon_con_clase(), test_confirmar_presencia_se_refleja_en_la_ocupacion(), test_cualquier_usuario_puede_reportar_y_solo_el_auxiliar_resuelve(), test_listar_ocupacion_incluye_todos_los_salones(), test_presencia_requiere_rol_administrador(), test_presencia_se_puede_corregir_sin_duplicar(), test_presencia_sin_clase_en_curso_da_409() (+8 more)

### Community 117 - "json"
Cohesion: 0.38
Nodes (4): _cargar_contrato_congelado(), _resolver_ref(), test_campos_requeridos_de_los_schemas_no_desaparecieron(), test_todos_los_paths_del_contrato_siguen_existiendo()

### Community 118 - "salones_repository.dart"
Cohesion: 0.15
Nodes (11): actualizarEstadoPrestamo, actualizarTipoYDescripcion, cancelarPrestamoSalon, consultarDisponibilidad, crearHorario, crearSalon, listarHorarios, listarPrestamosSalon (+3 more)

### Community 119 - "mantenimiento_data.dart"
Cohesion: 0.09
Nodes (19): actualizar, _api, descripcion, estado, fechaProgramada, fromJson, id, listar (+11 more)

### Community 122 - "ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias"
Cohesion: 0.18
Nodes (11): ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias, Alternativas Evaluadas, Comparativa de Costo de Reversión frente a otras decisiones de datos, Consecuencias, Contexto, Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa), Decisión, Estado (+3 more)

### Community 123 - "services/auth.py"
Cohesion: 0.06
Nodes (44): sesion_vigente(), verify_password(), correo_valido(), error_password(), normalizar_correo(), normalizar_nombre(), Usuario, TokenUsado (+36 more)

### Community 124 - "Estrategia de Datos y Eventos — UTB Tracker"
Cohesion: 0.40
Nodes (5): 1. Resumen Ejecutivo (5 Líneas), 2. Índice de Documentos, 3. Metodología de Verificación en el Repositorio, 4. Enlace al Commit, Estrategia de Datos y Eventos — UTB Tracker

### Community 125 - "salones_admin_repository.dart"
Cohesion: 0.15
Nodes (10): cambiarEstadoReporte, cambiarEstadoSolicitud, crearReporte, listarOcupacion, listarReportes, listarSolicitudes, listarTodasLasSolicitudes, listarTodosLosReportes (+2 more)

### Community 127 - "time"
Cohesion: 0.12
Nodes (7): ejecutar_corrida(), ejecutar_peticion(), main(), obtener_token(), percentil(), test_concurrencia_prestamos_mismo_recurso_postgresql(), test_rendimiento_latencia_p95_salud()

### Community 128 - "Cómo ejecutar UTB Tracker en Windows (PowerShell)"
Cohesion: 0.13
Nodes (14): 0. Requisitos (una sola vez), 1. Preparar el backend (una sola vez), 2. Terminal 1 — Backend, 3. Terminal 2 — App Flutter, 4. Cuentas de ejemplo (el login acepta el NOMBRE o el CORREO + clave), 5. Datos de ejemplo que crea `scripts/seed_demo.py`, 6. Instalar la app en un celular Android (APK), 7. Pruebas (+6 more)

### Community 130 - "fcm_registration.dart"
Cohesion: 0.14
Nodes (7): FcmTokenRegistrar, _injected, _messaging, _registrar, start, stop, _tokenSubscription

### Community 131 - "get_db"
Cohesion: 0.20
Nodes (15): get_db(), actualizar_perfil_endpoint(), cambiar_correo_endpoint(), cambiar_password_endpoint(), cerrar_sesiones_endpoint(), desactivar_cuenta_endpoint(), forgot_password_endpoint(), get_user_endpoint() (+7 more)

### Community 133 - "services/resources.py"
Cohesion: 0.24
Nodes (5): actualizar_recurso(), crear_recurso(), eliminar_recurso(), listar_recursos(), obtener_recurso()

### Community 134 - "3. Garantías del Flujo por Eventos (Transactional Outbox)"
Cohesion: 0.13
Nodes (15): 1. Niveles de Consistencia y Definiciones, 2. Matriz de Operaciones y Garantías de Consistencia, 3.1 Entrega (At-Least-Once), 3.2 Duplicados, 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN, 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`, 3.5 Despliegue del Worker en el Entorno Real, 3. Garantías del Flujo por Eventos (Transactional Outbox) (+7 more)

### Community 137 - "admin_usuarios_controller.dart"
Cohesion: 0.10
Nodes (14): _busqueda, cambiarRol, _cargando, cargar, _error, fijarBusqueda, fijarFiltroRol, _filtroRol (+6 more)

### Community 144 - "0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes"
Cohesion: 0.25
Nodes (7): 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad

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
Cohesion: 0.14
Nodes (12): build, createState, _descripcion, dispose, _enviando, _enviar, _error, mostrarReporteSalonSheet (+4 more)

### Community 152 - "schemas.py"
Cohesion: 0.18
Nodes (8): MantenimientoRecursoOut, PaginatedResponse, PrestamoDevolver, PrestamoOut, RecursoCreate, RecursoOut, ReporteResponse, Decisión

### Community 153 - "environment"
Cohesion: 0.34
Nodes (20): environment, CORREOS_DIR, CORS_ORIGINS, DATABASE_URL, EMAIL_TOKEN_SECRET_KEY, ENVIRONMENT, FORGET_PWD_SECRET_KEY, SECRET_KEY (+12 more)

### Community 154 - "1. Salidas Crudas de Comandos"
Cohesion: 0.25
Nodes (7): 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`), 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`), 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`), 1.4 Resumen de la Suite Completa del Repositorio, 1. Salidas Crudas de Comandos, 2. Matriz de Cumplimiento de Puntos del Taller, Evidencia de Ejecución: Mensajería Asíncrona (Taller)

### Community 155 - "worker"
Cohesion: 0.22
Nodes (9): condition, api, depends_on, worker, build, command, depends_on, restart (+1 more)

### Community 156 - "actualizar_mantenimiento"
Cohesion: 0.27
Nodes (3): actualizar_mantenimiento(), crear_mantenimiento(), listar_mantenimientos()

### Community 158 - "web"
Cohesion: 0.25
Nodes (8): API_BASE_URL, args, context, web, build, depends_on, ports, restart

### Community 160 - "test_correo_verificado.py"
Cohesion: 0.27
Nodes (19): _acciones(), _correos(), _entregar(), _login(), _registrar(), test_alerta_si_entra_tras_varios_fallos(), test_cuenta_sin_verificar_entra_y_consulta_pero_no_solicita_salones(), test_el_log_del_worker_no_incluye_el_token() (+11 more)

### Community 161 - "0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes"
Cohesion: 0.33
Nodes (6): 0009 - Administración de salones: ocupación en vivo, presencia del profesor y reportes, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 162 - "schemas/perfil.py"
Cohesion: 0.15
Nodes (7): Canal, Notificaciones, PasswordRequest, PerfilResponse, PerfilUpdate, Preferencias, SesionRenovada

### Community 163 - "test_resilience.py"
Cohesion: 0.05
Nodes (26): CircuitBreaker, wrapper(), CircuitBreakerOpenException, CircuitBreakerState, with_retry(), decorator(), wrapper(), 8.10 Arquitectura de Seguridad y Privacidad (S13) (+18 more)

### Community 164 - "Introducción y objetivos"
Cohesion: 0.50
Nodes (4): Descripción general de los requisitos, Introducción y objetivos, Objetivos de calidad, Stakeholders

### Community 165 - "4. Tabla de Amenazas Priorizadas (P × I)"
Cohesion: 0.15
Nodes (11): 4. Tabla de Amenazas Priorizadas (P × I), test_login_exitoso_genera_jwt(), test_registro_usuario_exitoso(), test_limite_de_login_se_guarda_en_la_base(), test_produccion_arranca_solo_con_las_claves_anteriores(), test_recuperacion_con_limite_de_frecuencia(), _crear_recurso(), test_devolver_prestamo() (+3 more)

### Community 166 - "Contexto y alcance"
Cohesion: 0.67
Nodes (3): Contexto de negocio, Contexto técnico, Contexto y alcance

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

### Community 178 - "NotificadorBase"
Cohesion: 0.20
Nodes (6): NotificadorBase, 1. Simplificaciones Asumidas en el Diseño, 2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial, 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa, 4. Requisitos para Transición a Producción, Límites del Experimento: Mensajería Asíncrona

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

### Community 203 - "Cómo Ejecutar en PowerShell (Comandos Reales)"
Cohesion: 0.22
Nodes (9): 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas), 2. Ejecutar la suite de pruebas de contrato congelado, 3. Ejecutar la demostración interactiva de punta a punta (con base temporal aislada), 4. Ejecutar el worker de polling en modo standalone, Cómo Ejecutar en PowerShell (Comandos Reales), Descripción de la Solución en una Frase, Enlace al Commit, Módulo de Mensajería Asíncrona (Transactional Outbox) (+1 more)

### Community 205 - "prestamos_repository.dart"
Cohesion: 0.25
Nodes (6): PrestamosRepositoryImpl, crear, devolver, listar, PrestamosRepository, _PrestamosFalso

### Community 207 - "tipo_salon_campos.dart"
Cohesion: 0.12
Nodes (15): build, CamposTipoSalon, createState, descripcion, dispose, _EditarTipoSheet, _EditarTipoSheetState, _error (+7 more)

### Community 208 - "0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos"
Cohesion: 0.33
Nodes (5): 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos, Alternativas consideradas, Consecuencias, Contexto, Estado

### Community 209 - "login"
Cohesion: 0.18
Nodes (9): IntentoLimitado, login(), _ahora(), anotar(), contar(), exigir(), limpiar(), purgar_viejos() (+1 more)

### Community 210 - "plantillas_correo.py"
Cohesion: 0.41
Nodes (13): bienvenida(), _boton(), cambio_correo_aviso(), cambio_correo_nuevo(), cambio_password(), _codigo(), _e(), _enlace_seguro() (+5 more)

### Community 211 - "politica.dart"
Cohesion: 0.13
Nodes (11): _correo, correoValido, errorPassword, msgCorreoInvalido, msgPasswordCorta, msgPasswordIgualCorreo, msgPasswordIgualNombre, normalizarCorreo (+3 more)

### Community 212 - "test_identidad.py"
Cohesion: 0.14
Nodes (19): 0014 - Autenticación con correo verificado, identidad normalizada y tokens por id, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado, Trazabilidad, _mensajes() (+11 more)

### Community 213 - "test_persistencia_cuentas.py"
Cohesion: 0.25
Nodes (4): _apagar(), _levantar(), _puerto_libre(), test_cuenta_registrada_sobrevive_al_reinicio_de_la_api()

### Community 214 - "ProveedorDesarrollo"
Cohesion: 0.10
Nodes (15): crear_proveedor(), enviar(), Proveedor, ProveedorDesarrollo, ProveedorSMTP, 0015 - Servicio de correo con plantillas y entrega por el outbox, Alternativas consideradas, Consecuencias (+7 more)

### Community 215 - "logging_middleware"
Cohesion: 0.08
Nodes (17): logging_middleware(), _mensaje_422(), validacion_en_espanol(), health_check(), A-01 · Declarar, A-02 · Declarar, A-03 · Declarar, A-04 · Declarar (+9 more)

### Community 221 - "0016 - Perfil personalizable y preferencias guardadas en el servidor"
Cohesion: 0.33
Nodes (6): 0016 - Perfil personalizable y preferencias guardadas en el servidor, Alternativas consideradas, Consecuencias, Contexto, Decisión, Estado

### Community 222 - "Correo real y worker en el servidor oficial (ADR-0015)"
Cohesion: 0.33
Nodes (5): 1. Variables nuevas en el `.env` del servidor, 2. Proveedor de correo recomendado, 3. Servicio systemd del worker, 4. Comprobar, Correo real y worker en el servidor oficial (ADR-0015)

### Community 223 - "0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción"
Cohesion: 0.40
Nodes (5): 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción, Alternativas consideradas, Consecuencias, Contexto, Estado

## Knowledge Gaps
- **1118 isolated node(s):** `_auth`, `build`, `createState`, `initState`, `Figuras` (+1113 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2109 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **29 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `get_db()` connect `get_db` to `Salon`, `Horario`, `test_messaging.py`, `test_salones_tipo_equipamiento.py`, `actualizar_mantenimiento`, `datetime`, `routers/auth.py`, `actualizar_salon`, `listar_prestamos`, `listar_prestamos_salon`, `listar_salones`, `services/salones_admin.py`, `services/auditoria.py`, `verificar_correo_endpoint`, `security.py`, `logging_middleware`, `update_user_role_endpoint`, `listar_recursos`, `services/resources.py`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `get_db()` (e.g. with `db_session()` and `test_rollback_real_forzando_fallo_en_commit()`) actually correct?**
  _`get_db()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_auth`, `build`, `createState` to the rest of the system?**
  _1118 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `../core/theme/app_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.054878048780487805 - nodes in this community are weakly interconnected._
- **Why does `Riesgos y deudas técnicas` connect `Salon` to `services/auth.py`, `arc42.md`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 37 inferred relationships involving `Usuario` (e.g. with `get_current_user()` and `require_role()`) actually correct?**
  _`Usuario` has 37 INFERRED edges - model-reasoned connections that need verification._
- **Should `with` be split into smaller, more focused modules?**
  _Cohesion score 0.05855855855855856 - nodes in this community are weakly interconnected._
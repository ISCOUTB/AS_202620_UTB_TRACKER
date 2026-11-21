---
date: July 2025
title: "![arc42](images/arc42-logo.png) Template"
---

# 

**About arc42**

arc42, the template for documentation of software and system
architecture.

Template Version 9.0-EN. (based upon AsciiDoc version), July 2025

Created, maintained and © by Dr. Peter Hruschka, Dr. Gernot Starke and
contributors. See <https://arc42.org>.

# Introducción y objetivos

## Descripción general de los requisitos

UTB Tracker es un sistema movil dirigido a los auxiliares de planta de la UTB. Este sistema ayudara a mantener un registro de los objetos electronicos de cada salon de la universidad como video beams, computadores, aires acondicionados, etc. Esto para saber el estado actual de los aparatos, su ubicación y funcionalidad.

Este sistema busca ayudar a los auxiliares de planta y de laboratorio a la hora de que se presten aparatos a profesores o estudiantes como video beams asi manteniendo un registro de a quien se presto y a que salon fue llevado cada aparato. Ademas mantiene un registro de la funcionalidad de los aparatos de cada salon para saber si por ejemplo el computador numero 24 del salon A1-304 esta dañado y se debe someter a mantenimiento.

Finalmente el sistema esta dirigido tanto a auxiliares de planta y laboratorio asi como a profesores y estudiantes interesados por prestar aparatos electronicos de los salones o de los laboratorios de la UTB.



## Objetivos de calidad

Los objetivos de calidad se derivaron directamente de los problemas que UTB Tracker busca resolver
(sección 2 del documento de idea) y de las reglas de negocio que dependen de que el sistema sea confiable.

| # | Objetivo de calidad | Motivación |
|---|---|---|
| 1 | **Confiabilidad de los datos** | El problema central que resuelve el sistema es la falta de un registro confiable del estado de cada recurso; si el estado (disponible/prestado/dañado) puede quedar inconsistente, el sistema no resuelve nada mejor que el proceso actual. |
| 2 | **Usabilidad** | El auxiliar de planta necesita registrar préstamos rápido, sin fricción, mientras atiende a varias personas; el estudiante/profesor necesita pedir un préstamo sin pasos innecesarios. |
| 3 | **Seguridad** | Hay dos roles con permisos distintos (administrador vs. usuario UTB); un usuario no debería poder alterar el catálogo ni el estado de recursos que no le corresponden. |
| 4 | **Disponibilidad** | El sistema debe estar accesible durante el horario en que opera el campus, que es cuando ocurren los préstamos y devoluciones. |
| 5 | **Rendimiento** | La app debe responder rápido en los momentos de mayor uso (por ejemplo, inicio de semestre, cuando muchos profesores piden equipos a la vez). |

Estos cinco objetivos son la base del árbol de utilidad (sección 10).

## Stakeholders

| Role/Name | Contact | Expectations |
|--------------|-----------------|---------------------|
| **Auxiliar de planta** | Trabajador de la UTB encargado de apoyar el mantenimiento, la operación y el cuidado de la infraestructura física o de los laboratorios y talleres del campus | Llevar el historial de prestamos y ubicación de cada objeto prestado y tambien la disponibilidad y el estado de los objetos de los salones y laboratorios |
| **Profesores/Estudiantes** | Personas interesadas en hacer un prestamo de algun objeto | Solicitar el prestamo mediante la aplicación y recibir una confirmación mediante esta misma |
| **Equipo de desarrollo** | Sebastián García, Gerónimo Cadena, Joriel Samir Barros, Mateo Milán | Construir un sistema mantenible dentro del tiempo del semestre |
| **Docente / evaluador** | Profesor del curso | Verificar que la arquitectura documentada corresponda con lo implementado en el repositorio |

# Restricciones arquitectónicas

Cada restricción se documenta con su justificación: de dónde sale y qué implica para el diseño.
No son preferencias del equipo, son condiciones que ya vienen dadas y que la arquitectura tiene
que respetar. Las decisiones tecnológicas que el equipo sí eligió (Flutter, FastAPI, PostgreSQL)
no van aquí — están justificadas en la sección "Solution Strategy" y en `docs/adr/0002-*.md`.

**Restricciones técnicas**

| Restricción | Origen | Implicación arquitectónica |
|---|---|---|
| Solo pueden usarse las librerías/herramientas dadas o aprobadas por el profesor | Condición del curso | Limita las opciones de frameworks; cada dependencia nueva se valida antes de adoptarla |
| El backend debe exponerse como API consumible por un cliente móvil separado | El cliente es una app Flutter, no una interfaz servida por el propio backend | Backend y cliente quedan desacoplados por un contrato HTTP/JSON; cualquier cambio de ese contrato afecta a los dos lados a la vez |
| Los cambios de esquema de base de datos deben quedar versionados | El equipo usa PostgreSQL con Alembic para migraciones | El modelo de datos no se modifica "a mano" en producción; cada cambio de esquema pasa por una migración registrada |

**Restricciones organizacionales**

| Restricción | Origen | Implicación arquitectónica |
|---|---|---|
| El proyecto debe estar terminado dentro del semestre académico | Calendario del curso | Favorece una arquitectura simple y modular sobre una solución sobre-diseñada |
| Equipo de 4 personas, todas simultáneamente estudiantes de otras materias | Composición real del equipo | La arquitectura debe permitir trabajo en paralelo sin choques constantes (separación clara de módulos/responsabilidades) |

**Restricciones legales / normativas**

| Restricción | Origen | Implicación arquitectónica |
|---|---|---|
| Cumplimiento de la Ley de Protección de Datos Personales (Ley 1581 de 2012, Colombia) | El sistema registra datos personales de usuarios (nombre, rol) y trazabilidad de sus préstamos | El acceso a los datos de un usuario debe restringirse según su rol (administrador vs. usuario UTB); las credenciales (JWT) deben manejarse de forma segura |

# Contexto y alcance

## Contexto de negocio

UTB Tracker se situa en un contexto donde los **auxiliares de planta** de la UTB no tienen una herramienta que les facilite el registro de prestamos de objetos electronicos y de laboratorio ademas de un sistema para saber el estado de estos mismos. De modo que nuestro sistema busca ayudarles en esta labor con una solucion digital 


| Comunicación | Descripción | Formato / canal |
|---|---|---|
| Auxiliar de planta → UTB Tracker | Registra prestamos de objetos, actualiza estado de los objetos, crea nuevos objetos, elimina objetos, gestiona usuarios | Interfaz movil, HTTPS |
| Estudiante/Profesor → UTB Tracker | Solicita prestamos de objetos, deja comentarios de los objetos | Interfaz movil, HTTPS |
| UTB Tracker → Correo electronico | Envía correos automáticos de confirmación al solicitar un préstamo, recordatorios de devolución de equipos atrasados a estudiantes/profesores, o notificaciones a auxiliares sobre reportes de daños. | SMTP / HTML |

No hay integración con sistemas externos de terceros (por ejemplo, pasarelas de pago o sistemas
de otras empresas): el alcance actual es interno entre estos dos roles y el propio sistema.

## Contexto técnico

El auxiliar de planta accede normalmente desde la app móvil, muchas veces con conexión intermitente en el campus; el estudiante o profesor accede desde dispositivos con mejor conectividad. Esta diferencia obliga a la aplicación móvil a tolerar fallas temporales de conexión.


**Diagrama de contexto (C4 Nivel 1)**

![Diagrama de contexto C4 Nivel 1 - Tractar](../c4/c4_nivel1.md)

*(Diagrama modelado utilizando la extension de *Mermaid* para VSCode. Muestra Auxiliar de planta y usuario UTB
como actores, UTB Tracker como sistema central, y un sistema externo: el sistema de correo electronico.)*

# Estrategia de solución

Esta sección resume las decisiones tecnológicas y de estilo que atraviesan todo el sistema, y
por qué se tomaron — el detalle completo de cada una vive en su propio ADR bajo `docs/adr/`.

## Decisiones tecnológicas

| Decisión | Motivación |
|---|---|
| Backend en FastAPI (Python) | Proporciona un desarrollo rápido, tipado estático con Pydantic para validación automática en los formularios (crucial para la usabilidad de QS-05) y documentación interactiva nativa (Swagger/OpenAPI). Se ejecuta mediante Uvicorn. |
| Persistencia en SQL (SQLAlchemy / Alembic) | Garantiza la integridad de las transacciones de préstamos mediante restricciones de clave foránea y transacciones ACID. Alembic maneja las migraciones de forma estructurada. |
| Arquitectura Monolítica Modular | Permite a los 4 desarrolladores trabajar en paralelo en sus propios módulos de dominio (`users`, `loans`, `resources`) bajo `app/routers/` reduciendo conflictos en Git y manteniendo fronteras claras. |

## Decisión de estilo arquitectónico

Se eligió **Monolito Modular**: un único desplegable dividido internamente en módulos de
dominio independientes (`users`, `loans`, `resources`).

La comparación completa contra los otros dos estilos evaluados (capas y hexagonal) está en
[`docs/matriz_estilos.md`](../matriz_estilos.md), y la decisión formal con alternativas
descartadas y consecuencias en
[`docs/adr/0001-estilo-arquitectonico.md`](../adr/0001-estilo-arquitectonico.md) (**ADR-0001**).

En resumen: se descartó *capas* porque el acoplamiento técnico dificulta que el equipo trabaje en paralelo, y se descartó *hexagonal* porque el exceso de indirección y andamiaje (puertos y adaptadores) consume demasiado tiempo valioso del semestre académico. El monolito modular en FastAPI ofrece el balance ideal entre límites claros de dominio y velocidad de desarrollo.

## Cómo se logran los objetivos de calidad principales

| Objetivo de calidad | Enfoque de solución |
|---|---|
| Disponibilidad / rendimiento (QS-01) | La asincronía nativa de FastAPI (utilizando endpoints `async def`) optimiza la concurrencia y los tiempos de respuesta del servidor frente a alta demanda en el campus. |
| Usabilidad (QS-05) | Al evitar indirección arquitectónica compleja, el equipo puede enfocarse en interfaces sencillas y en la validación automatizada en tiempo real que provee Pydantic. |
| Seguridad / Integridad (QS-03, QS-04) | Uso de dependencias de FastAPI (`Depends`) para inyectar políticas de autorización de forma limpia a nivel de router. Las contraseñas se almacenan cifradas con `bcrypt` (en lugar de texto plano). |
| Integridad de los Datos (QS-02) | Manejo de transacciones ACID nativas a través del ORM SQLAlchemy conectado a la base de datos SQL. |

# Estructura del sistema

## Vista general del sistema

**Diagrama**

```mermaid
    graph TB
    A[Recurso] --> B[Prestamo]
    B --> C[Usuario]
```

**Motivación**

Cada módulo bajo `app/routers/` corresponde a un módulo de dominio, siguiendo el estilo Monolito Modular (ADR-0001). La estructura de carpetas del repositorio (`app/routers/resources.py`, `app/routers/loans.py`, etc.) coincide 1 a 1 con los bloques del diagrama.

**Bloques contenidos**

| Bloque | Estado en esta entrega |
|---|---|
| `health` | Completo desde S3 — endpoint de verificación |
| `usuarios` | Módulo declarado, sin lógica de negocio todavía |
| `recursos` | **Corte vertical S4**: crear, listar y consultar recursos |
| `prestamos` | **Corte vertical S4**: crear préstamo, con regla de negocio central |

**Interfaces importantes**

Todos los módulos se comunican vía HTTP/JSON. Internamente, `prestamos` depende de `recursos` (consulta y modifica estado). La dependencia está declarada explícitamente en `app/routers/loans.py`.

### recursos

*Responsabilidad:* mantener el catálogo de equipos y su estado (disponible/prestado/dañado).
*Interfaz:* `POST /recursos`, `GET /recursos`, `GET /recursos/{id}`.
*Ubicación:* `app/routers/resources.py`, modelo en `app/models.py::Recurso`.
*Requisitos que cumple:* base para QS-06 (confiabilidad de datos).

### prestamos

*Responsabilidad:* registrar préstamos y aplicar la regla "un recurso solo puede prestarse si está disponible".
*Interfaz:* `POST /prestamos`, `GET /prestamos`.
*Ubicación:* `app/routers/loans.py`, modelo en `app/models.py::Prestamo`.
*Requisitos que cumple:* QS-06 (confiabilidad de datos) probado en `tests/test_loans.py`.

### cuenta y correo (ADR-0014, ADR-0015, ADR-0016)

*Responsabilidad:* identidad de las personas (registro con correo verificado, inicio de sesión por
usuario o correo, sesión con tokens por id y versión de sesión), perfil y preferencias guardadas
en el servidor, y todos los correos de la cuenta (verificación, recuperación, cambio de correo y
de contraseña, alertas).
*Interfaz:* `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`,
`GET /auth/verificar-correo`, `POST /auth/reenviar-verificacion`, `POST /auth/forgot-password`,
`POST /auth/reset-password`, `GET /auth/restablecer`, `GET|PATCH /auth/me`,
`POST /auth/me/cambiar-correo`, `POST /auth/me/cambiar-password`, `POST /auth/me/cerrar-sesiones`,
`POST /auth/me/desactivar`.
*Ubicación:* `app/routers/auth.py` → `app/services/auth.py`, `app/services/perfil.py`,
`app/services/correo.py` (+ `plantillas_correo.py`), `app/services/limites.py` →
`app/schemas/auth.py`, `app/schemas/perfil.py` → `app/models/auth_models.py`,
`app/models/seguridad_models.py`. Los correos salen por el outbox y el worker
(`app/messaging/worker.py::_procesar_correo`).
*Requisitos que cumple:* QS-04 (seguridad) — `tests/test_identidad.py`,
`tests/test_correo_verificado.py`, `tests/test_perfil.py`, `tests/test_persistencia_cuentas.py`.

### salones: tipo y equipamiento (ADR-0017)

*Responsabilidad:* tipo y descripción de cada salón y su equipamiento **calculado** desde los
recursos activos (una consulta agrupada para todos los salones), con sugerencia de tipo.
*Interfaz:* `GET /salones?tipo=&con_equipo=&busqueda=`, `GET /salones/{id}`,
`GET /salones/ocupacion` (campos `tipo`, `descripcion`, `equipamiento`, `tipo_sugerido`).
*Ubicación:* `app/services/equipamiento.py`, `app/services/salones.py`, `app/schemas/salones.py`.
*Requisitos que cumple:* QS-05 (usabilidad) y QS-02 (sin consultas N+1) —
`tests/test_salones_tipo_equipamiento.py`.

### roles y permisos (ADR-0018)

*Responsabilidad:* decidir qué puede hacer cada rol (Estudiante = `usuario_utb`, Auditor =
`auxiliar`, Administrador = `administrador`) con UNA tabla de permisos; gestión de usuarios y
roles por el administrador (con protección del último administrador), bandeja de solicitudes
del auditor y estadísticas del administrador. "Auditor" (rol) no es la bitácora de auditoría.
*Interfaz:* `GET /auth/me` (`rol_etiqueta`, `permisos`), `GET /usuarios`,
`PATCH /usuarios/{id}/rol|estado`, `GET /prestamos-salon/mias`, `GET /prestamos-salon/gestion`,
`POST /prestamos-salon/{id}/aprobar|rechazar`, `GET /stats/admin`.
*Ubicación:* `app/core/permisos.py` (tabla) → `app/core/deps.py` (`require_permiso` y alias por
permiso) → routers; `app/services/usuarios.py`, `app/services/prestamos_salon.py`,
`app/services/estadisticas.py`; en la app `frontend/lib/features/auth/domain/permisos.dart`,
`features/home/presentation/shell_page.dart` (pestañas por permisos), `features/solicitudes/`,
`features/admin/`, `shared/sin_acceso.dart`.
*Requisitos que cumple:* QS-04 (seguridad) — `tests/test_matriz_permisos.py` (cada endpoint ×
cada rol contra `docs/seguridad/matriz-permisos.md`), `tests/test_roles.py`,
`frontend/test/roles_test.dart`.

### cuenta institucional, rol por asignación y foto (ADR-0019, ADR-0020)

*Responsabilidad:* admitir solo correos institucionales en registros y cambios de correo
(`DOMINIOS_PERMITIDOS`, por defecto `utb.edu.co`, coincidencia exacta) sin bloquear cuentas
antiguas; decidir el rol con UNA función a partir de la lista `asignaciones_rol` que mantiene
el administrador, solo con el correo comprobado (un rol manual gana); guardar la foto de perfil
como miniatura limpia (sin EXIF/GPS) en una tabla aparte.
*Interfaz:* `GET /auth/me` (`correo_institucional`, `rol_origen`, `rol_origen_texto`, `cargo`,
`tiene_foto`, `foto_version`), `GET|POST /usuarios/asignaciones`,
`PATCH|DELETE /usuarios/asignaciones/{id}`, `POST /usuarios/asignaciones/importar`,
`POST /usuarios/{id}/rol/automatico`, `PUT|DELETE|GET /auth/me/foto`, `GET /usuarios/{id}/foto`.
*Ubicación:* `app/core/politica.py` (`error_correo_nuevo`), `app/core/config.py`,
`app/services/asignaciones.py` (`rol_resuelto`, `recalcular`, importación),
`app/services/fotos.py`, `app/services/imagenes.py` (firma, estructura y limpieza sin
librerías), `app/routers/asignaciones.py`, `app/routers/fotos.py`, `scripts/cargar_asignaciones.py`;
en la app `frontend/lib/core/utils/politica.dart`, `features/admin/presentation/asignaciones_page.dart`,
`features/cuenta/presentation/foto_perfil_sheet.dart`, `shared/foto_perfil.dart`.
*Requisitos que cumple:* QS-04 (seguridad) y privacidad — `tests/test_correo_institucional.py`,
`tests/test_rol_por_correo.py`, `tests/test_foto_perfil.py`,
`frontend/test/correo_institucional_test.dart`, `asignaciones_test.dart`, `perfil_foto_test.dart`.

### catálogo de salones UTB (ADR-0021)

*Responsabilidad:* aplicar en UN solo lugar la regla del código (`A` + edificio + `-` + piso +
salón: A1-101) con edificio y piso coincidentes; cargar el catálogo provisional desde un
archivo de datos sin borrar nunca; reportar los salones que no siguen la regla con una
propuesta; dejar crear, renombrar y desactivar solo al Administrador.
*Interfaz:* `POST /salones/catalogo/rango/vista-previa`, `POST /salones/catalogo/rango`,
`GET /salones/catalogo/fuera`, `POST|DELETE /salones` (ahora `salones.crear_catalogo`),
`GET /salones?edificio=&piso=`, campo `capacidad_estimada`.
*Ubicación:* `app/services/catalogo.py`, `app/routers/catalogo.py`, `app/schemas/catalogo.py`,
`scripts/datos/catalogo_utb.json`, `scripts/cargar_catalogo_utb.py`; en la app
`features/salones_admin/domain/catalogo.dart` (espejo de la regla) y
`features/salones_admin/presentation/catalogo_page.dart`.
*Requisitos que cumple:* QS-06 (confiabilidad de los datos) y QS-05 —
`tests/test_catalogo_salones.py`, `frontend/test/catalogo_test.dart`.

### habilitación, ocupación y equipos del salón (ADR-0022)

*Responsabilidad:* separar la HABILITACIÓN manual (con motivo obligatorio, nota y reapertura)
de la OCUPACIÓN calculada (clase u horario aprobado ahora); calcular `estado` para los
clientes de siempre; impedir solicitar o aprobar un salón deshabilitado y señalar y avisar las
solicitudes afectadas; llevar el historial legible del salón; cambiar el estado de los equipos
fijos (nunca "prestado") con sugerencia de reporte; aplicar plantillas con vista previa.
*Interfaz:* `PATCH /salones/{id}/habilitacion`, `GET /salones/{id}/historial`,
`POST /salones/habilitacion/lote[/vista-previa]`, `GET /salones/ocupacion/resumen`,
`GET /salones/exportar.csv`, `PATCH /recursos/{id}/estado`, `GET /recursos/plantillas`,
`POST /recursos/plantillas/{vista-previa|aplicar}`; campos `habilitado`, `aviso_deshabilitado`,
`ocupado_ahora` y `aviso_salon`.
*Ubicación:* `app/services/estado_salon.py`, `app/services/equipos.py`,
`app/services/exportar.py`, `app/routers/estado_salon.py`, `app/schemas/estado_salon.py`,
`app/schemas/equipos.py`, modelo `HistorialSalon`; en la app
`features/salones_admin/domain/disponibilidad.dart`, `data/disponibilidad_data.dart`,
`presentation/disponibilidad_secciones.dart`.
*Requisitos que cumple:* QS-06 (confiabilidad), QS-02 (sin N+1 en el panel) y QS-05 —
`tests/test_habilitacion_equipos.py`, `frontend/test/habilitacion_test.dart`.

## Nivel 2

### White Box *recursos*

router (resources.py) → schema (RecursoCreate / RecursoOut) → modelo (Recurso) → SQLite/PostgreSQL

El router valida la entrada con Pydantic, rechaza serial duplicado con 409 y devuelve salida validada.

### White Box *prestamos*

router (loans.py) → valida existencia y estado del Recurso → schema (PrestamoCreate/Out) → modelo (Prestamo) → SQLite/PostgreSQL → actualiza Recurso.estado a "prestado"

Antes de crear el préstamo, el router comprueba `recurso.estado == "disponible"`; si no, responde 409.

## Level 3

*(pendiente)*

# Runtime View

## Vista de ejecución

### Escenario 1 — Préstamo exitoso

Un auxiliar registra el préstamo de un recurso que está disponible.

```mermaid
sequenceDiagram
    actor Auxiliar
    participant API as UTB Tracker (FastAPI)
    participant DB as Base de datos
    
    Auxiliar->>API: POST /prestamos {recurso_id, usuario_id, fecha_devolucion_esperada}
    API->>DB: SELECT recurso WHERE id = recurso_id
    DB-->>API: recurso (estado = "disponible")
    API->>DB: INSERT prestamo
    API->>DB: UPDATE recurso SET estado = "prestado"
    DB-->>API: OK
    API-->>Auxiliar: 201 Created {prestamo}
```

**Aspectos notables:** la comprobación de disponibilidad y la actualización de estado ocurren en el mismo request.

### Escenario 2 — Préstamo rechazado (recurso no disponible)

Un segundo usuario intenta prestar el mismo recurso mientras ya está prestado.

```mermaid
sequenceDiagram
    actor Usuario2 as Segundo usuario
    participant API as UTB Tracker (FastAPI)
    participant DB as Base de datos
    
    Usuario2->>API: POST /prestamos {recurso_id, usuario_id, fecha_devolucion_esperada}
    API->>DB: SELECT recurso WHERE id = recurso_id
    DB-->>API: recurso (estado = "prestado")
    API-->>Usuario2: 409 Conflict {"detail": "El recurso no esta disponible..."}
    Note over API,DB: No se crea ningun registro de prestamo
```

**Aspectos notables:** este es el escenario de calidad QS-06, el sistema nunca permite dos préstamos activos sobre el mismo recurso.

### Escenario 3 — Notificación asíncrona de préstamo (Transactional Outbox + Worker)

Tras registrar exitosamente un préstamo, el sistema desacopla la notificación al usuario mediante el patrón Transactional Outbox para no comprometer la latencia ni la disponibilidad del endpoint ante caídas del servicio de correo ([ADR-0006](../adr/0006-mensajeria-asincrona-outbox.md)).

```mermaid
sequenceDiagram
    actor Auxiliar
    participant API as UTB Tracker (FastAPI)
    participant DB as PostgreSQL (ACID)
    participant Worker as Worker Outbox
    participant Mail as Notificador Externo

    Auxiliar->>API: POST /prestamos {recurso_id, usuario_id, fecha}
    Note over API,DB: Transacción ACID local única
    API->>DB: INSERT INTO prestamos
    API->>DB: UPDATE recursos SET estado = 'prestado'
    API->>DB: INSERT INTO mensajes_outbox (estado = 'pendiente')
    API->>DB: COMMIT
    API-->>Auxiliar: 201 Created {prestamo} (Respuesta inmediata)

    loop Polling cada 5s (WORKER_POLL_INTERVAL)
        Worker->>DB: SELECT * FROM mensajes_outbox WHERE estado = 'pendiente' AND siguiente_intento <= NOW()
        DB-->>Worker: [mensaje]
        Worker->>DB: SELECT email FROM usuarios WHERE id = usuario_id
        DB-->>Worker: email
        Worker->>Mail: enviar(email, asunto, cuerpo)
        alt Envío Exitoso
            Mail-->>Worker: OK
            Worker->>DB: INSERT INTO notificaciones_procesadas (message_id)
            Worker->>DB: UPDATE mensajes_outbox SET estado = 'enviado'
            Worker->>DB: COMMIT
        else Fallo Transitorio (Reintento)
            Mail-->>Worker: Error / Timeout
            Note over Worker: Backoff exponencial (retrasos de 4s, 8s, 16s, 32s + jitter, sin sleep)
            Worker->>DB: UPDATE mensajes_outbox SET siguiente_intento = NOW() + delay, intentos += 1
            Worker->>DB: COMMIT
        else Intentos Agotados (>= 5)
            Worker->>DB: UPDATE mensajes_outbox SET estado = 'muerto', ultimo_error = err
            Worker->>DB: COMMIT
        end
    end
```

**Ciclo de Estados del Mensaje Outbox:**

```mermaid
stateDiagram-v2
    [*] --> pendiente : crear_prestamo (Transacción ACID con el préstamo)
    pendiente --> pendiente : Fallo en envío (intentos < 5)<br/>Recalcula siguiente_intento con backoff
    pendiente --> enviado : Entrega exitosa al notificador<br/>(Registrado en notificaciones_procesadas)
    pendiente --> enviado : Reentrega detectada<br/>(Deduplicado por message_id)
    pendiente --> muerto : Intentos >= 5 superados<br/>o versión de contrato no soportada
    enviado --> [*]
    muerto --> [*] : Intervención / DLQ
```



### Escenario 4 — Solicitud de salón por rol (ADR-0018)

El Estudiante pide un salón; el Auditor lo aprueba o rechaza desde su bandeja; el Estudiante
ve la respuesta en "Mis solicitudes" y le llega un correo (si no apagó los avisos de salones).

```mermaid
sequenceDiagram
    actor E as Estudiante
    actor A as Auditor
    participant API as UTB Tracker (FastAPI)
    participant DB as Base de datos
    participant W as Worker (outbox)

    E->>API: POST /prestamos-salon (permiso salones.solicitar + correo verificado)
    API->>DB: valida conflictos con clases y otras solicitudes, guarda "pendiente"
    A->>API: GET /prestamos-salon/gestion (permiso solicitudes.gestionar)
    API->>DB: pendientes + 2 consultas para el conflicto de toda la página
    API-->>A: lista con "conflicto" por solicitud
    A->>API: POST /prestamos-salon/{id}/rechazar {respuesta}
    API->>DB: estado, respuesta, atendido_por/en + bitácora + correo en el outbox (1 transacción)
    W->>DB: lee el outbox
    W-->>E: correo "Tu solicitud ... fue rechazada" (respeta preferencias)
    E->>API: GET /prestamos-salon/mias
    API-->>E: estado y motivo del rechazo
```

Un Estudiante que llame a la bandeja o a aprobar recibe 403 y la app muestra "No tienes acceso a
esto". El modo prueba del Administrador solo cambia lo que la app dibuja: la API sigue
aplicando su rol real.

### Escenario 5 — Registro institucional y rol por asignación (ADR-0019)

```mermaid
sequenceDiagram
    actor Ad as Administrador
    actor P as Persona nueva
    participant API as UTB Tracker (FastAPI)
    participant DB as Base de datos

    Ad->>API: POST /usuarios/asignaciones {correo exacto, rol Auditor, cargo}
    API->>DB: guarda la fila + bitácora (correo oculto)
    P->>API: POST /auth/register {correo @utb.edu.co, ...} (un "rol" en el cuerpo se ignora)
    API->>API: error_correo_nuevo: dominio exacto en DOMINIOS_PERMITIDOS (si no, 422)
    API->>DB: cuenta con rol base (Estudiante) y SIN verificar + correo de verificación
    P->>API: GET /auth/verificar-correo?token=...
    API->>DB: correo comprobado -> rol_resuelto = rol de la asignación
    API->>DB: sube sesion_version (cierra sesiones) + bitácora usuario.rol_automatico
    P->>API: POST /auth/login -> GET /auth/me
    API-->>P: rol Auditor, rol_origen "correo", cargo
```

Sin correo real en producción la cuenta nace "verificada" pero sin `email_verificado_en`: no
cuenta como comprobada y se queda con el rol base hasta que un administrador le asigne otro.

## Infrastructure Level 1

El backend de UTB Tracker se despliega en un único servidor Linux (VPS) gestionado
manualmente mediante `systemd`. El proceso de entrega continua está automatizado con
GitHub Actions (`.github/workflows/ci.yml`).

```mermaid
graph TD
    subgraph Internet
        Mobile["📱 App Flutter\n(cliente móvil)"]
    end

    subgraph VPS ["☁️ VPS Linux (Ubuntu 22.04)"]
        Nginx["🔀 Nginx\n(proxy inverso, puerto 443/80)"]
        Uvicorn["⚙️ Uvicorn\n(ASGI server, puerto 8000)\nutb-tracker.service (systemd)"]
        Postgres["🗄️ PostgreSQL 16\n(puerto 5432, local)"]
    end

    subgraph GitHub
        CI["🔄 GitHub Actions\n(CI/CD pipeline)"]
    end

    Mobile -->|"HTTPS :443"| Nginx
    Nginx -->|"HTTP :8000 (interno)"| Uvicorn
    Uvicorn -->|"TCP :5432 (local)"| Postgres
    CI -->|"SSH deploy"| VPS
```

**Motivación:**
El equipo opera con un presupuesto y tiempo académico limitados. Un único VPS con Nginx
como proxy inverso y Uvicorn gestionado por `systemd` cubre el escenario QS-03
(300 usuarios simultáneos) sin la sobrecarga operativa de contenedores o servicios
gestionados. La decisión de no usar microservicios está formalizada en
[ADR-0005](../adr/0005-monolito-vs-microservicios.md).

**Características de calidad y rendimiento:**
- **TLS terminado en Nginx:** todo el tráfico entre el cliente móvil y el servidor
  viaja cifrado (HTTPS), cumpliendo QS-04 y la Ley 1581 de 2012.
- **Proceso Uvicorn (API) gestionado por systemd:** el servicio web de la API se reinicia automáticamente
  si el proceso cae (`Restart=always`), contribuyendo a la disponibilidad QS-01. (Nota: el despliegue
  actual no arranca el worker de mensajería; este se ejecuta manualmente vía CLI cuando se requiere).
- **PostgreSQL local (mismo host):** la latencia de red entre el backend y la base de
  datos es prácticamente despreciable (loopback local), favoreciendo QS-02 (tiempo de respuesta).
- **Despliegue automatizado vía CI:** los cambios en `main` se despliegan sin
  intervención manual después de pasar la suite de pruebas y la auditoría de dependencias.

**Mapeo de bloques constructivos a infraestructura:**

| Bloque (`app/`) | Infraestructura |
|---|---|
| `routers/health.py` — `GET /salud` | Uvicorn → PostgreSQL (`SELECT 1` activo) |
| `routers/resources.py` — `/recursos` | Uvicorn → PostgreSQL (tabla `recurso`) |
| `routers/loans.py` — `/prestamos` | Uvicorn → PostgreSQL (tablas `recurso`, `prestamo`, `mensajes_outbox`, transacción ACID) |
| `messaging/worker.py` — Worker Outbox | Ejecución manual CLI (`python -m app.messaging.worker`); no arrancado en el despliegue actual |
| `routers/auth.py` — `/auth` | Uvicorn → PostgreSQL (tabla `usuario`) |

## Infrastructure Level 2

### Despliegue reproducible con Docker Compose (ADR-0012)

Para desarrollo y demostraciones el sistema completo se levanta con `docker compose up --build`:

```mermaid
flowchart LR
    nav[Navegador :8080] --> web[web · nginx + Flutter web]
    nav -->|HTTP JSON| api[api · FastAPI :8000]
    api --> db[(db · PostgreSQL 16)]
    worker[worker · python -m app.messaging] --> db
    worker -->|SMTP / FCM| ext[Servicios externos]
    seed[seed · perfil demo] -.-> db
```

`api`, `worker` y `seed` usan la misma imagen (`Dockerfile`): es un monolito modular (ADR-0005),
no microservicios. La API aplica `alembic upgrade head` al arrancar.

### Estimación de costos mensuales (S8 — req. 8.10)

Costos aproximados para el entorno de producción del proyecto académico:

| Componente | Proveedor / opción | Costo mensual estimado |
|---|---|---|
| **VPS 2 vCPU / 4 GB RAM** | DigitalOcean Droplet / Linode / Oracle Free Tier | USD $12 – $24 (Oracle: $0 en capa gratuita) |
| **PostgreSQL** | Instancia local en el mismo VPS (incluida arriba) | $0 adicional |
| **Dominio `.com`** | Namecheap / Google Domains | USD $1 – $2 (prorrateado mensual) |
| **SSL/TLS** | Let's Encrypt (Certbot) | $0 |
| **GitHub Actions** | Plan Free (2 000 min/mes incluidos) | $0 |
| **Total estimado** | | **USD $0 – $26 / mes** |

> La capa gratuita de Oracle Cloud Infrastructure (Ampere A1 4 vCPU / 24 GB RAM)
> puede alojar el sistema completo en producción sin costo adicional durante la
> vida académica del proyecto.


# Conceptos transversales (Cross-cutting Concepts)

## 8.1 Patrón de Capas y Control de Erosión Arquitectónica

> **Regla automática (ADR-0023, S09):** `tests/test_erosion_capas.py` falla si un router importa modelos o consulta la base, si un servicio importa routers, si un modelo depende de capas superiores, o si `domain/` de Flutter importa Flutter, `http`, `data/` o `presentation/`. Corre en el CI en cada unión a `main`.
Para evitar la erosión del estilo Monolito Modular (S9 — req. 9.6), el backend implementa una separación estricta de tres capas en cada módulo de dominio:
1. **Capa de Enrutamiento HTTP (`app/routers/`):** Expone endpoints REST, valida datos de entrada mediante esquemas Pydantic y gestiona respuestas HTTP/códigos de estado (200, 201, 404, 409). No ejecuta lógica de negocio ni consultas directas al ORM.
2. **Capa de Servicio (`app/services/`):** Orquesta la lógica de negocio, reglas de dominio (ej. exclusividad de recursos en préstamo — QS-06) y transacciones de base de datos. Módulos: `services/resources.py`, `services/loans.py`, `services/auth.py`.
3. **Capa de Persistencia y Modelos (`app/models/` y `app/core/database.py`):** Define entidades SQLAlchemy mapeadas a tablas PostgreSQL y administra la sesión de conexión.

## 8.2 Seguridad, Hashing y Autenticación
- **Protección de Credenciales (QS-04 / ADR-0004 / req. 9.8):** Las contraseñas se almacenan exclusivamente como hashes irreversibles generados con `bcrypt` (sales dinámicas automáticas). El sistema nunca almacena ni compara contraseñas en texto plano.
- **Tokens de Acceso:** Uso de JSON Web Tokens (JWT) firmados con algoritmo simétrico HS256 (`PyJWT`), con tiempo de expiración configurable y verificación sin estado (*stateless*), desacoplando la autorización de la base de datos en cada consulta.

## 8.3 Observabilidad y Logging Estructurado
- **Middleware HTTP (`app/main.py`):** Cada petición entrante es interceptada para asignarle un identificador único correlativo (`request_id` formato UUID de 8 caracteres).
- **Formato Estructurado:** Los eventos de acceso se registran en formato JSON con marca de tiempo UTC, método HTTP, ruta, código de estado y latencia en milisegundos (`latency_ms`), listo para ingesta en herramientas de monitoreo como Grafana Loki o Datadog.
- **Sondeo de Salud Profundo (`app/routers/health.py`):** El endpoint `GET /salud` ejecuta activamente una consulta `SELECT 1` sobre el pool de PostgreSQL para validar la salud real de la infraestructura.

## 8.4 Evaluación de Inteligencia Artificial Generativa en el Producto (req. 9.9)
Se evaluó la posible integración de modelos de IA generativa (LLMs) dentro del flujo operativo de UTB Tracker.
- **Determinación Arquitectónica: NO APLICA / NO SE INTEGRA EN RUNTIME.**
- **Justificación:** UTB Tracker es un sistema de misión crítica para el control y la trazabilidad de inventario físico en salones de clase. Los requisitos centrales del sistema son la **consistencia transaccional inmediata (QS-06)** y la **alta confiabilidad y predictibilidad (QS-03)**. Los modelos generativos introducen no determinismo, latencia adicional de inferencia y costos de API externos que no agregan valor al registro transaccional de préstamos. La IA se utiliza exclusivamente como herramienta de asistencia en el desarrollo y revisión de código por el equipo de ingeniería, documentada en `docs/ia.md`.

## 8.5 Resiliencia, Timeouts y Reintentos (S11 — req. 11.1 y 11.2)
- **Pool de Conexiones Resiliente (`app/core/database.py`):** Configurado con `pool_size=10`, `max_overflow=20`, `pool_timeout=30`, `pool_recycle=1800` y `pool_pre_ping=True`. La validación de ping previo descarta conexiones inactivas cerradas por el kernel o firewall, eliminando errores `OperationalError` tras periodos de inactividad.
- **Reintentos con Backoff y Jitter (`app/core/resilience.py`):** Decorador `@with_retry` implementado para tolerar fallos transitorios en conexiones de red o base de datos. Emplea la fórmula `delay = min(max_delay, base_delay * 2^intento) + random_jitter`, mitigando problemas de sincronización de reintentos concurrentes (*thundering herd*).

## 8.6 Idempotencia y Prevención de Condiciones de Carrera (S11 — req. 11.3 y R-02)
- **Idempotencia de Préstamos (`app/routers/loans.py`, `app/services/loans.py`):** Soporte para la cabecera `X-Idempotency-Key`. Los clientes móviles reintentan peticiones de forma transparente ante fluctuaciones de Wi-Fi; el backend registra la clave en `idempotencia_registros` y devuelve el préstamo original sin duplicar registros ni emitir falsos errores 409.
- **Bloqueo Pesimista de Fila (QS-06):** Para evitar la condición de carrera identificada en R-02, la consulta del recurso en `crear_prestamo` aplica bloqueo pesimista `.with_for_update()`, serializando solicitudes que intenten prestar el mismo equipo simultáneamente.

## 8.7 Descomposición: Sagas, Patrón Outbox y Circuit Breakers (S11/S12 — req. 11.4, 11.5 y 11.6)
- **Regla central de negocio (Préstamos): Transacción ACID local:** La validación de disponibilidad y asignación del préstamo ocurren en un único `db.commit()` atómico local, garantizando consistencia inmediata (QS-06). Las Sagas no aplican para la reserva del recurso.
- **Transactional Outbox para Notificaciones Desacopladas (S12 / ADR-0006):** Para los efectos colaterales secundarios (notificación por correo al usuario), se implementó el patrón Transactional Outbox ([ADR-0006](../adr/0006-mensajeria-asincrona-outbox.md)). La inserción en `mensajes_outbox` comparte la transacción del préstamo; un proceso consumidor (`app/messaging/worker.py`) entrega las notificaciones de forma asíncrona con semántica *at-least-once*, deduplicación en `notificaciones_procesadas` y reintentos con backoff exponencial.
- **Circuit Breaker (`app/core/resilience.py`):** Se provee la clase `CircuitBreaker` para aislar fallos en integraciones externas directas, alternando estados CLOSED, OPEN y HALF_OPEN para evitar caídas en cascada.
- **Decisión de Microservicios:** Formalizada en [ADR-0005](../adr/0005-monolito-vs-microservicios.md), donde se fundamenta el rechazo de microservicios para maximizar la consistencia transaccional y simplicidad operativa del equipo.

## 8.8 Estrategia de Consistencia de Datos
El sistema define garantías explícitas por cada operación de lectura y escritura. La regla de oro establece que las operaciones de escritura validan invariantes exclusivamente contra la base de datos primaria bajo transacciones ACID locales (con bloqueo pesimista en préstamos y restricciones declarativas en modelos). Para el detalle exhaustivo por operación, garantías del flujo por eventos y análisis de brechas de concurrencia, consultar [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md).

## 8.9 Estrategia de Caché (Diseño Propuesto)
Para mitigar la sobrecarga en horas pico (QS-02, QS-03) sin comprometer la consistencia de inventario (QS-06), se diseña una capa de caché en memoria de proceso acotada por TTL (60 s para recursos, 120 s para salones) con invalidación por grupos de versión ante eventos de escritura. Ninguna operación de modificación lee de la caché. Especificación técnica completa en [`docs/datos/diseno-cache.md`](../datos/diseno-cache.md) *(DISEÑO PROPUESTO — NO IMPLEMENTADO)*.


## 8.10 Arquitectura de Seguridad y Privacidad (S13)
En la Semana 13 se formalizó el análisis integral de seguridad y privacidad del sistema:
- **Modelado de Amenazas ([`docs/seguridad/modelo-amenazas.md`](../seguridad/modelo-amenazas.md)):** Aplicación de la metodología STRIDE sobre las 6 fronteras de confianza del C4 (Nivel 2), priorizando 22 amenazas por riesgo técnico ($P \times I$). Se identificaron como riesgos críticos la auto-asignación de roles en el registro público (T-01, riesgo 25), la falsificación potencial de tokens por claves por defecto (T-02, riesgo 20) y la enumeración de usuarios (T-03, riesgo 20).
- **Análisis de Dependencias y SBOM ([`docs/seguridad/analisis-dependencias.md`](../seguridad/analisis-dependencias.md)):** Integración de `pip-audit` en el pipeline de CI (`.github/workflows/ci.yml:51-55`), identificación de 29 vulnerabilidades en `starlette` y `pyjwt`, auditoría del cliente Flutter con `flutter pub outdated`, y generación del SBOM formal CycloneDX v1.5 en [`docs/seguridad/sbom/bom.json`](../seguridad/sbom/bom.json).
- **Privacidad y Protección de Datos ([`docs/seguridad/privacidad.md`](../seguridad/privacidad.md)):** Inventario de datos personales bajo la Ley 1581 de 2012 de Colombia, bases jurídicas de tratamiento, evaluación del principio de minimización y roadmap de gobernanza de datos.
- **Control de Acceso Granular por Recurso:** Formalizado en el [ADR-0008](../adr/0008-control-acceso-granular-recurso.md) para resolver brechas BOLA/IDOR mediante políticas de titularidad de recursos en la capa de servicios.

# Decisiones arquitectónicas

Las decisiones de arquitectura se documentan como ADR individuales en `docs/adr/`, no en esta
sección. Índice de decisiones tomadas hasta ahora:

- [ADR-0001](../adr/0001-estilo-arquitectonico.md) — Estilo arquitectónico: Monolito Modular (S3)
- [ADR-0002](../adr/0002-cambio-stack-fastapi-flutter.md) — Cambio de stack: Django → FastAPI + Flutter (S4)
- [ADR-0003](../adr/0003-integracion-sincrona.md) — Integración entre módulos: llamadas directas síncronas (S4)
- [ADR-0004](../adr/0004-seguridad-jwt.md) — Seguridad y Autenticación: JWT HS256 + bcrypt (S8)
- [ADR-0005](../adr/0005-monolito-vs-microservicios.md) — Preservación del Monolito Modular: rechazo de microservicios (S8)
- [ADR-0006](../adr/0006-mensajeria-asincrona-outbox.md) — Mensajería Asíncrona: Transactional Outbox para notificaciones de préstamos (S12)
- [ADR-0007](../adr/0007-identificadores-enteros-autoincrementales.md) — Identificadores enteros autoincrementales en claves primarias (S12)
- [ADR-0008](../adr/0008-control-acceso-granular-recurso.md) — Control de acceso granular por recurso (mitigación BOLA/IDOR) (S13)
- [ADR-0009](../adr/0009-administracion-de-salones.md) — Administración de salones: ocupación en vivo, presencia del profesor y reportes
- [ADR-0010](../adr/0010-auditoria.md) — Auditoría: bitácora de solo-agregar escrita en la misma transacción
- [ADR-0011](../adr/0011-rediseno-interfaz-y-control.md) — Rediseño al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos
- [ADR-0012](../adr/0012-contenedores-docker.md) — Empaquetar el sistema con Docker Compose (PostgreSQL, API, worker y web)
- [ADR-0013](../adr/0013-identidad-propia-y-servidor-unico.md) — Identidad visual propia, interfaz más compacta y un solo servidor (la nube) para web y APK
- [ADR-0014](../adr/0014-autenticacion-correo-verificado-y-tokens-por-id.md) — Autenticación con correo verificado, identidad normalizada y tokens por id
- [ADR-0015](../adr/0015-servicio-de-correo.md) — Servicio de correo con plantillas y entrega por el outbox
- [ADR-0016](../adr/0016-perfil-y-preferencias-en-el-servidor.md) — Perfil personalizable y preferencias guardadas en el servidor
- [ADR-0017](../adr/0017-tipo-de-salon-y-equipamiento-calculado.md) — Tipo de salón y equipamiento calculado desde los recursos
- [ADR-0018](../adr/0018-modelo-de-roles-y-permisos.md) — Modelo de roles y permisos con una matriz única (etiquetas Estudiante/Auditor/Administrador, permisos en /auth/me, modo prueba solo de interfaz)
- [ADR-0019](../adr/0019-correo-institucional-y-rol-por-asignacion.md) — Solo correos institucionales (dominio exacto, sin bloquear cuentas antiguas) y rol por una lista de asignación que solo aplica con el correo comprobado; el rol manual gana
- [ADR-0020](../adr/0020-foto-de-perfil.md) — Foto de perfil como miniatura limpia (firma real, sin EXIF/GPS, sin librerías nuevas en el backend) en la tabla aparte `fotos_perfil`
- [ADR-0023](../adr/0023-retiro-del-prestamo-de-equipos-y-control-de-erosion.md) — "prestado" deja de usarse (422 y migración de datos auditada), `/prestamos/*` queda como legado obsoleto y las capas se verifican solas con `tests/test_erosion_capas.py` (S09)
- [ADR-0022](../adr/0022-habilitacion-ocupacion-y-equipos-del-salon.md) — Habilitación manual del salón (motivo obligatorio) separada de la ocupación calculada; `estado` calculado con los valores de siempre; salón deshabilitado no se solicita y sus solicitudes se señalan y avisan sin cancelarse solas; historial del salón; equipos fijos con estado (nunca "prestado"), plantillas con vista previa; panel sin N+1
- [ADR-0021](../adr/0021-catalogo-de-salones-utb.md) — Catálogo de salones UTB: regla del código en un solo lugar, lista provisional en un archivo de datos (59 salones, corregida con una tesis de la biblioteca UTB), carga idempotente que nunca borra y solo el Administrador crea, renombra y desactiva

# Requisitos de calidad

## Descripción general de los requisitos de calidad

El árbol parte de los cinco objetivos de calidad definidos en la sección "Introducción y objetivos".
Cada rama se desglosa en atributos concretos y se prioriza con dos ejes: **importancia para el
negocio** y **dificultad técnica de lograrlo** (Alta/Media/Baja, Alta/Media/Baja).

```
Utilidad (UTB Tracker)
│
├── Confiabilidad de los datos
│   └── El sistema le da la confianza a quien lo usa de que el estado de los objetos (Prestado/funcionando/dañado) es correcto en todo momento      [Alta / Media]
│
├── Usabilidad
│   ├── Necesita ser rapida e intuitiva para el auxiliar de planta a la hora de registrar un prestamo, devolverlo o registrar daños. [Alta / Media]
│   └── Necesita ser rapida e intuitiva para los docentes/estudiantes a la hora de pedir prestamos de forma concurrente.                       [Alta / Media]
│
├── Seguridad
│   ├── Proteccion de usuarios. Solo el usuario y el administrador pueden ingresar al sistema y cada uno tiene distintos permisos                  [Alta / Alta]
│   └── Confidencialidad de datos de facturación entre propietarios       [Alta / Media]
│
├── Disponibilidad
│   └── El sistema debe estar disponible en los horarios donde se encuentran trabajando los auxiliares de planta     [Media / Baja]
│
└── Rendimiento
    └── El sistema debe poder soportar varias solicitudes a la vez y responder en un tiempo razonable [Alta / Media]
```

## Escenarios de calidad

Se documentan 5 escenarios, uno por rama principal del árbol, en formato
Fuente–Estímulo–Ambiente–Artefacto–Respuesta–Medida (SEI). Cada uno está enlazado desde su
aspecto correspondiente en `docs/aspectos.md`.

### QS-01 — Disponibilidad



| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Intenta acceder al sistema |
| **Ambiente** | Horario habitual del campus (7:00 a.m. – 7:00 p.m.) |
| **Artefacto** | Servicio movil de UTB Tracker |
| **Respuesta** | El sistema atiende la solicitud sin caída del servicio |
| **Medida** | Disponibilidad ≥ 99% del tiempo dentro de la ventana 7am–7pm |

### QS-02 — Rendimiento (tiempo de respuesta)

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Abre la aplicación o navega a una nueva vista |
| **Ambiente** | Operación normal, dispositivo conectado (probablemente) al internet del campus |
| **Artefacto** | Servicio movil de UTB Tracker |
| **Respuesta** | La vista carga y queda interactiva |
| **Medida** | Tiempo de carga ≤ 3 segundos |
| **Evidencia empírica (S9 / S14)** | Evaluada con `tests/test_performance.py`: p50 de respuesta API ~4 ms, p95 < 25 ms, muy por debajo del umbral de 3 s. Medición empírica S14 con endpoints reales reportada en [`docs/calidad/medicion-qs03.md`](../calidad/medicion-qs03.md) (máx 2976 ms bajo 300 peticiones concurrentes). |

### QS-03 — Rendimiento (concurrencia)

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Múltiples usuarios usan el sistema al mismo tiempo (hora pico) |
| **Ambiente** | Operación normal |
| **Artefacto** | Backend / API de UTB Tracker |
| **Respuesta** | El sistema procesa las solicitudes sin degradar el servicio |
| **Medida** | Soporta al menos 300 usuarios simultáneos sin errores ni caídas |
| **Evidencia empírica (S9 / S14)** | `tests/test_performance.py::test_concurrencia_solicitudes_simultaneas`: 50 peticiones simultáneas con ThreadPool, 100% de tasa de éxito (HTTP 200), 0 caídas o timeouts. Medición empírica S14 con 300 usuarios simultáneos sobre endpoints reales en [`docs/calidad/medicion-qs03.md`](../calidad/medicion-qs03.md): 300/300 peticiones exitosas (0 errores). |


### QS-04 — Seguridad

| Campo | Descripción |
|---|---|
| **Fuente** | Usuario sin rol de auxiliar/administrador, o un atacante externo |
| **Estímulo** | Intenta registrar, modificar o eliminar un recurso del catálogo (objeto o salón) |
| **Ambiente** | Operación normal del sistema |
| **Artefacto** | Módulo de autorización / API de gestión de recursos |
| **Respuesta** | El sistema bloquea la acción, deniega el acceso y no altera la base de datos |
| **Medida** | 0% de operaciones de modificación no autorizadas permitidas; tokens de sesión (JWT) firmados de forma segura |

### QS-05 — Usabilidad

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar de planta / laboratorio |
| **Estímulo** | Debe registrar el préstamo de un equipo o reportar un daño por primera vez, sin capacitación previa |
| **Ambiente** | Operación normal en el campus (con usuarios en fila para atención) |
| **Artefacto** | Formulario de registro de préstamo o daño en la app móvil |
| **Respuesta** | El auxiliar completa la operación correctamente |
| **Medida** | Completa el registro del préstamo o reporte en menos de 1 minuto y en su primer intento, sin cometer errores críticos |

### QS-06 — Confiabilidad de los datos

| Campo | Descripción |
|---|---|
| **Fuente** | Dos auxiliares o usuarios que intentan prestar el mismo recurso simultáneamente |
| **Estímulo** | Dos peticiones `POST /prestamos` concurrentes sobre el mismo `recurso_id` |
| **Ambiente** | Hora pico del campus, red del campus |
| **Artefacto** | Módulo de préstamos (`app/routers/loans.py`) + PostgreSQL |
| **Respuesta** | Solo una petición crea el préstamo; la segunda recibe 409 Conflict sin crear ningún registro |
| **Medida** | 0% de recursos con dos préstamos activos simultáneos; segunda petición siempre recibe 409 |

# Riesgos y deudas técnicas

Identificados durante la auditoría arquitectónica (Semanas 8, 9 y 11). Ver informe completo
en `docs/auditoria_s8_s9_s11.md`.

| # | Riesgo / Deuda Técnica | Impacto | Mitigación y Estado |
|---|---|---|---|
| **R-01** | Contraseñas sin hashing criptográfico (`services/auth.py`) | Crítico — Seguridad / QS-04. Fuga de BD comprometería credenciales | **Mitigado en S9:** Hashing con salt dinámico `bcrypt` nativo en `app/core/hashing.py`. |
| **R-02** | Condición de carrera en préstamos (sin bloqueo de fila) | Alto — Confiabilidad / QS-06. Dos solicitudes paralelas pueden prestar el mismo equipo | **Mitigado en S11:** Bloqueo pesimista de fila `.with_for_update()` en `app/services/loans.py`. |
| **R-03** | Ausencia de migraciones Alembic en producción | Medio — Operabilidad. `create_all()` no permite cambios de esquema en caliente | **Parcialmente mitigado en S12:** Se creó la migración `6c7d8e9f0a1b` para las tablas de mensajería outbox (verificada únicamente en SQLite, no en PostgreSQL). Persiste la deuda técnica de que la migración previa `5b652dd28f00` falla desde una base vacía. |
| **R-04** | Pipeline CI apuntaba a `app/tests/` (1 test) en lugar de `tests/` (suite completa) | Alto — Calidad. Código defectuoso podía desplegarse pasando el único test de salud | **Mitigado en S8:** `ci.yml` ahora corre la suite completa (`pytest tests/ -v`) con contenedor PostgreSQL. |
| **R-05** | Falta de `Idempotency-Key` en `POST /prestamos` | Medio — Integridad. Reintentos del cliente Flutter en red inestable pueden duplicar reservas | **Mitigado en S11:** Soporte de cabecera `X-Idempotency-Key` respaldada por `idempotencia_registros`. |
| **R-06** | Doble reserva concurrente de salones (`services/prestamos_salon.py:114`) | Alto — Confiabilidad / QS-06. Validación en Python sin bloqueo permite reservas solapadas | **Abierto / Deuda técnica:** Propuesta de restricción de exclusión GiST o `with_for_update` en [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md). |
| **R-07** | Inserción de horarios solapados (`services/horarios.py:89`) | Medio — Integridad / QS-06. Falta de restricción de exclusión en BD permite superposición horaria | **Abierto / Deuda técnica:** Propuesta de restricción PostgreSQL en [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md). |
| **R-08** | Doble devolución de préstamo por falta de bloqueo (`services/loans.py:146`) | Medio — Confiabilidad / QS-06. Peticiones simultáneas marcan devolución doblemente | **Abierto / Deuda técnica:** Propuesta de `.with_for_update()` en [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md). |
| **R-09** | Nombres de usuario duplicados por omisión de `unique=True` (`models/auth_models.py:19`) | Alto — Seguridad / QS-04. Nombres idénticos rompen el flujo de login (`auth.py:70`) | **Abierto / Deuda técnica:** Propuesta de restricción única en [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md). |
| **R-10** | Inoperancia de bloqueo pesimista en SQLite (`services/loans.py:54-60`) | Medio — Confiabilidad / QS-06. Pruebas locales en SQLite no validan aislamiento de concurrencia | **Abierto / Deuda técnica:** Propuesta de estandarizar PostgreSQL local en [`docs/datos/consistencia-por-operacion.md`](../datos/consistencia-por-operacion.md). |
| **R-11** | Enumeración de usuarios por clave entera expuesta (`routers/auth.py:53-59`) | Alto — Seguridad / QS-04. Falta de chequeo de autorización permite enumerar usuarios | **Abierto / Deuda técnica:** Documentado en [`docs/adr/0007-identificadores-enteros-autoincrementales.md`](../adr/0007-identificadores-enteros-autoincrementales.md). |
| **R-12** | Auto-asignación de roles privilegiados en registro público (`services/auth.py:40-44`) | Crítico — Seguridad / QS-04. Atacante puede enviar `{"rol": "administrador"}` y ganar control total | **Abierto / Deuda técnica:** Propuesta de forzar `rol = "usuario_utb"` en registro público en [`docs/seguridad/modelo-amenazas.md`](../seguridad/modelo-amenazas.md). |
| **R-13** | Creación de préstamos a nombre de terceros por falta de validación de titularidad (`services/loans.py:46-48`) | Alto — Seguridad / Integridad. Estudiantes pueden comprometer a otros asignándoles equipos | **Abierto / Deuda técnica:** Propuesta de autorización a nivel de recurso en [`docs/adr/0008-control-acceso-granular-recurso.md`](../adr/0008-control-acceso-granular-recurso.md). |
| **R-14** | Secretos de JWT y firmas criptográficas con valores débiles por defecto (`core/config.py:14,21`) | Crítico — Seguridad / QS-04. Si falta variable de entorno, permite falsificar tokens con clave `"change-me-in-production"` | **Abierto / Deuda técnica:** Propuesta de validación estricta y fallo al inicio del backend en [`docs/seguridad/modelo-amenazas.md`](../seguridad/modelo-amenazas.md). |
| **R-15** | Ausencia de Rate Limiting en API y Login (`routers/auth.py:21-26`) | Alto — Disponibilidad / QS-03. Ataques de fuerza bruta y agotamiento de CPU por hashing `bcrypt` | **Abierto / Deuda técnica:** Propuesta de middleware de limitación de tasa en [`docs/seguridad/modelo-amenazas.md`](../seguridad/modelo-amenazas.md). |
| **R-16** | Vulnerabilidades conocidas en dependencias externas Starlette y PyJWT (`requirements.txt`) | Alto — Seguridad. PYSEC-2026-161 y GHSA-pxh4-856f-4h89 detectados por `pip-audit` | **Abierto / En proceso:** Actualización de paquetes y bloqueo en CI en [`docs/seguridad/analisis-dependencias.md`](../seguridad/analisis-dependencias.md). |
| **R-17** | Almacenamiento de tokens de sesión en archivo plano sin cifrar en Flutter (`frontend/lib/core/storage/token_storage.dart:18-19`) | Medio — Privacidad / Seguridad. Exposición de tokens en `.utb_sesion.json` | **Abierto / Deuda técnica:** Propuesta de migrar a `flutter_secure_storage` en [`docs/seguridad/privacidad.md`](../seguridad/privacidad.md). |
| **R-18** | Entrega at-least-once con potenciales duplicados y orden no garantizado en Outbox (`messaging/worker.py:145-153, 250-291`) | Bajo — Calidad / Usabilidad. Mensajes pueden entregarse fuera de orden o duplicarse si el worker cae | **Amenaza aceptada (S13):** Se asume por diseño para mantener desacoplamiento sin 2PC ni colas FIFO complejas ([`docs/seguridad/modelo-amenazas.md`](../seguridad/modelo-amenazas.md)). |
| **R-19** | Vulnerabilidad de bypass y forja de tokens JWT por omisión de lista de revocación (T-17) | Medio — Seguridad / QS-04. Cierre de sesión declarativo mantiene tokens válidos hasta su expiración | **Amenaza aceptada (S13 / A-03):** Se preserva diseño stateless; ventana de riesgo acotada por `ACCESS_TOKEN_EXPIRE_MINUTES`. |
| **R-20** | Vulnerabilidades en cadena de suministro de paquetes backend (T-22) | Medio — Seguridad / Integridad. CVEs en starlette 0.50.0 y pyjwt 2.12.1 | **Abierto / En proceso:** Mitigado parcialmente con `pip-audit` en CI (`ci.yml:51-55`); pendiente actualización de versiones a starlette >= 1.0.1 y pyjwt >= 2.14.0. |
| **R-21** | Margen mínimo de QS-02 bajo 300 peticiones concurrentes con 1 worker (máx 2976 ms vs 3000 ms) | Medio — Rendimiento / QS-02. Latencia al límite del umbral ante picos de demanda. Causa no aislada (hipótesis no verificada: 1 worker de Uvicorn y pool de 30 conexiones en `app/core/database.py:21-24`) | **Abierto / Deuda técnica:** Mitigación propuesta mediante caché en memoria acotada por TTL ([`docs/datos/diseno-cache.md`](../datos/diseno-cache.md)) y despliegue multi-worker de Uvicorn. Evidencia en [`docs/calidad/medicion-qs03.md`](../calidad/medicion-qs03.md). |

## 11. Revisión entre pares

| Hallazgo | Evaluador | Impacto | Acción | Estado |
|---|---|---|---|---|
| Falta de tabla de mitigaciones en sección 8 | Profesor García | Alto (S13) | Añadir tabla de mitigaciones en `docs/arc42/arc42.md` | Mitigado |
| Ausencia de enlace a modelo de amenazas y privacidad | Profesor García | Medio (S13) | Añadir enlaces a `docs/seguridad/modelo-amenazas.md` y `docs/seguridad/privacidad.md` | Mitigado |
| Pendiente de hallazgos de pares | Equipo | N/A | Revisar y documentar hallazgos restantes | En progreso |

---

<PENDIENTE: hallazgos de la revisión entre pares>




| Término | Definición |
|---|---|
| **Recurso** | Equipo electrónico individual trackeado por el sistema (video beam, computador, A/C, TV, sistema de audio). No incluye mobiliario (sillas, mesas) — esos no se registran por unidad. |
| **Salón** | Aula, laboratorio, auditorio o almacén de la UTB, identificado por un código (ej. `A1-304`). Es la ubicación "de origen" de un recurso. |
| **Estado (de un recurso)** | Uno de: `disponible`, `prestado`, `dañado`, `mantenimiento`. Determina si el recurso puede prestarse — ver regla de negocio en `app/routers/loans.py`. |
| **Préstamo** | Registro de que un `Usuario` tomó un `Recurso` prestado, con fecha esperada y real de devolución. Un recurso solo puede tener un préstamo activo a la vez (QS-06). |
| **Vencido** | Un préstamo cuya fecha de devolución esperada ya pasó y no se ha devuelto. Se calcula en la consulta, no se guarda como estado aparte. *(La regla de bloqueo por préstamo vencido está pendiente de implementación — ver arc42 sección 5, riesgos abiertos de `prestamos`.)* |
| **Auxiliar (de planta / laboratorio)** | Rol administrador del sistema: gestiona el catálogo, revisa préstamos, reporta daños. |
| **Usuario UTB** | Rol de estudiante o profesor: consulta el catálogo y solicita préstamos. |
| **Aspecto** | Corte vertical del sistema con valor propio, trazable de punta a punta (ver `docs/aspectos.md`). No confundir con "recurso" del dominio de negocio. |
| **Escenario de calidad (QS)** | Especificación medible de un atributo de calidad, en formato Fuente-Estímulo-Ambiente-Artefacto-Respuesta-Medida (arc42 sección 10). |
| **ADR** | Architecture Decision Record — registro corto e inmutable de una decisión de arquitectura, con alternativas descartadas y consecuencias (`docs/adr/`). |
| **Corte vertical** | Funcionalidad completa que atraviesa varios módulos de dominio con lógica de negocio real (no solo esqueleto), probada de extremo a extremo. |

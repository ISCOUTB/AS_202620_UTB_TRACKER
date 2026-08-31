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

![Diagrama de contexto C4 Nivel 1 - Tractar](c4/c4_nivel1.md)

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

# Deployment View

## Infrastructure Level 1

***\<Overview Diagram\>***

Motivation  
*\<explanation in text form\>*

Quality and/or Performance Features  
*\<explanation in text form\>*

Mapping of Building Blocks to Infrastructure  
*\<description of the mapping\>*

## Infrastructure Level 2

### *\<Infrastructure Element 1\>*

*\<diagram + explanation\>*

### *\<Infrastructure Element 2\>*

*\<diagram + explanation\>*

…

### *\<Infrastructure Element n\>*

*\<diagram + explanation\>*

# Cross-cutting Concepts

## *\<Concept 1\>*

*\<explanation\>*

## *\<Concept 2\>*

*\<explanation\>*

…

## *\<Concept n\>*

*\<explanation\>*

# Decisiones arquitectónicas

Las decisiones de arquitectura se documentan como ADR individuales en `docs/adr/`, no en esta
sección. Índice de decisiones tomadas hasta ahora:

- [ADR-0001](../adr/0001-estilo-arquitectonico.md) — Estilo arquitectónico: Monolito Modular (S3)
- [ADR-0002](../adr/0002-cambio-stack-fastapi-flutter.md) — Cambio de stack: Django → FastAPI + Flutter (S4)

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

### QS-03 — Rendimiento (concurrencia)

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Múltiples usuarios usan el sistema al mismo tiempo (hora pico) |
| **Ambiente** | Operación normal |
| **Artefacto** | Backend / API de UTB Tracker |
| **Respuesta** | El sistema procesa las solicitudes sin degradar el servicio |
| **Medida** | Soporta al menos 300 usuarios simultáneos sin errores ni caídas |

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

# Riesgos y deudas técnicas

# Glosario

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

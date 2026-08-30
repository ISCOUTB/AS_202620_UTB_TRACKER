# Aspectos — UTB Tracker

Un aspecto es un corte vertical del sistema con valor propio, trazable de punta a punta:

```
aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia de calidad
```

Cada fila de la tabla debe poder recorrerse completa. En esta entrega varias
columnas quedan en `—` porque todavía no existen ADRs, código ni pruebas.

---

## A-01 · Declarar

- **Nombre:** Formularios intuitivos para auxiliares y solicitantes
- **Para quién:** Auxiliares de planta (que registran préstamos en campo) y estudiantes/profesores que realizan solicitudes desde sus dispositivos móviles.
- **Qué problema resuelve:** El registro manual de préstamos o inventarios es lento y propenso a errores humanos. Si el reemplazo digital no es ágil e intuitivo, se perderá el control sobre los objetos de los salones.

## A-02 · Declarar

- **Nombre:** Acceso al sistema durante la jornada académica
- **Para quién:** Auxiliares de planta, profesores y estudiantes que interactúan con el sistema durante el horario de actividad en el campus (7:00 a.m. a 7:00 p.m.).
- **Qué problema resuelve:** Si el sistema no está disponible al iniciar o finalizar clases (cuando ocurren la mayoría de préstamos y devoluciones), el registro se interrumpe y se pierde la trazabilidad en tiempo real del estado de los equipos.

## A-03 · Declarar

- **Nombre:** Respuesta rápida de la interfaz en el campus
- **Para quién:** Auxiliares de planta y usuarios en el campus que pueden estar usando la red de la utb o datos móviles inestables.
- **Qué problema resuelve:** Una interfaz lenta retrasa al auxiliar de planta al atender a múltiples profesores/estudiantes, generando filas de espera y desincentivando el uso de la aplicación.

## A-04 · Declarar

- **Nombre:** Estabilidad en horas pico de solicitudes
- **Para quién:** El conjunto de profesores y estudiantes que solicitan o devuelven equipos al mismo tiempo (ej. cambios de clase, inicios de jornada).
- **Qué problema resuelve:** Si el backend se satura durante los picos de clase, se retrasan las entregas de video beams u computadores, afectando directamente el inicio de las clases.

## A-05 · Declarar

- **Nombre:** Control de acceso en la gestión del catálogo e inventarios
- **Para quién:** Administradores y auxiliares de planta que requieren permisos diferenciados a los de estudiantes y profesores.
- **Qué problema resuelve:** Si un estudiante/profesor o un atacante externo pudiera alterar el inventario, eliminar recursos o modificar el catálogo de objetos, la base de datos perdería toda su credibilidad.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| A-01 | Formularios intuitivos para auxiliares y solicitantes | Usabilidad para registrar préstamos y reportes rápido — [QS-05](arc42.md#qs-05--usabilidad) | C1: Usuario ↔ UTB Tracker (definido) | [ADR-0001](adr/0001-estilo-arquitectonico.md) | app/routers/users.py | health check | — |
| A-02 | Acceso al sistema durante la jornada académica | Disponibilidad ≥99% en horario 7am–7pm — [QS-01](arc42.md#qs-01--disponibilidad) | C1: Usuario ↔ UTB Tracker (definido) | [ADR-0001](adr/0001-estilo-arquitectonico.md) | app/routers/loans.py | health check | — |
| A-03 | Respuesta rápida de la interfaz en el campus | Tiempo de carga ≤3s en dispositivo móvil — [QS-02](arc42.md#qs-02--rendimiento-tiempo-de-respuesta) | C1: Usuario ↔ UTB Tracker (definido) | [ADR-0001](adr/0001-estilo-arquitectonico.md) | — | — | — |
| A-04 | Estabilidad en horas pico de solicitudes | Soporta ≥300 usuarios concurrentes sin caídas — [QS-03](arc42.md#qs-03--rendimiento-concurrencia) | C1: Usuario ↔ UTB Tracker (definido) | [ADR-0001](adr/0001-estilo-arquitectonico.md) | — | — | — |
| A-05 | Control de acceso en la gestión del catálogo | 0% de modificaciones no autorizadas en inventario — [QS-04](arc42.md#qs-04--seguridad) | C1: Usuario ↔ UTB Tracker (definido) | [ADR-0001](adr/0001-estilo-arquitectonico.md) | app/routers/resources.py | health check | — |

---

## Especificar (escenarios medibles)

**Escenario QS-05 — Usabilidad** *(A-01, definido en `docs/arc42.md`)*

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar de planta / laboratorio |
| **Estímulo** | Debe registrar el préstamo de un equipo o reportar un daño por primera vez, sin capacitación previa |
| **Ambiente** | Operación normal en el campus (con usuarios en fila para atención) |
| **Artefacto** | Formulario de registro de préstamo o daño en la app móvil |
| **Respuesta** | El auxiliar completa la operación correctamente |
| **Medida** | Completa el registro del préstamo o reporte en menos de 1 minuto y en su primer intento, sin cometer errores críticos |

**Escenario QS-01 — Disponibilidad** *(A-02)*

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Intenta acceder al sistema |
| **Ambiente** | Horario habitual del campus (7:00 a.m. – 7:00 p.m.) |
| **Artefacto** | Servicio móvil de UTB Tracker |
| **Respuesta** | El sistema atiende la solicitud sin caída del servicio |
| **Medida** | Disponibilidad ≥ 99% del tiempo dentro de la ventana 7am–7pm |

**Escenario QS-02 — Rendimiento (tiempo de respuesta)** *(A-03)*

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Abre la aplicación o navega a una nueva vista |
| **Ambiente** | Operación normal, dispositivo conectado al internet del campus |
| **Artefacto** | Servicio móvil de UTB Tracker |
| **Respuesta** | La vista carga y queda interactiva |
| **Medida** | Tiempo de carga ≤ 3 segundos |

**Escenario QS-03 — Rendimiento (concurrencia)** *(A-04)*

| Campo | Descripción |
|---|---|
| **Fuente** | Auxiliar o profesor/estudiante |
| **Estímulo** | Múltiples usuarios usan el sistema al mismo tiempo (hora pico) |
| **Ambiente** | Operación normal |
| **Artefacto** | Backend / API de UTB Tracker |
| **Respuesta** | El sistema procesa las solicitudes sin degradar el servicio |
| **Medida** | Soporta al menos 300 usuarios simultáneos sin errores ni caídas |

**Escenario QS-04 — Seguridad** *(A-05)*

| Campo | Descripción |
|---|---|
| **Fuente** | Usuario sin rol de auxiliar/administrador, o un atacante externo |
| **Estímulo** | Intenta registrar, modificar o eliminar un recurso del catálogo (objeto o salón) |
| **Ambiente** | Operación normal del sistema |
| **Artefacto** | Módulo de autorización / API de gestión de recursos |
| **Respuesta** | El sistema bloquea la acción, deniega el acceso y no altera la base de datos |
| **Medida** | 0% de operaciones de modificación no autorizadas permitidas; tokens de sesión (JWT) firmados de forma segura |

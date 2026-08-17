# Aspectos — Tractar

Un aspecto es un corte vertical del sistema con valor propio, trazable de punta a punta:

```
aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia de calidad
```

Cada fila de la tabla debe poder recorrerse completa. En esta entrega varias
columnas quedan en `—` porque todavía no existen ADRs, código ni pruebas.

---

## A-01 · Declarar

- **Nombre:** Formularios intuitivos para conductores y propietarios
- **Para quién:** Conductores con conocimiento tecnológico limitado y propietarios, algunos de
  la tercera edad, que hoy dependen del registro en papel.
- **Qué problema resuelve:** El registro manual de viajes es lento y se pierde si el conductor
  se desvincula antes de entregar la información. Si el reemplazo digital no es igual de
  simple que el papel, no hay adopción y el problema no se resuelve de verdad.

## A-02 · Declarar

- **Nombre:** Acceso al sistema durante la jornada laboral
- **Para quién:** Conductores y propietarios que necesitan registrar o consultar viajes en
  cualquier momento de su jornada (7am–10pm), no solo cuando "les funcione" el sistema.
- **Qué problema resuelve:** Si el sistema no está disponible cuando el conductor termina un
  viaje, vuelve a depender de anotar en papel para registrar después — lo que reintroduce
  exactamente el problema que Tractar busca eliminar.

## A-03 · Declarar

- **Nombre:** Respuesta rápida de la interfaz en dispositivos de gama baja
- **Para quién:** Conductores que usan smartphones de gama baja/media (2GB RAM), muchas veces
  entregados por el propietario, no equipos de alta gama.
- **Qué problema resuelve:** Una interfaz lenta en un teléfono limitado hace que el conductor
  abandone el registro a mitad de camino o vuelva al papel por ser "más rápido en el momento".

## A-04 · Declarar

- **Nombre:** Estabilidad del sistema con muchos usuarios simultáneos
- **Para quién:** El conjunto de propietarios y conductores del gremio que usarán el sistema al
  mismo tiempo, especialmente en horas pico de operación de la flota.
- **Qué problema resuelve:** Si el sistema se cae o se satura cuando varios registran viajes a
  la vez, el propietario pierde confianza en la herramienta y el historial queda incompleto.

## A-05 · Declarar

- **Nombre:** Confidencialidad de la información financiera de cada propietario
- **Para quién:** Propietarios, cuyos datos de facturación y viajes son información financiera
  sensible que no debe quedar expuesta a otros propietarios ni a terceros.
- **Qué problema resuelve:** El historial de viajes determina cuánto factura cada propietario.
  Si otro propietario o un tercero puede verlo, se pierde la confianza necesaria para que el
  gremio adopte el sistema en lugar del papel.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| A-01 | Formularios intuitivos para conductores y propietarios | Usabilidad para usuarios con poca experiencia tecnológica — [QS-05](arc42/10_requisitos_calidad.md#qs-05--usabilidad) | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |
| A-02 | Acceso al sistema durante la jornada laboral | Disponibilidad ≥99% en horario 7am–10pm — [QS-01](arc42/10_requisitos_calidad.md#qs-01--disponibilidad) | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |
| A-03 | Respuesta rápida de la interfaz en dispositivos de gama baja | Tiempo de carga ≤3s en dispositivo de 2GB RAM — [QS-02](arc42/10_requisitos_calidad.md#qs-02--rendimiento-tiempo-de-respuesta) | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |
| A-04 | Estabilidad del sistema con muchos usuarios simultáneos | Soporta ≥300 usuarios concurrentes sin caídas — [QS-03](arc42/10_requisitos_calidad.md#qs-03--rendimiento-concurrencia) | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |
| A-05 | Confidencialidad de la información financiera de cada propietario | 0% de accesos no autorizados exitosos; contraseñas con hash — [QS-04](arc42/10_requisitos_calidad.md#qs-04--seguridad) | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |

---

## Especificar (escenarios medibles)

**Escenario QS-05 — Usabilidad** *(A-01, definido en `docs/arc42/10_requisitos_calidad.md`, sección 10.2)*

| Campo | Descripción |
|---|---|
| **Fuente** | Conductor con conocimiento tecnológico limitado (incluye adultos mayores) |
| **Estímulo** | Debe registrar un viaje nuevo por primera vez, sin capacitación previa |
| **Ambiente** | Uso normal en campo |
| **Artefacto** | Formulario de registro de viaje |
| **Respuesta** | El usuario completa el formulario correctamente |
| **Medida** | Completa el registro en ≤ 3 intentos y en menos de 2 minutos, sin asistencia externa |

**Escenario QS-01 — Disponibilidad** *(A-02)*

| Campo | Descripción |
|---|---|
| **Fuente** | Conductor o propietario |
| **Estímulo** | Intenta acceder al sistema |
| **Ambiente** | Horario laboral habitual (7:00 a.m. – 10:00 p.m.) |
| **Artefacto** | Servicio web de Tractar |
| **Respuesta** | El sistema atiende la solicitud sin caída del servicio |
| **Medida** | Disponibilidad ≥ 99% del tiempo dentro de la ventana 7am–10pm |

**Escenario QS-02 — Rendimiento (tiempo de respuesta)** *(A-03)*

| Campo | Descripción |
|---|---|
| **Fuente** | Usuario (propietario o conductor) |
| **Estímulo** | Abre la aplicación o navega a una nueva vista |
| **Ambiente** | Operación normal, dispositivo de gama baja (2GB RAM) |
| **Artefacto** | Interfaz web de Tractar |
| **Respuesta** | La vista carga y queda interactiva |
| **Medida** | Tiempo de carga ≤ 3 segundos |

**Escenario QS-03 — Rendimiento (concurrencia)** *(A-04)*

| Campo | Descripción |
|---|---|
| **Fuente** | Conjunto de usuarios del sistema |
| **Estímulo** | Múltiples usuarios usan el sistema al mismo tiempo (hora pico) |
| **Ambiente** | Operación normal |
| **Artefacto** | Backend / API de Tractar |
| **Respuesta** | El sistema procesa las solicitudes sin degradar el servicio |
| **Medida** | Soporta al menos 300 usuarios simultáneos sin errores ni caídas |

**Escenario QS-04 — Seguridad** *(A-05)*

| Campo | Descripción |
|---|---|
| **Fuente** | Propietario distinto al dueño de los datos, o atacante externo |
| **Estímulo** | Intenta acceder al historial de facturación de un vehículo que no le pertenece |
| **Ambiente** | Operación normal del sistema |
| **Artefacto** | Módulo de autorización / datos de facturación |
| **Respuesta** | El sistema deniega el acceso y no expone la información |
| **Medida** | 0% de solicitudes no autorizadas exitosas; contraseñas almacenadas con hash (nunca en texto plano) |

Cada escenario queda como línea base verificable para su aspecto: cuando exista implementación
y pruebas, se contrastan contra la medida correspondiente para declarar el aspecto como cumplido.C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |

## Especificar (pendiente de escenario medible)

Falta redactar el escenario de calidad en formato de seis partes (estímulo, fuente, entorno,
artefacto, respuesta, medida) para A-01. Se completa cuando trabajemos la sección 10
(Requisitos de calidad) del arc42.

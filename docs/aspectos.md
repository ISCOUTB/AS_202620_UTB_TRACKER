# Aspectos — UTB Tracker

Un aspecto es un corte vertical del sistema con valor propio, trazable de punta a punta:

```
aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia de calidad
```

Cada fila de la tabla debe poder recorrerse completa. En esta entrega varias
columnas quedan en `—` porque todavía no existen ADRs, código ni pruebas.

---

## A-01 · Declarar

- **Nombre:** Formularios intuitivos para auxiliares y usuarios UTB
- **Para quién:** Auxiliares de planta/laboratorio que atienden varias solicitudes seguidas, y
  estudiantes/profesores sin capacitación previa en el sistema.
- **Qué problema resuelve:** Si registrar un préstamo o reportar un daño toma demasiados pasos,
  el auxiliar vuelve al proceso manual que el sistema busca reemplazar.

## A-02 · Declarar

- **Nombre:** Acceso al sistema durante el horario del campus
- **Para quién:** Auxiliares y usuarios UTB que necesitan registrar o consultar préstamos
  durante la jornada.
- **Qué problema resuelve:** Si el sistema no responde durante el horario activo del campus,
  el registro vuelve a depender de anotaciones manuales.

## A-03 · Declarar

- **Nombre:** Respuesta rápida de la interfaz
- **Para quién:** Auxiliares atendiendo en fila y usuarios UTB en horas pico.
- **Qué problema resuelve:** Una interfaz lenta hace que el auxiliar abandone el registro a
  mitad de camino.

## A-04 · Declarar

- **Nombre:** Estabilidad con muchos usuarios simultáneos
- **Para quién:** Todo el campus, especialmente en inicio de semestre.
- **Qué problema resuelve:** Si el sistema se satura cuando muchos piden equipos a la vez, el
  registro queda incompleto.

## A-05 · Declarar

- **Nombre:** Control de acceso por rol
- **Para quién:** Auxiliares (administran el catálogo) vs. usuarios UTB (solo consultan y
  solicitan).
- **Qué problema resuelve:** Sin control de acceso, cualquier usuario podría alterar el
  catálogo o el estado de recursos que no le corresponden.

## A-06 · Declarar

- **Nombre:** Confiabilidad del estado de recursos y préstamos
- **Para quién:** Auxiliares y usuarios UTB — todos dependen de que el estado mostrado
  (disponible/prestado/dañado) sea siempre el real.
- **Qué problema resuelve:** El problema central del sistema (documento de idea, sección 2):
  hoy no hay un registro confiable de qué equipo está disponible. Si el sistema permite que dos
  préstamos coincidan sobre el mismo recurso, no mejora nada frente al proceso manual actual.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| **A-01** | Formularios intuitivos | Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0002](adr/0002-cambio-stack-fastapi-flutter.md) | `app/schemas/schemas.py`, `app/schemas/auth.py` | `tests/test_contract.py` (2 pruebas en verde) | Contrato OpenAPI congelado en `docs/contracts/openapi.json` con validación estricta de esquemas de formulario |
| **A-02** | Acceso durante horario del campus | Disponibilidad — [QS-01](arc42/arc42.md#qs-01--disponibilidad) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md) | `app/routers/health.py::health_check` | `app/tests/test_main.py` (en verde) | Health check profundo contra PostgreSQL (`SELECT 1`) y servicio systemd en Linux con reinicio automático |
| **A-03** | Respuesta rápida | Rendimiento (tiempo) — [QS-02](arc42/arc42.md#qs-02--rendimiento-tiempo-de-respuesta) | C1, C2 | [ADR-0002](adr/0002-cambio-stack-fastapi-flutter.md) | `app/main.py::logging_middleware`, FastAPI ASGI | `tests/test_loans.py`, `tests/test_resources.py` | Middleware con medición de latencia en milisegundos (`latency_ms`) en cada petición HTTP |
| **A-04** | Estabilidad con concurrencia | Rendimiento (concurrencia) — [QS-03](arc42/arc42.md#qs-03--rendimiento-concurrencia) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0005](adr/0005-monolito-vs-microservicios.md) | `app/core/database.py`, `app/core/resilience.py`, `app/main.py` | `tests/test_performance.py`, `tests/test_resilience.py` | Pool resiliente (`pool_pre_ping`, timeouts) y decorador `@with_retry` con backoff y jitter |
| **A-05** | Control de acceso por rol | Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad) | C1, C2 | [ADR-0004](adr/0004-seguridad-jwt.md) | `app/routers/auth.py`, `app/services/auth.py`, `app/core/hashing.py`, `app/core/security.py` | `tests/test_auth.py` (8 pruebas en verde) | Emisión y verificación de tokens JWT HS256, hashing irreversible con `bcrypt` (sin texto plano), control de roles |
| **A-06** | Confiabilidad del estado de recursos y préstamos | Confiabilidad de los datos — [QS-06](arc42/arc42.md#qs-06--confiabilidad-de-los-datos) | C1, C2, C3 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0003](adr/0003-integracion-sincrona.md) | `app/routers/loans.py`, `app/services/loans.py`, `app/models/recurso_models.py` | `tests/test_loans.py`, `tests/test_resilience.py` (idempotencia y locking) | Regla de negocio QS-06: bloqueo pesimista `.with_for_update()` e idempotencia vía `X-Idempotency-Key` |



---

## Especificar (escenarios medibles)

Los 6 escenarios de calidad (QS-01 a QS-06) están definidos en `docs/arc42.md`, sección
"Requisitos de calidad". A-06 es el primer aspecto de esta tabla que recorre la cadena
completa — desde el requisito hasta la evidencia de prueba real — porque es el que tiene el
corte vertical de esta entrega (S4) detrás. Los demás aspectos avanzan en las siguientes
entregas a medida que se implementen sus módulos correspondientes.

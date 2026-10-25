# ADR-0006: Mensajería Asíncrona con Transactional Outbox para Notificaciones de Préstamos

## Estado

Aceptado

## Fecha

25 de octubre de 2026

## Contexto

El sistema UTB Tracker implementa la regla central de negocio de préstamos de recursos de forma síncrona y transaccional (ADR-0003, ADR-0005): cuando un usuario solicita un préstamo (`POST /prestamos`), el servicio valida el estado del recurso con bloqueo pesimista de fila (`.with_for_update()`), cambia su estado a "prestado" y registra el préstamo en una única transacción ACID en PostgreSQL.

Sin embargo, tras confirmarse un préstamo exitoso, surge la necesidad de notificar al usuario (vía correo electrónico). Integrar este envío externo de forma síncrona dentro del ciclo de la petición HTTP introduce serios riesgos arquitectónicos:
1. **Acoplamiento de disponibilidad:** Si el servicio SMTP o la pasarela de correo se cae o responde lento, el endpoint `POST /prestamos` fallaría o se bloquearía, degradando la disponibilidad del sistema (QS-01).
2. **Latencia del endpoint:** Una llamada SMTP o HTTP externa típicamente añade entre 200 ms y varios segundos a la respuesta HTTP, afectando el tiempo de respuesta (QS-02).
3. **Consistencia y problema de la "transacción dual":** Si el correo se envía primero y la transacción de BD falla, el usuario recibe un correo de un préstamo que nunca existió. Si la transacción de BD confirma primero y el proceso muere antes de enviar el correo, la notificación se pierde irremediablemente.

El [ADR-0003](0003-integracion-sincrona.md) ya anticipaba explícitamente esta situación en su sección de alternativas:
> *"Asíncrono para las notificaciones (correo de confirmación/recordatorio) mientras el resto sigue síncrono. Esta sí es una alternativa razonable a futuro... ese canal específico sí ameritaría su propio ADR evaluando asíncrono para esa pieza puntual — sin que eso cambie esta decisión para el resto de la API."*

## Decisión

Se decide implementar el patrón **Transactional Outbox** junto con un proceso consumidor desacoplado (**Worker**) para la entrega de notificaciones de eventos de dominio (`prestamo.creado`):

1. **Transactional Outbox (`mensajes_outbox`):** El servicio `crear_prestamo` inserta el registro del préstamo, actualiza el estado del recurso y escribe el evento de dominio en la tabla `mensajes_outbox` **dentro de la misma transacción ACID local** (`db.commit()`). Si la transacción hace rollback, no queda ningún mensaje espurio; si confirma, el mensaje queda garantizado en disco.
2. **Consumidor desacoplado (`app/messaging/worker.py`):** Un proceso worker independiente lee periódicamente (`WORKER_POLL_INTERVAL=5s`) los mensajes en estado `"pendiente"` cuyo `siguiente_intento <= ahora`, resuelve el correo del usuario, invoca al notificador externo y actualiza el estado del mensaje.
3. **Garantía de entrega At-Least-Once con Deduplicación en Consumidor:** La deduplicación evita reenvíos cuando el mensaje se reentrega DESPUÉS de que el commit (notificación procesada + estado "enviado") se confirmó; si el proceso muere entre notificador.enviar y ese commit, no queda ninguna marca y el correo puede enviarse dos veces (consecuencia asumida de at-least-once).
4. **Política de reintentos sin bloqueo (`time.sleep`):** Ante fallos del notificador externo, se aplica backoff exponencial con jitter:
   - Base: `2.0` s (`WORKER_BASE_DELAY`).
   - Máximo: `60.0` s (`WORKER_MAX_DELAY`).
   - Fórmula: `delay = min(60, 2 * 2^intentos) + uniform(0, delay * 0.1)`.
   - El worker no duerme su hilo: calcula el timestamp UTC del próximo intento y actualiza `siguiente_intento` en la base de datos, manteniéndose disponible para procesar otros mensajes.
5. **Dead Letter Queue (DLQ) en base de datos:** Si un mensaje alcanza el límite de intentos (`WORKER_MAX_INTENTOS=5`), pasa al estado `"muerto"` con la traza de error en `ultimo_error`, evitando bucles infinitos de reintento y permitiendo auditoría manual.

## Relación y Matización del ADR-0003

Este ADR **no revoca ni borra** el [ADR-0003](0003-integracion-sincrona.md), sino que lo **matiza y complementa**:
- La validación del recurso, el bloqueo pesimista y el registro del préstamo se mantienen **estrictamente síncronos** (el cliente recibe 201 o 409 de inmediato, garantizando QS-06).
- Únicamente los efectos colaterales secundarios (la notificación por correo) se desacoplan de forma **asíncrona**, eliminando la dependencia de servicios externos dentro del request HTTP.

## Alternativas Evaluadas

| Criterio | Envío Síncrono en Request | `BackgroundTasks` de FastAPI | Broker Externo (RabbitMQ / Kafka) | Transactional Outbox (Seleccionada) |
|---|---|---|---|---|
| **Latencia del endpoint** | Alta (+200-2000 ms por SMTP) | Nula (responde inmediato) | Nula (publicación en broker < 5 ms) | Mínima (+1 INSERT local < 2 ms) |
| **Disponibilidad ante caída de correo** | Pésima (500 Internal Error) | Mala (se pierde la notificación) | Alta (persiste en cola) | Alta (persiste en `mensajes_outbox`) |
| **Riesgo de pérdida de mensajes** | Bajo (si falla, aborta request) | **Crítico:** si el proceso cae antes de ejecutar la tarea en memoria, se pierde para siempre | Bajo (broker persistente) | Mínimo: el mensaje no se pierde mientras la fila del outbox persista en la base de datos; el riesgo que se acepta es el duplicado, no la pérdida. |
| **Complejidad operativa** | Mínima (0 infraestructura extra) | Mínima (en memoria de FastAPI) | **Alta:** requiere cluster RabbitMQ/Redis, monitoreo, puertos y credenciales | **Baja:** usa la misma PostgreSQL existente, sin dependencias externas |
| **Facilidad de prueba** | Fácil | Media | Difícil (requiere broker en CI) | **Excelente:** funciones puras con inyección de reloj y notificador simulado |

- **Por qué se descartó `BackgroundTasks` de FastAPI:** Aunque es trivial de programar, mantiene las tareas en la memoria volátil del proceso Uvicorn. Si el servidor se reinicia, se despliega una nueva versión o el proceso es terminado por el OOM-killer, todas las notificaciones pendientes se pierden de forma irrecuperable.
- **Por qué se descartó RabbitMQ / Redis:** A la escala actual de UTB Tracker (máximo 300 usuarios simultáneos en hora pico, QS-03), desplegar y mantener un broker de mensajería independiente aumentaría drásticamente la sobrecarga operativa de un equipo universitario de 4 integrantes (ADR-0005) sin aportar beneficios tangibles sobre una tabla en PostgreSQL.

## Consecuencias

### Positivas
- **Aislamiento de fallos:** Caídas prolongadas del servidor de correos no impiden a los auxiliares registrar préstamos en el campus.
- **Latencia constante:** La API responde en pocos milisegundos sin importar la lentitud del proveedor de correos.
- **Trazabilidad de punta a punta:** El `correlation_id` generado en el middleware HTTP viaja dentro del evento hasta el log del worker, permitiendo reconstruir la historia completa de cada notificación.
- **Persistencia garantizada de eventos:** El guardado del evento comparte la transacción del préstamo. Si el préstamo existe, el mensaje existe.

### Negativas y Límites Aceptados
- **Latencia de entrega:** La notificación no es instantánea; se entrega en el siguiente ciclo de polling del worker (típicamente entre 0 y 5 segundos).
- **Semántica At-Least-Once:** Si el worker muere justo después de llamar a `notificador.enviar()` y antes del `db.commit()` de `notificaciones_procesadas`, al reiniciarse se reenviará el correo. Este riesgo se asume como preferible a la pérdida del mensaje.
- **Sobrecarga de polling en BD:** El worker ejecuta consultas periódicas `SELECT ... WHERE estado = 'pendiente'`. A la escala de 300 usuarios del campus esto tiene un impacto despreciable, pero a escalas masivas requeriría `LISTEN/NOTIFY` de PostgreSQL o un broker dedicado.

## Conclusión basada en la Evidencia

Para la escala académica de UTB Tracker, la alternativa síncrona o un `BackgroundTasks` simple habrían bastado para una demostración mínima. Sin embargo, la implementación de **Transactional Outbox** resuelve de raíz el problema de consistencia transaccional y pérdida de datos ante caídas del servidor, sin asumir la complejidad de infraestructura de RabbitMQ, manteniendo el sistema robusto, testeable y alineado con los objetivos QS-01 y QS-06.

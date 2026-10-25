# Contrato de Evento de Dominio: `prestamo.creado` (Versión 1)

## 1. Identificación del Evento

- **Nombre del Evento (`tipo`):** `prestamo.creado`
- **Versión Actual (`version`):** `1`
- **Archivo de Definición:** [`app/messaging/events.py`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L21-L56)
- **Fecha de Congelación:** 25 de octubre de 2026

---

## 2. Estructura Canónica del Mensaje

El mensaje sigue el patrón **Envelope (Sobre) + Payload (Cuerpo de Negocio)**.

### 2.1 Campos del Sobre (`EventoPrestamoCreado`)

Definido en [`app/messaging/events.py:31-52`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L31-L52):

| Campo | Tipo | Obligatorio | Descripción | Ejemplo |
|---|---|---|---|---|
| `message_id` | `UUID` / `str` | Sí | Identificador único del mensaje; utilizado para deduplicación e idempotencia en consumidor | `"aece6f25-43cc-46ac-8218-3606273a26c0"` |
| `tipo` | `str` | Sí | Nombre calificado del evento en notación de punto | `"prestamo.creado"` |
| `version` | `int` | Sí | Versión del esquema del contrato (entero) | `1` |
| `correlation_id` | `str` | Sí | Identificador de correlación trazable a la petición HTTP originaria (`request_id`) | `"req-corr-001"` |
| `ocurrido_en` | `datetime` | Sí | Timestamp UTC en formato ISO 8601 en que se consumó el préstamo | `"2026-10-25T07:46:01.000000Z"` |
| `payload` | `object` (`PayloadPrestamoCreado`) | Sí | Objeto con los datos de negocio del evento | *(Ver tabla 2.2)* |

### 2.2 Campos del Payload (`PayloadPrestamoCreado`)

Definido en [`app/messaging/events.py:21-29`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L21-L29):

| Campo | Tipo | Obligatorio | Descripción | Ejemplo |
|---|---|---|---|---|
| `prestamo_id` | `int` | Sí | Identificador único del registro en la tabla `prestamos` | `1` |
| `usuario_id` | `int` | Sí | Identificador del usuario que tomó el préstamo | `1` |
| `recurso_id` | `int` | Sí | Identificador del recurso físico prestado | `1` |
| `fecha_devolucion_esperada` | `datetime` | Sí | Fecha y hora programada para la devolución del recurso (ISO 8601) | `"2026-10-30T18:00:00"` |

> **Nota sobre el destinatario:** El payload **no** transporta el correo electrónico del usuario para evitar acoplar datos sensibles o desactualizados. El consumidor resuelve el correo en tiempo de procesamiento consultando la base de datos a partir de `usuario_id` ([`app/messaging/worker.py:232`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L232)).

---

## 3. Ejemplo Real de Mensaje JSON

El siguiente es un mensaje real serializado conforme a las clases Pydantic y guardado en la columna `payload` de la tabla `mensajes_outbox`:

```json
{
  "message_id": "aece6f25-43cc-46ac-8218-3606273a26c0",
  "tipo": "prestamo.creado",
  "version": 1,
  "correlation_id": "req-corr-001",
  "ocurrido_en": "2026-10-25T07:46:01.000000Z",
  "payload": {
    "prestamo_id": 1,
    "usuario_id": 1,
    "recurso_id": 1,
    "fecha_devolucion_esperada": "2026-10-30T18:00:00"
  }
}
```

En la implementación actual del servicio [`app/services/loans.py:98-118`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/services/loans.py#L98-L118), la fila en `mensajes_outbox` almacena en sus columnas los metadatos del sobre (`message_id`, `tipo`, `version`, `correlation_id`) y en la columna `payload` (TEXT) el diccionario del cuerpo de negocio:
```json
{
  "prestamo_id": 1,
  "usuario_id": 1,
  "recurso_id": 1,
  "fecha_devolucion_esperada": "2026-10-30T18:00:00"
}
```
El worker soporta de manera transparente ambas variantes al deserializar con `json.loads` ([`app/messaging/worker.py:221-226`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L221-L226)).

---

## 4. Criterios de Compatibilidad y Evolución del Esquema

El sistema aplica la **Ley de Robustez de Postel**: *"Sé conservador en lo que envías, tolerante en lo que recibes"*.

### 4.1 Cambios Compatibles hacia Atrás (Aditivos)
- **Agregar campos nuevos opcionales:** Tanto `PayloadPrestamoCreado` como `EventoPrestamoCreado` configuran `model_config = ConfigDict(extra="ignore")` ([`app/messaging/events.py:23, 44`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L23)). Si un productor agrega un campo no reconocido (por ejemplo `"observaciones": "entregado con cargador"`), el consumidor procesa el mensaje sin fallar y descarta los campos desconocidos. Verificado en [`tests/test_messaging.py::test_tolerancia_a_campos_desconocidos_en_evento`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L292).

### 4.2 Cambios Rupturistas (Breaking Changes)
- Eliminar o renombrar cualquiera de los campos obligatorios existentes (`prestamo_id`, `usuario_id`, `recurso_id`).
- Cambiar el tipo de dato de un campo existente (por ejemplo, cambiar `prestamo_id` de entero a cadena alfanumérica).
- Modificar la semántica de los identificadores.

### 4.3 Política de Versiones no Soportadas
Si el consumidor recibe un mensaje cuya versión no está registrada en `VERSIONES_SOPORTADAS = frozenset({1})` ([`app/messaging/events.py:55`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L55)):
1. **No hay descarte silencioso:** El worker detecta la discrepancia ([`app/messaging/worker.py:185-198`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L185-L198)).
2. Emite un log de nivel `ERROR` con `VERSION_NO_SOPORTADA`.
3. Transiciona el mensaje en `mensajes_outbox` inmediatamente al estado `"muerto"`.
4. Almacena en `ultimo_error` la descripción clara del conflicto.
5. Verificado en [`tests/test_messaging.py::test_rechazo_explicito_si_version_de_contrato_no_soportada`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L320).

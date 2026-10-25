# Evidencia de Ejecución: Mensajería Asíncrona (Taller)

**Fecha:** 25 de octubre de 2026  
**Entorno de Ejecución:** Windows 11, PowerShell, Python 3.14.4, pytest 9.1.1, entorno virtual en `.\venv`.

---

## 1. Salidas Crudas de Comandos

### 1.1 Pruebas del Módulo de Mensajería (`tests/test_messaging.py`)

Comando ejecutado:
```powershell
.\venv\Scripts\python.exe -m pytest tests/test_messaging.py -v
```

Salida cruda del terminal:
```text
============================= test session starts =============================
platform win32 -- Python 3.14.4, pytest-9.1.1, pluggy-1.6.0 -- C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR\venv\Scripts\python.exe
cachedir: .pytest_cache
rootdir: C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR
plugins: anyio-4.14.2
collecting ... collected 12 items

tests/test_messaging.py::test_outbox_se_inserta_en_misma_transaccion_que_prestamo PASSED [  8%]
tests/test_messaging.py::test_rollback_no_deja_mensaje_en_outbox PASSED  [ 16%]
tests/test_messaging.py::test_worker_procesa_mensaje_exitosamente PASSED [ 25%]
tests/test_messaging.py::test_consumidor_idempotente_ante_reentrega PASSED [ 33%]
tests/test_messaging.py::test_reintentos_backoff_exponencial_sin_sleep PASSED [ 41%]
tests/test_messaging.py::test_mensaje_muerto_al_superar_max_intentos PASSED [ 50%]
tests/test_messaging.py::test_tolerancia_a_campos_desconocidos_en_evento PASSED [ 58%]
tests/test_messaging.py::test_rechazo_explicito_si_version_de_contrato_no_soportada PASSED [ 66%]
tests/test_messaging.py::test_trazabilidad_logs_correlation_id PASSED    [ 75%]
tests/test_messaging.py::test_idempotencia_http_con_x_idempotency_key PASSED [ 83%]
tests/test_messaging.py::test_desacoplamiento_temporal_sin_worker PASSED [ 91%]
tests/test_messaging.py::test_rollback_real_forzando_fallo_en_commit PASSED [100%]

============================== warnings summary ===============================
venv\Lib\site-packages\fastapi\testclient.py:1
  C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR\venv\Lib\site-packages\fastapi\testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
    from starlette.testclient import TestClient as TestClient  # noqa

tests/test_messaging.py::test_outbox_se_inserta_en_misma_transaccion_que_prestamo
tests/test_messaging.py::test_rollback_no_deja_mensaje_en_outbox
tests/test_messaging.py::test_worker_procesa_mensaje_exitosamente
tests/test_messaging.py::test_consumidor_idempotente_ante_reentrega
tests/test_messaging.py::test_idempotencia_http_con_x_idempotency_key
tests/test_messaging.py::test_desacoplamiento_temporal_sin_worker
tests/test_messaging.py::test_rollback_real_forzando_fallo_en_commit
  C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR\venv\Lib\site-packages\jwt\api_jwt.py:149: InsecureKeyLengthWarning: The HMAC key is 23 bytes long, which is below the minimum recommended length of 32 bytes for SHA256. See RFC 7518 Section 3.2.
    return self._jws.encode(

tests/test_messaging.py::test_outbox_se_inserta_en_misma_transaccion_que_prestamo
tests/test_messaging.py::test_outbox_se_inserta_en_misma_transaccion_que_prestamo
tests/test_messaging.py::test_rollback_no_deja_mensaje_en_outbox
tests/test_messaging.py::test_worker_procesa_mensaje_exitosamente
tests/test_messaging.py::test_consumidor_idempotente_ante_reentrega
tests/test_messaging.py::test_idempotencia_http_con_x_idempotency_key
tests/test_messaging.py::test_desacoplamiento_temporal_sin_worker
tests/test_messaging.py::test_rollback_real_forzando_fallo_en_commit
  C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR\venv\Lib\site-packages\jwt\api_jwt.py:370: InsecureKeyLengthWarning: The HMAC key is 23 bytes long, which is below the minimum recommended length of 32 bytes for SHA256. See RFC 7518 Section 3.2.
    decoded = self.decode_complete(

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
====================== 12 passed, 16 warnings in 14.41s =======================
```

---

### 1.2 Verificación del Ciclo de Vida de Alembic (`6c7d8e9f0a1b`)

Ejecutado sobre base SQLite aislada en `$env:TEMP\tractar_verify_migration.db`:
- Paso 2.1: Esquema base creado con `Base.metadata.create_all(engine)`.
- Paso 2.2: Sello inicial `alembic stamp 5b652dd28f00`.
- Paso 2.3: `alembic upgrade head` (aplica `6c7d8e9f0a1b`).
- Paso 2.4: Inspección de tablas creadas: `mensajes_outbox` y `notificaciones_procesadas`.
- Paso 2.5: `alembic downgrade -1` (revierte a `5b652dd28f00` y elimina tablas).
- Paso 2.6: `alembic upgrade head` (recrea tablas limpiamente).

Salida cruda del script de verificación:
```text
=== DB TEMPORAL: sqlite:///C:/Users/sebas/AppData/Local/Temp/tractar_verify_migration.db ===
Paso 2.1: Tablas base creadas: ['horarios', 'idempotencia_registros', 'prestamos', 'prestamos_salon', 'recursos', 'reportes', 'salones', 'usuarios']
Paso 2.2: alembic stamp 5b652dd28f00

INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running stamp_revision  -> 5b652dd28f00
Paso 2.3: alembic upgrade head

INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade 5b652dd28f00 -> 6c7d8e9f0a1b, add_mensajeria_outbox_and_notificaciones
Paso 2.4: Tablas tras upgrade: ['alembic_version', 'horarios', 'idempotencia_registros', 'mensajes_outbox', 'notificaciones_procesadas', 'prestamos', 'prestamos_salon', 'recursos', 'reportes', 'salones', 'usuarios']
  Columnas mensajes_outbox: ['id', 'message_id', 'tipo', 'version', 'payload', 'correlation_id', 'estado', 'intentos', 'siguiente_intento', 'ultimo_error', 'creado_en', 'procesado_en']
  Indices mensajes_outbox: ['ix_mensajes_outbox_id', 'ix_mensajes_outbox_message_id']
  Columnas notificaciones_procesadas: ['message_id', 'procesado_en']
  Indices notificaciones_procesadas: ['ix_notificaciones_procesadas_message_id']
Paso 2.5: alembic downgrade -1

INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running downgrade 6c7d8e9f0a1b -> 5b652dd28f00, add_mensajeria_outbox_and_notificaciones
  Tablas tras downgrade: ['alembic_version', 'horarios', 'idempotencia_registros', 'prestamos', 'prestamos_salon', 'recursos', 'reportes', 'salones', 'usuarios']
Paso 2.6: alembic upgrade head (recreación)

INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade 5b652dd28f00 -> 6c7d8e9f0a1b, add_mensajeria_outbox_and_notificaciones
  Tablas tras re-upgrade: ['alembic_version', 'horarios', 'idempotencia_registros', 'mensajes_outbox', 'notificaciones_procesadas', 'prestamos', 'prestamos_salon', 'recursos', 'reportes', 'salones', 'usuarios']
Base temporal borrada exitosamente.
```

---

### 1.3 Demostración de Punta a Punta (`scripts/demo_mensajeria.py`)

Comando ejecutado:
```powershell
.\venv\Scripts\python.exe scripts/demo_mensajeria.py
```

Salida cruda del terminal:
```text
======================================================================
 DEMOSTRACIÓN DE MENSAJERÍA ASÍNCRONA — UTB TRACKER
======================================================================

[OK] Base de datos temporal creada en: C:\Users\sebas\AppData\Local\Temp\tractar_demo_20261025024601.db

----------------------------------------------------------------------
 PARTE A: Publicación de préstamo SIN worker
----------------------------------------------------------------------
-> Préstamo creado exitosamente: ID=1, Estado=activo
-> Registro en mensajes_outbox:
   message_id     : aece6f25-43cc-46ac-8218-3606273a26c0
   correlation_id : req-corr-001
   tipo           : prestamo.creado (v1)
   estado         : pendiente
   intentos       : 0
   payload        : {"prestamo_id": 1, "usuario_id": 1, "recurso_id": 1, "fecha_devolucion_esperada": "2026-10-30T18:00:00"}

----------------------------------------------------------------------
 PARTE B y C: Reintentos (2 fallos simulados -> éxito) con logs de punta a punta
----------------------------------------------------------------------

[Ciclo Worker 1]
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 INTENTO_1 tipo=prestamo.creado prestamo_id=1 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 FALLO intento=1 error='[NotificadorSimulado] Fallo simulado (1 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 REPROGRAMADO siguiente_intento=2026-10-25T07:46:05.929292+00:00"}
-> Tras ciclo 1: estado=pendiente, intentos=1, prox_intento=2026-10-25T07:46:05.929292

[Ciclo Worker 2]
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 INTENTO_2 tipo=prestamo.creado prestamo_id=1 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 FALLO intento=2 error='[NotificadorSimulado] Fallo simulado (0 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 REPROGRAMADO siguiente_intento=2026-10-25T07:46:09.833675+00:00"}
-> Tras ciclo 2: estado=pendiente, intentos=2, prox_intento=2026-10-25T07:46:09.833675

[Ciclo Worker 3]
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 INTENTO_3 tipo=prestamo.creado prestamo_id=1 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[NotificadorSimulado] Notificación enviada — email=estudiante@utb.edu.co asunto='UTB Tracker — Préstamo registrado' envio_num=1"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 ENVIADO prestamo_id=1"}
-> Tras ciclo 3: estado=enviado, intentos=3, procesado_en=2026-10-25 07:46:10.833675
-> Registro de deduplicación creado: message_id=aece6f25-43cc-46ac-8218-3606273a26c0, procesado_en=2026-10-25 07:46:10.833675

----------------------------------------------------------------------
 PARTE D: Fallo permanente hasta agotar reintentos (estado 'muerto')
----------------------------------------------------------------------
-> Préstamo 2 creado: ID=2. Mensaje ID=b620488f-28e5-49eb-89a0-b2c87b903ff4 en outbox.
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq INTENTO_1 tipo=prestamo.creado prestamo_id=2 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq FALLO intento=1 error='[NotificadorSimulado] Fallo simulado (998 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq REPROGRAMADO siguiente_intento=2026-10-25T07:46:05.876768+00:00"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq INTENTO_2 tipo=prestamo.creado prestamo_id=2 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq FALLO intento=2 error='[NotificadorSimulado] Fallo simulado (997 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq REPROGRAMADO siguiente_intento=2026-10-25T07:46:10.235751+00:00"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq INTENTO_3 tipo=prestamo.creado prestamo_id=2 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq FALLO intento=3 error='[NotificadorSimulado] Fallo simulado (996 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq REPROGRAMADO siguiente_intento=2026-10-25T07:46:18.829047+00:00"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq INTENTO_4 tipo=prestamo.creado prestamo_id=2 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq FALLO intento=4 error='[NotificadorSimulado] Fallo simulado (995 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq REPROGRAMADO siguiente_intento=2026-10-25T07:46:35.658884+00:00"}
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq INTENTO_5 tipo=prestamo.creado prestamo_id=2 usuario_id=1"}
{"time":"2026-10-25T02:46:01","level":"WARNING","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq FALLO intento=5 error='[NotificadorSimulado] Fallo simulado (994 restantes)'"}
{"time":"2026-10-25T02:46:01","level":"ERROR","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=b620488f-28e5-49eb-89a0-b2c87b903ff4 correlation_id=req-corr-dlq MUERTO intentos=5 error='[NotificadorSimulado] Fallo simulado (994 restantes)'"}
-> Resultado final del mensaje 2:
   estado       : muerto
   intentos     : 5
   ultimo_error : [NotificadorSimulado] Fallo simulado (994 restantes)

----------------------------------------------------------------------
 PARTE E: Reentrega del mensaje 1 con deduplicación en consumidor
----------------------------------------------------------------------
-> Reintentando procesar mensaje 1 (message_id=aece6f25-43cc-46ac-8218-3606273a26c0)...
{"time":"2026-10-25T02:46:01","level":"INFO","logger":"utb_tracker.messaging.worker","msg":"[worker] message_id=aece6f25-43cc-46ac-8218-3606273a26c0 correlation_id=req-corr-001 DUPLICADO_DESCARTADO — mensaje ya procesado, omitiendo envío"}
-> Envíos realizados por el notificador: 0 (esperado: 0 por deduplicación)

======================================================================
 DEMOSTRACIÓN FINALIZADA CON ÉXITO
======================================================================
[OK] Base de datos temporal borrada: C:\Users\sebas\AppData\Local\Temp\tractar_demo_20261025024601.db
```

---

### 1.4 Resumen de la Suite Completa del Repositorio

Comando ejecutado:
```powershell
.\venv\Scripts\python.exe -m pytest -q
```

Salida cruda del terminal:
```text
FAILED app/tests/test_main.py::test_health_check - AssertionError: assert {'s...
FAILED tests/test_horarios.py::test_horario_mismo_dia_sin_cruce_acepta - asse...
2 failed, 59 passed, 84 warnings in 69.00s (0:01:08)
```
*(Nota: las 2 fallas corresponden a bugs preexistentes documentados en `app/tests/test_main.py` y `tests/test_horarios.py`; las 12 pruebas de mensajería y las 2 de contrato pasan al 100%).*

---

## 2. Matriz de Cumplimiento de Puntos del Taller

| # | Punto del Enunciado | Estado | Implementación / Evidencia (Rutas y Líneas) |
|---|---|---|---|
| **1** | **Contrato y compatibilidad** | Cumplido | - Definición de esquemas: [`app/messaging/events.py:21-56`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/events.py#L21-L56)<br>- Especificación completa: [`docs/mensajeria/contrato-prestamo-creado.md`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/docs/mensajeria/contrato-prestamo-creado.md)<br>- Prueba campos desconocidos: [`tests/test_messaging.py:292-318`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L292-L318)<br>- Prueba versión no soportada: [`tests/test_messaging.py:320-342`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L320-L342) |
| **2** | **Garantía de entrega y consecuencias** | Cumplido | - Transacción ACID compartida (Transactional Outbox): [`app/services/loans.py:82-121`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/services/loans.py#L82-L121)<br>- Modelos SQLAlchemy: [`app/messaging/models.py:25-87`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/models.py#L25-L87)<br>- Prueba outbox en misma transacción: [`tests/test_messaging.py:33-80`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L33-L80)<br>- Prueba rollback real en commit: [`tests/test_messaging.py:465-552`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L465-L552) |
| **3** | **Duplicados (idempotencia y deduplicación)** | Cumplido | - Deduplicación en consumidor: [`app/messaging/worker.py:200-218, 280-286`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L200-L218)<br>- Tabla `notificaciones_procesadas`: [`app/messaging/models.py:69-87`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/models.py#L69-L87)<br>- Prueba deduplicación: [`tests/test_messaging.py:164-215`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L164-L215)<br>- Prueba idempotencia HTTP `X-Idempotency-Key`: [`tests/test_messaging.py:376-424`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L376-L424) |
| **4** | **Reintentos, backoff y cola de fallidos** | Cumplido | - Configuración: [`app/messaging/worker.py:48-54`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L48-L54) (5 entregas en total; retrasos reales de 4s, 8s, 16s, 32s + jitter hasta 10%; base configurada 2.0s con exponente ya incrementado; max 60.0s)<br>- Cálculo de backoff sin sleep: [`app/messaging/worker.py:103-115`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L103-L115)<br>- Estado "muerto" (DLQ): [`app/messaging/worker.py:299-314`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L299-L314)<br>- Pruebas backoff y DLQ: [`tests/test_messaging.py:217-290`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L217-L290) |
| **5** | **Prueba automatizada de duplicado y fallo recuperable** | Cumplido | - Reentrega idempotente: [`tests/test_messaging.py:164-215`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L164-L215)<br>- Fallo recuperable con backoff: [`tests/test_messaging.py:217-258`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L217-L258) |
| **6** | **Métrica o log para seguir mensaje de punta a punta** | Cumplido | - Captura `request_id` en contexto: [`app/main.py:18, 59-77`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/main.py#L18)<br>- Inserción `correlation_id` en outbox: [`app/services/loans.py:86-96`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/services/loans.py#L86-L96)<br>- Emisión consistente en worker: [`app/messaging/worker.py:181-183, 243-247, 261-264, 272-276, 294-296, 310-313`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/app/messaging/worker.py#L181-L183)<br>- Pruebas de trazabilidad: [`tests/test_messaging.py:344-369, 554-585`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/tests/test_messaging.py#L554-L585) |
| **7** | **ADR contra alternativa síncrona** | Cumplido | - Documentado en [`docs/adr/0006-mensajeria-asincrona-outbox.md`](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/docs/adr/0006-mensajeria-asincrona-outbox.md), matizando explícitamente el [ADR-0003](file:///c:/Users/sebas/OneDrive/Desktop/Tractar/AS_202620_TRACTAR/docs/adr/0003-integracion-sincrona.md). |

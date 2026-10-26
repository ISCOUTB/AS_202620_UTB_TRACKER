# Estrategia de Consistencia de Datos por Operación — UTB Tracker

> **Documento verificado contra el código fuente del repositorio.**  
> Cada afirmación incluye su ubicación exacta (`archivo:línea`).  
> Las mejoras a brechas y características no existentes se identifican explícitamente como **DISEÑO PROPUESTO — NO IMPLEMENTADO**.

---

## 1. Niveles de Consistencia y Definiciones

Para clasificar rigurosamente las operaciones de UTB Tracker, se definen los siguientes cinco niveles de garantía, adaptados a la arquitectura monolítica modular (`docs/adr/0001-estilo-arquitectonico.md`, `docs/adr/0005-monolito-vs-microservicios.md`):

1. **Fuerte con bloqueo pesimista (`with_for_update`):**  
   Garantizada mediante cerrojo de fila a nivel de base de datos (`SELECT ... FOR UPDATE`) dentro de una transacción ACID. Asegura exclusión mutua estricta: ninguna otra transacción concurrente puede leer ni modificar la entidad bloqueada hasta que la transacción activa haga `commit` o `rollback`. Es el nivel requerido para la protección de invariantes con alta contención (QS-06).
2. **Fuerte por restricción en BD (`UNIQUE`, `PRIMARY KEY`, `NOT NULL`, `FOREIGN KEY`):**  
   Garantizada por las restricciones declarativas del motor relacional PostgreSQL. Si dos transacciones intentan violar la invariante concurrentemente, el motor serializa la comprobación en el índice y rechaza una de ellas con un error de integridad (`IntegrityError`), sin importar la sincronización del código de aplicación.
3. **"Comprobar y luego escribir" (*Check-then-act*) sin garantía bajo concurrencia:**  
   Patrón donde la aplicación ejecuta una consulta de lectura en Python (`SELECT`), evalúa una regla de negocio en memoria (`if`), y posteriormente ejecuta una escritura (`INSERT` o `UPDATE`) en transacciones que no bloquean la fila ni cuentan con una restricción de exclusión en base de datos. Bajo peticiones concurrentes, múltiples hilos leen el mismo estado antes de que el primero escriba, provocando condiciones de carrera e inconsistencias lógicas.
4. **Eventual acotada por TTL (Caché propuesta):**  
   Garantía donde las consultas leen datos de una réplica volátil en memoria. La vista leída puede diferir del estado primario en base de datos, pero la divergencia temporal está estrictamente acotada por el tiempo de vida (TTL) configurado. (DISEÑO PROPUESTO — NO IMPLEMENTADO).
5. **At-least-once (Al menos una vez):**  
   Garantía de entrega asíncrona respaldada por persistencia transaccional en tabla outbox (`mensajes_outbox`) y reintentos con backoff exponencial. Se garantiza que el mensaje nunca se pierde ante caídas de red o del notificador externo, con el compromiso aceptado de potenciales entregas duplicadas mitigadas mediante deduplicación.

---

## 2. Matriz de Operaciones y Garantías de Consistencia

A continuación se detalla cada operación del sistema, su escenario de calidad asociado en `docs/arc42/arc42.md` (utilizando exclusivamente los identificadores formales QS-01 a QS-06), la garantía requerida, el mecanismo real implementado y la brecha verificada en el código.

| Operación | Escenario de calidad | Garantía que requiere | Mecanismo real (archivo:línea) | Brecha verificada |
|---|---|---|---|---|
| **POST /auth/register** | QS-04 (Seguridad) | Fuerte por restricción en BD | `app/services/auth.py:26-38`, `app/models/auth_models.py:19-20` | `Usuario.email` tiene `unique=True` en BD (`auth_models.py:20`), pero `Usuario.nombre` es solo `Column(String, nullable=False)` (`auth_models.py:19`). La unicidad de `nombre` solo se valida en Python (`auth.py:26`); dos registros concurrentes con el mismo nombre se insertan en BD. |
| **POST /resources** | QS-04 (Seguridad) | Fuerte por transacción ACID | `app/services/resources.py:32-48`, `app/routers/resources.py:34` | Autorización `AdminUser` requerida. No existe restricción de unicidad en `Recurso.nombre` (`app/models/recurso_models.py:23`); permite recursos homónimos en el mismo salón. |
| **PUT /resources/{id}** | QS-04 (Seguridad) | Fuerte por transacción ACID | `app/services/resources.py:53-73`, `app/routers/resources.py:58` | Check-then-act. No implementa control de concurrencia optimista (sin columna de versión) ni bloqueo pesimista; actualizaciones concurrentes provocan sobreescritura ciega (*lost update*). |
| **DELETE /resources/{id}** | QS-04 (Seguridad) | Fuerte por transacción ACID | `app/services/resources.py:78-98`, `app/routers/resources.py:90` | Soft-delete marcando `activo = False`. No verifica en base de datos si el recurso tiene préstamos en estado `'activo'` antes de desactivarlo. |
| **POST /resources/{id}/reportar** | QS-05 (Usabilidad), QS-06 (Confiabilidad) | Fuerte con bloqueo pesimista | `app/services/resources.py:103-128` | Check-then-act sin bloqueo. Consulta el recurso por ID y cambia `estado = "dañado"`. Si ocurre en paralelo a `crear_prestamo`, no hay serialización garantizada sobre el recurso. |
| **POST /prestamos** | QS-06 (Confiabilidad de los datos), QS-03 (Rendimiento concurrencia) | Fuerte con bloqueo pesimista | `app/services/loans.py:46-139` | Bloqueo pesimista `query.with_for_update()` en `loans.py:58` ejecutado condicionalmente en dialectos distintos a SQLite (`loans.py:54-60`). En una única transacción local (`loans.py:132-133`) actualiza recurso, crea préstamo e inserta outbox. En SQLite local no bloquea (ver Brechas). |
| **PATCH /prestamos/{id}/devolver** | QS-06 (Confiabilidad de los datos) | Fuerte con bloqueo pesimista | `app/services/loans.py:146-172` | **Check-then-act sin bloqueo.** Consulta `db.query(Prestamo).filter(id == prestamo_id).first()` (`loans.py:153-155`) sin `.with_for_update()`. Verifica `if prestamo.estado == "devuelto": raise 409`. Dos peticiones paralelas superan la comprobación y ambas marcan devuelto y restauran recurso. |
| **POST /salones** | QS-04 (Seguridad) | Fuerte por restricción en BD | `app/services/salones.py:26-44`, `app/models/salon_models.py:29` | Protegido por restricción `Column(String, unique=True, index=True)` en `Salon.codigo` (`salon_models.py:29`). Transacción atómica en `salones.py:41`. |
| **PUT /salones/{id}** | QS-04 (Seguridad) | Fuerte por transacción ACID | `app/services/salones.py:49-74` | Check-then-act. Valida colisión de código en Python (`salones.py:56-62`) antes de actualizar; la BD respalda unicidad de código pero no previene *lost updates* concurrentes. |
| **DELETE /salones/{id}** | QS-04 (Seguridad) | Fuerte por transacción ACID | `app/services/salones.py:79-99` | Borrado en BD sin validar si el salón posee recursos asignados activos o préstamos de salón pendientes/aprobados. |
| **POST /horarios** | QS-06 (Confiabilidad de los datos), QS-04 (Seguridad) | Fuerte con exclusión temporal | `app/services/horarios.py:27-58`, `app/services/horarios.py:89-106` | **Check-then-act sin bloqueo.** Ejecuta `_validar_solapamiento` en Python (`horarios.py:89-106`). No existe bloqueo de fila ni restricción de rango (`EXCLUDE USING gist`) en `HorarioDisponibilidad` (`app/models/salon_models.py:53-65`). Solicitudes concurrentes insertan horarios solapados. |
| **POST /horarios/bulk** | QS-06 (Confiabilidad de los datos), QS-04 (Seguridad) | Fuerte con exclusión temporal | `app/services/horarios.py:59-86` | **Check-then-act sin bloqueo.** Valida solapamientos iterativamente en memoria (`horarios.py:68-75`) antes del `db.commit()`. Susceptible a inserciones cruzadas de otros clientes. |
| **POST /prestamos-salon** | QS-06 (Confiabilidad de los datos), QS-03 (Rendimiento concurrencia) | Fuerte con exclusión o bloqueo | `app/services/prestamos_salon.py:38-78`, `app/services/prestamos_salon.py:114-138` | **Check-then-act sin bloqueo.** Consulta cruce de fechas en Python (`_validar_cruce_fechas` en `prestamos_salon.py:114-138`). No usa `with_for_update()` ni restricción de exclusión en `PrestamoSalon` (`app/models/salon_models.py:70-85`). Dos reservas concurrentes para el mismo salón y rango horario se aceptan simultáneamente. |
| **PATCH /prestamos-salon/{id}** | QS-06 (Confiabilidad de los datos) | Fuerte con bloqueo pesimista | `app/services/prestamos_salon.py:82-111` | Check-then-act sin bloqueo. Lee el préstamo de salón, valida transición de estado en Python y ejecuta `db.commit()`. Sin bloqueo de fila. |
| **Notificación outbox** | QS-06 (Confiabilidad), QS-01 (Disponibilidad) | At-least-once con deduplicación | `app/services/loans.py:117-133`, `app/messaging/worker.py:65-171` | Inserción en `mensajes_outbox` en la misma transacción ACID del préstamo (`loans.py:132`). Procesamiento desacoplado por worker con reintentos y registro en `notificaciones_procesadas`. (Ver sección 3). |
| **Grupo de Lecturas (Catálogo, recursos, salones, disponibilidad)** | QS-02 (Rendimiento ≤ 3s), QS-03 (Concurrencia 300 usuarios) | Lectura transaccional `READ COMMITTED` | `app/services/resources.py:15-28`, `app/services/salones.py:14-22`, `app/services/horarios.py:14-24` | Lecturas directas al motor relacional en cada petición HTTP. **No existe caché implementada.** En horas pico (300 usuarios simultáneos, QS-03), satura el pool de PostgreSQL. |

---

## 3. Garantías del Flujo por Eventos (Transactional Outbox)

El flujo asíncrono para notificaciones de préstamos (`prestamo.creado`) se rige por las siguientes características verificadas en `app/messaging/`:

### 3.1 Entrega (At-Least-Once)
- La publicación del evento no ocurre por red en el request HTTP, sino mediante un `INSERT` en la tabla `mensajes_outbox` dentro del mismo bloque transaccional del préstamo (`app/services/loans.py:117-133` y `app/messaging/service.py:19-48`).
- Al ejecutarse `db.commit()` (`loans.py:132`), la creación del préstamo, el cambio de estado del recurso a `"prestado"` y el registro del outbox quedan atómicamente confirmados o abortados.
- El worker de mensajería (`app/messaging/worker.py:65-171`) sondea la tabla periódicamente (`WORKER_POLL_INTERVAL = 5.0` s) y reintenta con backoff exponencial ante fallos hasta un límite de 5 intentos (`WORKER_MAX_INTENTOS = 5`), pasando a estado `"muerto"` (DLQ) si se agota.

### 3.2 Duplicados
- La garantía de entrega es **al menos una vez (at-least-once)**.
- Se implementa una tabla de deduplicación en el consumidor (`notificaciones_procesadas`, `app/messaging/models.py:76-88`).
- **Escenario de duplicación verificado:** Si el worker invoca con éxito al notificador externo (`app/messaging/worker.py:100`), pero el proceso muere, pierde conexión con la BD o se reinicia **antes** de ejecutar la transacción de confirmación (`db.add(procesado)` y `db.commit()` en `worker.py:114-117`), el mensaje permanecerá en estado `"pendiente"`. Al recuperarse, otro ciclo del worker volverá a enviar el correo al usuario. Este riesgo se asume como inherente al desacoplamiento at-least-once sin transacción distribuida de dos fases (2PC).

### 3.3 Orden de Entrega: SIN GARANTÍA DE ORDEN
- En `app/messaging/worker.py:65-72`, la consulta de mensajes pendientes aplica el filtro:
  ```python
  # app/messaging/worker.py:66-72
  query = (
      db.query(MensajeOutbox)
      .filter(
          MensajeOutbox.estado == "pendiente",
          MensajeOutbox.siguiente_intento <= ahora,
      )
      .order_by(MensajeOutbox.creado_en)
      .limit(batch_size)
  )
  ```
- **Declaración formal:** El sistema ofrece **SIN GARANTÍA DE ORDEN DE ENTREGA**.  
  *Justificación técnica:* El ordenamiento por `creado_en` solo opera sobre el subconjunto de mensajes cuyo `siguiente_intento <= ahora`. Si un mensaje antiguo $M_1$ (creado a las 10:00) falla temporalmente y entra en backoff con `siguiente_intento` programado para las 10:02, y posteriormente a las 10:01 se crea un mensaje nuevo $M_2$ con `siguiente_intento` inmediato (10:01), el worker procesará $M_2$ a las 10:01 y $M_1$ a las 10:02. Por ende, los mensajes no se entregan estrictamente en orden cronológico de generación.

### 3.4 Concurrencia entre Múltiples Workers: AUSENCIA DE `SKIP LOCKED`
- La consulta del worker (`app/messaging/worker.py:65-72`) **no utiliza bloqueo de fila ni `SKIP LOCKED`** (`.with_for_update(skip_locked=True)` no existe en el módulo de mensajería).
- Si se ejecutan dos o más instancias concurrentes de `app/messaging/worker.py`, ambas leerán simultáneamente los mismos registros pendientes en su lote y ejecutarán llamadas redundantes al notificador, duplicando notificaciones al usuario y colisionando al insertar en `notificaciones_procesadas` por su clave primaria (`message_id`).

### 3.5 Despliegue del Worker en el Entorno Real
- **Despliegue automático (`.github/workflows/ci.yml:68`):** El paso de deploy ejecuta únicamente:
  ```bash
  alembic upgrade head
  sudo systemctl restart utb-tracker
  ```
- **Script local (`run.sh:19`):** Ejecuta únicamente:
  ```bash
  ./venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
  ```
- **Hallazgo verificado:** El proceso del worker (`python -m app.messaging.worker`) **no está integrado en el despliegue automático ni en el script de arranque**. En producción actual, el servicio `utb-tracker` aloja únicamente la API web Uvicorn; el worker de mensajería debe iniciarse y supervisarse de forma manual o mediante una unidad systemd independiente no definida en el repositorio.

---

## 4. Brechas Conocidas y Mejoras Propuestas

Todas las mejoras en esta sección corresponden a **DISEÑO PROPUESTO — NO IMPLEMENTADO**.

### Brecha B-01: Doble Reserva Concurrente de Salones
- **Evidencia en código:** `app/services/prestamos_salon.py:38-78` y función `_validar_cruce_fechas` (`prestamos_salon.py:114-138`).
- **Condición:** Dos peticiones `POST /prestamos-salon` para el mismo salón en el mismo intervalo de fecha/hora son leídas simultáneamente en memoria antes del `db.commit()`, autorizando dos reservas solapadas sobre el mismo espacio físico.
- **Mejora propuesta (DISEÑO PROPUESTO — NO IMPLEMENTADO):**  
  Implementar una restricción de exclusión a nivel de PostgreSQL en `app/models/salon_models.py` utilizando la extensión `btree_gist`:
  ```sql
  -- Requiere CREATE EXTENSION btree_gist;
  ALTER TABLE prestamos_salon ADD CONSTRAINT excluir_solapamiento_salon 
  EXCLUDE USING gist (salon_id WITH =, tsrange(fecha_inicio, fecha_fin) WITH &&)
  WHERE (estado IN ('pendiente', 'aprobado'));
  ```
  Alternativamente, bloquear el salón con `db.query(Salon).filter(Salon.id == salon_id).with_for_update()` antes de validar y registrar la reserva.

### Brecha B-02: Inserción de Horarios Solapados
- **Evidencia en código:** `app/services/horarios.py:27-58` y `app/services/horarios.py:89-106`.
- **Condición:** La validación de superposición horaria (`hora_inicio` y `hora_fin` en un `dia_semana`) se ejecuta en memoria mediante consulta ordinaria. Dos llamadas concurrentes insertan bloques solapados para el mismo salón.
- **Mejora propuesta (DISEÑO PROPUESTO — NO IMPLEMENTADO):**  
  Crear una restricción de exclusión PostgreSQL en `horarios_disponibilidad`:
  ```sql
  ALTER TABLE horarios_disponibilidad ADD CONSTRAINT excluir_solapamiento_horario
  EXCLUDE USING gist (salon_id WITH =, dia_semana WITH =, numrange(EXTRACT(EPOCH FROM hora_inicio), EXTRACT(EPOCH FROM hora_fin)) WITH &&);
  ```

### Brecha B-03: Doble Devolución de Préstamo (*Race Condition*)
- **Evidencia en código:** `app/services/loans.py:146-172`.
- **Condición:** `devolver_prestamo` lee el préstamo sin `.with_for_update()`. Dos peticiones simultáneas `PATCH /prestamos/{id}/devolver` superan la comprobación `if prestamo.estado == "devuelto":` en paralelo, actualizan `fecha_devolucion_real` y restauran el estado del recurso redundantemente.
- **Mejora propuesta (DISEÑO PROPUESTO — NO IMPLEMENTADO):**  
  Incorporar bloqueo pesimista en la consulta de préstamo:
  ```python
  # En app/services/loans.py:devolver_prestamo
  query = db.query(recurso_models.Prestamo).filter(recurso_models.Prestamo.id == prestamo_id)
  if db.bind and db.bind.dialect.name != "sqlite":
      query = query.with_for_update()
  prestamo = query.first()
  ```

### Brecha B-04: Registro de Nombres de Usuario Duplicados
- **Evidencia en código:** `app/models/auth_models.py:19` (`nombre = Column(String, nullable=False)` sin `unique=True`) y `app/services/auth.py:26-31`.
- **Condición:** Si dos usuarios se registran concurrentemente con el mismo nombre pero diferente correo, ambas comprobaciones en memoria pasan y la BD acepta ambos registros. Esto causa un fallo crítico en el inicio de sesión, ya que `login` en `app/services/auth.py:70` busca exclusivamente por nombre (`Usuario.nombre == schema.nombre`).
- **Mejora propuesta (DISEÑO PROPUESTO — NO IMPLEMENTADO):**  
  Modificar el modelo en `app/models/auth_models.py:19`:
  ```python
  nombre = Column(String, nullable=False, unique=True, index=True)
  ```
  y generar la migración de esquema correspondiente en Alembic.

### Brecha B-05: Inoperancia de Bloqueo Pesimista en Entornos SQLite
- **Evidencia en código:** `app/services/loans.py:54-60`:
  ```python
  if db.bind and db.bind.dialect.name != "sqlite":
      query = query.with_for_update()
  ```
- **Condición:** En entornos de desarrollo local o pruebas rápidas basadas en SQLite (`app/core/database.py:27`), `.with_for_update()` se desactiva deliberadamente porque SQLite no soporta bloqueos a nivel de fila (`FOR UPDATE`). Por lo tanto, las pruebas locales no verifican el aislamiento de concurrencia de QS-06.
- **Mejora propuesta (DISEÑO PROPUESTO — NO IMPLEMENTADO):**  
  Estandarizar los entornos de pruebas locales mediante contenedores de desarrollo con PostgreSQL idénticos al entorno de integración continua (`.github/workflows/ci.yml:11-28`).

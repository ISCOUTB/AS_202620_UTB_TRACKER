# Límites del Experimento: Mensajería Asíncrona

**Fecha:** 25 de octubre de 2026  
**Alcance:** Taller académico de mensajería asíncrona sobre la rama `feature/mensajeria-taller`.

---

## 1. Simplificaciones Asumidas en el Diseño

1. **Notificador Simulado (`NotificadorSimulado`):** En lugar de conectarse a un servidor SMTP real o proveedor SaaS (SendGrid/Amazon SES), se implementó un notificador que escribe en los logs del sistema e implementa inyección programada de fallos (`fallos_antes_de_exito`). El protocolo estructural `NotificadorBase` permite reemplazarlo sin tocar el worker.
2. **Polling a Base de Datos en lugar de Broker:** El transporte es una tabla relacional (`mensajes_outbox`) consultada periódicamente (`WORKER_POLL_INTERVAL=5s`) en lugar de RabbitMQ, Kafka o Amazon SQS.
3. **Instancia Única de Worker:** El punto de entrada CLI (`python -m app.messaging.worker`) está diseñado como un proceso monopunto con un bucle simple `while True:` que procesa secuencialmente en un único hilo.

---

## 2. Aspectos No Probados, Riesgos Técnicos y Verificación Parcial

1. **NO VERIFICADO EN POSTGRESQL; el pipeline de CI aún no ha ejecutado esta rama:** Las pruebas automatizadas corren exclusivamente sobre SQLite en desarrollo local. Dado que la rama `feature/mensajeria-taller` no ha sido subida al repositorio remoto, el pipeline de CI no ha ejecutado estas pruebas en PostgreSQL. Construcciones que difieren entre motores:
   - **Manejo de Fechas:** SQLite almacena datetimes como cadenas sin zona horaria (naive UTC). PostgreSQL diferencia entre `TIMESTAMP WITH TIME ZONE` y `WITHOUT TIME ZONE`, requiriendo normalización estricta (`ahora_naive`).
   - **Almacenamiento de Payload:** Columna `Text` en SQLite frente a tipos nativos `JSONB` de PostgreSQL.
2. **Worker Excluido del Despliegue Automático:** El pipeline de despliegue (`.github/workflows/ci.yml`) únicamente reinicia el servicio web principal `utb-tracker.service` (la API Uvicorn); no incluye ningún servicio ni configuración para arrancar o reiniciar el worker de mensajería (`python -m app.messaging.worker`) en producción.
3. **Uso del Reloj Real en Cálculo de Reintentos:** La función `_calcular_siguiente_intento` consulta directamente `datetime.now(timezone.utc)` del sistema en lugar de recibir el reloj inyectado `ahora`. Esto impide simular avances de tiempo controlados dentro de la función de cálculo sin alterar el reloj del sistema o manipular los objetos devueltos.
4. **Fragilidad Silenciosa en la Trazabilidad:** En `app/services/loans.py`, la resolución de `correlation_id` intenta importar `request_id_ctx` desde `app.main` dentro de un bloque `try/except` amplio (`except Exception: cid = "system"`). Si por algún error de contexto o importación circular la obtención falla, se genera silenciosamente un identificador aleatorio nuevo (`str(uuid.uuid4())[:8]`) que no corresponde a la petición HTTP, rompiendo la trazabilidad de punta a punta sin emitir ninguna alerta o advertencia.
5. **Concurrencia entre Múltiples Workers:** No se probó la ejecución de más de una instancia del worker en paralelo. Con varios workers simultáneos leyendo `mensajes_outbox`, dos procesos podrían tomar el mismo mensaje pendiente antes de que alguno lo marque, requiriendo `SELECT ... FOR UPDATE SKIP LOCKED` (disponible en PostgreSQL, pero no en SQLite).
6. **Preservación del Orden Estricto:** La política de reintentos con backoff altera el orden de entrega: si el mensaje A falla y se reprograma, un mensaje B posterior exitoso se entregará antes que A.

---

## 3. Hallazgo Técnico: Cadena de Migraciones Alembic Previa

- **Diagnóstico:** Ejecutar `alembic upgrade head` sobre una base de datos PostgreSQL/SQLite completamente vacía falla en la migración `5b652dd28f00` (aportada por otro integrante del equipo). Dicha migración intenta agregar columnas a tablas base (`salones`, `horarios`) asumiendo que ya existen, sin haberlas creado previamente en una migración `0001_initial`.
- **Límite:** Por directriz estricta del taller, no se alteró la migración `5b652dd28f00` ni su `down_revision`. Nuestra migración (`6c7d8e9f0a1b`) se verificó y funciona perfectamente una vez que el esquema base preexistente está en su lugar.

---

## 4. Requisitos para Transición a Producción

Para desplegar este mecanismo en un entorno institucional de producción se requeriría:
1. **Implementar adaptador SMTP / API institucional:** Conectar `NotificadorBase` con credenciales seguras vía variables de entorno.
2. **Control de Concurrencia en Worker:** Agregar `.with_for_update(skip_locked=True)` en la consulta de mensajes pendientes de `app/messaging/worker.py` para permitir escalar a múltiples réplicas del worker sin duplicidad.
3. **Índice Compuesto en BD:** Crear índice en `(estado, siguiente_intento)` sobre `mensajes_outbox` para mantener el polling eficiente cuando la tabla crezca a decenas de miles de registros.
4. **Métricas y Alertas:** Exponer contadores Prometheus para mensajes en estado `"muerto"` (DLQ) y alertar al equipo de operaciones si el número supera un umbral.
5. **Corrección de la Migración Base de Alembic:** Reestructurar la migración inicial del repositorio para que cree todas las tablas base (`usuarios`, `prestamos`, `recursos`) de forma determinística en bases de datos nuevas.

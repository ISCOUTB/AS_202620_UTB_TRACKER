# UTB Tracker · Guía de Entrega y Sustentación Final (3 Páginas)

**Sistema:** UTB Tracker (Administración y Solicitud de Salones)  
**Semestre:** 2026-20 · Arquitectura de Software · Universidad Tecnológica de Bolívar  
**URL de Producción (App Web Flutter):** [https://tractar.iscoutb.dev](https://tractar.iscoutb.dev)  
**URL de la API (Backend FastAPI):** [https://api-tractar.iscoutb.dev](https://api-tractar.iscoutb.dev) (Swagger: `/docs`, Salud: `/salud`)  
**APK Cliente Android:** Publicado en GitHub Releases (etiqueta final)  

---

## PÁGINA 1: Arquitectura Construida vs. Documentada (Correspondencia C4 & arc42)

### 1.1 Estilo Arquitectónico y Estructura en Código (Monolito Modular por Capas)
UTB Tracker implementa un **monolito modular con diseño guiado por capas** (ADR-0001, ADR-0005) desplegado en un VPS Linux (Ubuntu 24.04, Nginx como reverse proxy, Uvicorn bajo systemd y PostgreSQL 16 relacional). Se descartó microservicios para evitar la complejidad operativa y sobrecarga de latencia distribuida sin justificación de escala.

La correspondencia entre el diseño y el código es estricta (validada por `tests/test_erosion_capas.py`):
1. **Capa Adaptadores HTTP (`app/handler/`):** Controladores FastAPI que reciben DTOs validados con Pydantic (`app/schemas/`), resuelven inyección de dependencias (`Depends`) y autorizan por rol/permisos (ADR-0018).
2. **Capa Servicios de Dominio (`app/service/`):** Encapsula transacciones de base de datos, reglas de negocio de disponibilidad de salones, hashing con bcrypt nativo (ADR-0004), cálculo de ocupación y publicación en outbox.
3. **Capa Persistencia (`app/models/`):** Mapeo relacional SQLAlchemy 2.0 (`Usuario`, `Salon`, `Recurso`, `PrestamoSalon`, `Auditoria`, `MensajeOutbox`). Migraciones administradas con Alembic (`alembic upgrade head`).
4. **Worker Asíncrono (`app/messaging/worker.py`):** Proceso desacoplado que implementa el patrón **Transactional Outbox** (ADR-0006) para garantizar entrega at-least-once de correos (SMTP) y push (FCM) sin comprometer el tiempo de respuesta HTTP.

### 1.2 Mapeo C4 (Nivel 1 a Nivel 3)
* **Nivel 1 (Contexto · `docs/c4/c4_nivel1.md`):** Usuarios del campus (Estudiante, Auditor/Auxiliar y Administrador) interactúan con UTB Tracker; el sistema se integra externamente con el servidor de correo SMTP institucional y Firebase Cloud Messaging.
* **Nivel 2 (Contenedores · `docs/c4/C2.md`):** App Móvil (Flutter), API Backend (FastAPI), Worker de Mensajería (Python) y Base de Datos (PostgreSQL 16). Protocolos: HTTPS/JSON entre móvil y API; TCP/SQL mediante pool SQLAlchemy a la base de datos.
* **Nivel 3 (Componentes · `docs/c4/c4_nivel3.md`):** Descomposición interna de la API en Middleware estructurado (correlación por `request_id`), Routers de Dominio, Servicios de Lógica Transaccional, Repositorios ORM y publicador Outbox.

---

## PÁGINA 2: Evolución de Decisiones Arquitectónicas con Evidencia y Mediciones

El sistema evolucionó a lo largo de 16 semanas respondiendo a escenarios de calidad medibles ([arc42 §10](arc42/arc42.md#10-requisitos-de-calidad) y [docs/aspectos.md](aspectos.md)):

| Escenario / Requisito | Decisión Arquitectónica (ADR) | Medición / Evidencia en el Repositorio |
|---|---|---|
| **QS-01 · Disponibilidad** | Proceso systemd con auto-restart, health check profundo `/salud` contra PostgreSQL (`SELECT 1`). | Endpoint `GET /salud` responde HTTP 200 en `< 15 ms` en VPS (`tests/test_main.py`). |
| **QS-02 · Rendimiento (Latencia)** | Monolito ASGI con FastAPI + Uvicorn, logging middleware estructurado con `latency_ms` y `request_id`. | Peticiones de lectura responden con `latency_ms < 50 ms` promedio (ver logs de producción). |
| **QS-03 · Concurrencia** | Pool resiliente SQLAlchemy con `pool_pre_ping`, decorador `@with_retry` con backoff exponencial. | Informe `docs/calidad/medicion-qs03.md`: 300 peticiones concurrentes completadas con p95 de **2523 ms** (umbral máximo permitido: 3000 ms). |
| **QS-04 · Seguridad y Control de Acceso** | Hashing criptográfico `bcrypt` dinámico (ADR-0004), JWT stateless con `sub` como ID y versión de sesión (ADR-0014), matriz RBAC estricta (ADR-0018). | Matriz 100% verificada en `tests/test_matriz_permisos.py` y `tests/test_roles.py`. pip-audit sin vulnerabilidades conocidas. |
| **QS-05 · Usabilidad y Compatibilidad** | Contrato OpenAPI congelado (`docs/contracts/openapi.json`), respuestas 422 en español, App Flutter responsiva a 360 dp. | `tests/test_contract.py` en verde permanente (impide rupturas accidentales entre backend y frontend). |
| **QS-06 · Confiabilidad e Idempotencia** | Bloqueo pesimista de fila `.with_for_update()` en reservas concurrentes y soporte de cabecera `X-Idempotency-Key` (ADR-0001, ADR-0010). | `tests/test_resilience.py` y `tests/test_loans.py`: 0% duplicados ante 2 peticiones concurrentes (una obtiene 201 y la otra 409 Conflict). |
| **Evolución del Dominio (S14-S16)** | Retiro de préstamo individual de equipos fijos (ADR-0023); control exclusivo de salones, habilitación con motivo obligatorio y auditoría inmutable (ADR-0010, ADR-0017). | Migración Alembic `e1f2a3b4c5d6` aplicada en producción; 12 pruebas de inmutabilidad en `tests/test_auditoria.py`. |

---

## PÁGINA 3: Trade-offs, Modos de Fallo, Límites y Defensa en Vivo

### 3.1 Análisis de Trade-offs y Compromisos Asumidos
1. **Monolito Modular vs. Microservicios (ADR-0005):**  
   * *Compromiso:* Despliegue conjunto y escalamiento vertical inicial.  
   * *Beneficio:* Transacciones ACID nativas sin necesidad de Two-Phase Commit (2PC) ni orquestadores distribuidos; latencia entre módulos de 0 ms; simplicidad de CI/CD.
2. **Transactional Outbox vs. Colas Distribuidas Kafka/RabbitMQ (ADR-0006):**  
   * *Compromiso:* La tabla `mensajes_outbox` compite por I/O con las operaciones de negocio en PostgreSQL. Entrega *at-least-once* (posibles duplicados si el worker cae tras enviar y antes de marcar procesado).  
   * *Beneficio:* Cero infraestructura externa adicional (cero costo de clúster MQ); consistencia atómica entre el guardado de la solicitud y el encolado del correo.
3. **Bloqueo Pesimista (`FOR UPDATE`) vs. Optimista (Versionado):**  
   * *Compromiso:* Serialización temporal de transacciones concurrentes sobre el mismo salón.  
   * *Beneficio:* Garantía matemática absoluta contra colisiones de reserva (QS-06) sin requerir reintentos fallidos en el cliente.

### 3.2 Modos de Fallo, Límites del Sistema y Resiliencia
* **Caída del servicio SMTP o Firebase:** La API no se bloquea ni retorna error 500 al usuario. El evento queda en estado `pendiente` y el worker reintenta con backoff exponencial y jitter (ADR-0006, `app/service/resilience.py`).
* **Saturación de Conexiones a BD:** El pool de SQLAlchemy limita a 30 conexiones con timeout controlado. Ante fallo de BD, el Circuit Breaker entra en estado `OPEN` evitando saturar la infraestructura.
* **Límite de Rendimiento Identificado:** Bajo pruebas extremas de carga con 1 worker Uvicorn, 300 usuarios concurrentes alcanzan un p95 de 2523 ms (cercano al umbral de 3000 ms). Mitigación futura documentada: despliegue multi-worker (`gunicorn -k uvicorn.workers.UvicornWorker -w 4`) y caché TTL en memoria (`docs/datos/diseno-cache.md`).

### 3.3 Guía de Demostración para la Sustentación (Orientada a Escenarios de Calidad)
* **Demostración 1 (Disponibilidad y Conexión en Vivo · QS-01):**  
  Navegar a `https://api-tractar.iscoutb.dev/salud` para evidenciar estado `ok` y conexión viva a PostgreSQL.
* **Demostración 2 (Seguridad y Control de Acceso Granular · QS-04):**  
  Intentar acceder a `/salones/admin` o `/auditoria` con token de rol Estudiante en Swagger (`/docs`) y verificar rechazo `403 Forbidden` con mensaje descriptivo.
* **Demostración 3 (Confiabilidad y Prevención de Doble Reserva · QS-06):**  
  Enviar dos solicitudes idénticas con la misma clave `X-Idempotency-Key` o en el mismo intervalo de horario: la primera es aceptada y la segunda rechazada sin corromper el estado.
* **Demostración 4 (Auditabilidad Inmutable · Aspecto A-08):**  
  Realizar un cambio de estado en un salón o usuario y consultar `/auditoria` para mostrar el registro con timestamp, actor y diff (antes/después).

---

## Anexo: versión final 1.1.0 (2026-11-23)

| Tema | Decisión | Evidencia |
|---|---|---|
| Identidad y roles | Sin verificación de correo (el dominio `@utb.edu.co` ya es de la UTB); todo registro nace Estudiante y solo un administrador asigna roles a cuentas existentes; correo único y sin alias `+` | ADR-0024, `tests/test_roles_sin_verificacion.py`, `tests/test_correo_unico.py`, amenaza T-36 |
| Una sola fuente de verdad | La matriz rol → permisos vive en `app/middleware/matriz_permisos.json`; la app la recibe en `GET /auth/roles` y no tiene copia | ADR-0025, `tests/test_matriz_unica.py` |
| Datos de demostración | Equipos, horarios, solicitudes y reportes sobre los 59 salones del catálogo, marcados y repetibles; no crean salones | `docs/despliegue/demostracion.md`, `tests/test_demo_datos.py` |
| Marca | Logo de la UTB en toda la app | ADR-0026 |
| Calidad | SonarCloud: complejidad reducida; suite del backend y de la app en verde | `sonar-project.properties`, CI |

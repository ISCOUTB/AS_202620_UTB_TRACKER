# Diseño de Estrategia de Caché e Invalidación — UTB Tracker

> **ESTADO: DISEÑO PROPUESTO — NO IMPLEMENTADO EN EL REPOSITORIO.**  
> En el código fuente actual no existe ninguna capa de caché en memoria ni distribuida (`grep -rn "cache"` en `app/` no arroja mecanismos de caché de endpoints, únicamente decoradores estándar de configuración).  
> Este documento formula la propuesta técnica para mitigar la sobrecarga de consultas en horas pico (QS-02, QS-03).

---

## 1. Alcance y Reglas de Integridad

### 1.1 Regla Central de Oro (Aislamiento de Invariantes)
**Ninguna operación de escritura lee jamás de la capa de caché.**  
Toda operación que altere el estado (`POST /prestamos`, `PATCH /prestamos/{id}/devolver`, `POST /resources/{id}/reportar`, `POST /prestamos-salon`, etc.) ejecuta sus comprobaciones de invariantes directamente sobre la base de datos primaria en una transacción ACID con bloqueo pesimista o restricciones relacionales (`docs/datos/consistencia-por-operacion.md`).

*Consecuencia ante obsolescencia:* Si un usuario consulta una lista de recursos en caché que muestra un equipo como `"disponible"` cuando acaba de ser prestado, la interfaz móvil le permitirá presionar el botón de solicitud, pero la petición `POST /prestamos` fallará atómicamente en la API devolviendo `409 Conflict` (`app/services/loans.py:65`). La obsolescencia en la lectura solo degrada temporalmente la experiencia de usuario con un rechazo controlado, pero **nunca corrompe los datos ni genera sobre-préstamos** (QS-06).

### 1.2 Endpoints Incluidos en Caché
Se seleccionan exclusivamente endpoints de lectura de alta demanda y bajo ritmo de mutación:

1. `GET /resources`: Catálogo general de recursos (soporta filtros: `tipo`, `estado`, `salon_id`, `skip`, `limit`).
2. `GET /resources/{recurso_id}`: Detalle de recurso específico.
3. `GET /salones`: Listado de salones y aulas del campus (`skip`, `limit`).
4. `GET /salones/{salon_id}`: Información y capacidad de un salón específico.
5. `GET /salones/{salon_id}/disponibilidad`: Matriz de disponibilidad y horarios de un salón para una fecha dada.
6. `GET /horarios/{horario_id}`: Consulta de un bloque horario específico.
7. `GET /horarios/salon/{salon_id}`: Listado de horarios asignados a un aula.

### 1.3 Endpoints Excluidos de Caché
1. `GET /prestamos`: Excluido porque su contenido depende del contexto y privilegios del usuario autenticado (`CurrentUser`). Un usuario común solo ve sus préstamos activos (`app/services/loans.py:183`), mientras un auxiliar/administrador visualiza el historial general.
2. `GET /prestamos-salon`: Excluido por depender de la identidad y rol del usuario solicitante (`app/services/prestamos_salon.py:19`).
3. `GET /auth/me` y `GET /auth/user/{user_id}`: Excluidos por representar información de identidad y seguridad sensible.
4. `GET /salud`: Excluido deliberadamente porque implementa un sondeo de salud profundo (`deep health check`) que ejecuta `SELECT 1` activo sobre PostgreSQL (`app/routers/health.py:17-26`) para garantizar la medición de disponibilidad en QS-01.

---

## 2. Topología de Caché y Decisión de Ubicación

### 2.1 En Proceso vs. Redis Distribuido
- **Hallazgo de despliegue (V2):** En `run.sh:19`, Uvicorn corre como proceso individual en modo desarrollo. En producción, el script de CI (`.github/workflows/ci.yml:68`) ejecuta `sudo systemctl restart utb-tracker`. Dado que el repositorio no define el archivo de servicio systemd, el número de procesos en producción es **NO VERIFICADO**, pero comúnmente despliega entre 2 y 4 *workers* bajo Uvicorn/Gunicorn en máquinas virtuales (ej. Oracle Cloud Ampere A1, arc42 sección 7).
- **Decisión propuesta:** Adoptar una **caché en memoria de proceso** (mediante estructuras `cachetools.TTLCache` o diccionarios con timestamps en Python), descartando el despliegue de un clúster de Redis externo.  
  *Justificación:* A la escala de UTB Tracker (máximo 300 usuarios simultáneos, QS-03), incorporar Redis añadiría costos operativos, monitoreo de infraestructura y puntos únicos de fallo que contradicen la decisión de mantener el sistema como un monolito simple y económico (ADR-0005).

### 2.2 Comportamiento Multi-Proceso y Límite de Obsolescencia
Al usar caché en memoria de proceso bajo un servidor con múltiples procesos de Uvicorn:
- La invalidación provocada por una petición de escritura recibida en el *Proceso A* **no se propaga** a los procesos *B* o *C*.
- Los procesos *B* y *C* continuarán sirviendo respuestas cacheadas hasta que sus respectivos temporizadores de TTL expiren de forma natural.
- **Garantía formal:** La inconsistencia temporal entre diferentes procesos queda **estrictamente acotada por el TTL máximo declarado** (60 segundos para recursos, 120 segundos para salones). Ningún usuario percibirá datos con una antigüedad mayor al TTL bajo ninguna circunstancia.

---

## 3. Estructura de Claves y Validación de Autenticación

### 3.1 Formato Canónico de Claves
Para prevenir colisiones y evitar claves huérfanas por alteración del orden de parámetros en la URL, las claves se construyen normalizando la ruta y ordenando alfabéticamente los parámetros de consulta (*query params*):

$$\text{Clave} = \text{cache}:\{\text{grupo}\}:\text{v}\{\text{versión}\}:\{\text{path}\}:\{\text{query\_params\_ordenados}\}$$

Ejemplos:
- `cache:recursos:v1:/resources:limit=20&salon_id=2&skip=0&tipo=videobeam`
- `cache:recursos:v1:/resources/15:`
- `cache:salones:v1:/salones/3/disponibilidad:fecha=2026-10-26`

### 3.2 Secuencia de Consulta y Autenticación
Para endpoints que requieran autenticación (`CurrentUser` o `AdminUser`):
1. **Paso 1 (Autenticación y Autorización previa):** FastAPI ejecuta primero las dependencias de seguridad (`Depends(get_current_user)`). Si el token JWT es inválido, expiró o no cumple el rol requerido, la petición se aborta con `401 Unauthorized` o `403 Forbidden` (`app/core/security.py`).
2. **Paso 2 (Consulta de Caché):** Solo tras validar exitosamente el token, el interceptor de caché busca la clave correspondiente en memoria. Si existe (*cache hit*), retorna la respuesta serializada de inmediato (tiempo de respuesta < 5 ms, satisfaciendo ampliamente QS-02).
3. **Paso 3 (Fallo de caché y repoblación):** Si no existe (*cache miss*), la petición continúa a la base de datos, almacena el resultado en memoria con su TTL y retorna el HTTP 200.

---

## 4. Tiempos de Vida (TTL) y Cotas de Obsolescencia

| Endpoint | TTL Propuesto | Cota Máxima de Obsolescencia | Justificación |
|---|---|---|---|
| `GET /resources` (Catálogo general) | 60 segundos | 60 segundos | Alta frecuencia de consulta; ritmo moderado de préstamos. Un TTL de 1 min reduce ~90% de lecturas a BD en horas pico. |
| `GET /resources/{id}` (Detalle de recurso) | 60 segundos | 60 segundos | Coherente con el catálogo general. |
| `GET /salones` (Listado de salones) | 120 segundos | 120 segundos | Los salones físicos rara vez se crean, modifican o eliminan durante la jornada académica. |
| `GET /salones/{id}` (Detalle de salón) | 120 segundos | 120 segundos | Información estructural estática (nombre, capacidad, ubicación). |
| `GET /salones/{id}/disponibilidad` | 60 segundos | 60 segundos | Cambia únicamente cuando se crea una reserva de salón o se modifica un horario. |
| `GET /horarios/salon/{id}` | 120 segundos | 120 segundos | Horarios académicos semanales con mutación casi nula dentro del semestre. |

---

## 5. Política de Invalidación (Grupos de Versión)

En lugar de recorrer y eliminar individualmente cientos de combinaciones de claves al modificarse una entidad, se emplea el patrón de **Versionado por Espacio de Nombres (Namespace Versioning)**:
- Cada grupo de caché mantiene un entero de versión en memoria (`version_recursos = 1`, `version_salones = 1`).
- La clave incluye la versión activa del grupo (`cache:recursos:v1:...`).
- Para invalidar todo el grupo de forma instantánea ($O(1)$), simplemente se incrementa el contador (`version_recursos += 1`). A partir de ese instante, todas las búsquedas usarán `v2`, provocando *cache misses* controlados, mientras las entradas `v1` son descartadas automáticamente por la política de expiración o desalojo LRU de la memoria.

### Matriz de Escritura → Grupos Invalidados

Toda operación de escritura real del sistema detona la invalidación del grupo correspondiente:

| Operación de Escritura Real | Ubicación en Código | Grupo Invalidado | Razón de Dominio |
|---|---|---|---|
| `POST /resources` | `app/services/resources.py:32-48` | `recursos` | Nuevo recurso disponible en catálogo. |
| `PUT /resources/{id}` | `app/services/resources.py:53-73` | `recursos` | Modificación de nombre, tipo o asignación de salón. |
| `DELETE /resources/{id}` | `app/services/resources.py:78-98` | `recursos` | Desactivación lógica de un equipo. |
| `POST /resources/{id}/reportar` | `app/services/resources.py:103-128` | `recursos` | **El recurso cambia su estado a `'dañado'`.** Debe reflejarse en catálogo para no ofrecerlo. |
| `POST /prestamos` | `app/services/loans.py:46-139` | `recursos` | **El recurso cambia su estado a `'prestado'`.** Invalida el listado de disponibles. |
| `PATCH /prestamos/{id}/devolver` | `app/services/loans.py:146-172` | `recursos` | **El recurso cambia su estado a `'disponible'`.** Vuelve a habilitarse en el catálogo. |
| `POST /salones` | `app/services/salones.py:26-44` | `salones` | Nueva aula física agregada al campus. |
| `PUT /salones/{id}` | `app/services/salones.py:49-74` | `salones` | Modificación de código, capacidad o torre. |
| `DELETE /salones/{id}` | `app/services/salones.py:79-99` | `salones` | Eliminación de aula. |
| `POST /horarios` | `app/services/horarios.py:27-58` | `salones` | Altera la matriz de horarios y disponibilidad semanal del salón. |
| `POST /horarios/bulk` | `app/services/horarios.py:59-86` | `salones` | Inserción masiva de bloques horarios. |
| `PUT /horarios/{id}` | `app/services/horarios.py:89` | `salones` | Modificación de bloque horario. |
| `DELETE /horarios/{id}` | `app/services/horarios.py:109` | `salones` | Liberación de bloque horario. |
| `POST /prestamos-salon` | `app/services/prestamos_salon.py:38-78` | `salones` | Reserva de salón; altera el endpoint `/disponibilidad`. |
| `PATCH /prestamos-salon/{id}` | `app/services/prestamos_salon.py:82-111` | `salones` | Cancelación, rechazo o finalización de reserva de salón. |

---

## 6. Modos de Fallo, Telemetría y Pruebas

### 6.1 Modos de Fallo y Mitigaciones
1. **Reinicio del Proceso (*Cold Start*):**  
   Al desplegarse una nueva versión o reiniciarse el servicio (`sudo systemctl restart utb-tracker`), la memoria de caché arranca vacía. Las peticiones iniciales golpearán la base de datos.  
   *Mitigación:* La base de datos cuenta con índices B-Tree en todas las claves foráneas y columnas de filtro (`app/models/recurso_models.py`, `app/models/salon_models.py`), y el pool de conexiones SQLAlchemy está configurado con pre-ping (`app/core/database.py:20-25`), absorbiendo la carga inicial sin degradación.
2. **Avalancha de Peticiones al Expirar (*Cache Stampede / Thundering Herd*):**  
   Cuando la clave del catálogo general expira bajo una concurrencia de 300 usuarios simultáneos (QS-03), decenas de hilos podrían intentar recalcular la misma consulta SQL simultáneamente.  
   *Mitigación propuesta:* Incorporar cerrojos de ejecución única (*single-flight mutex / asyncio.Lock*) para que el primer hilo adquiera el candado y consulte a PostgreSQL, mientras los demás hilos esperan y consumen el resultado recién generado.
3. **Consumo Excesivo de Memoria RAM:**  
   Si se generan millones de combinaciones de parámetros de consulta arbitrarios.  
   *Mitigación:* Configurar un límite máximo estricto de elementos por caché (ej. `maxsize = 1000` entradas por grupo) gestionado con política de reemplazo LRU (*Least Recently Used*). 1000 entradas en memoria consumen menos de 10 MB de RAM.

### 6.2 Telemetría y Métricas Propuestas
La capa de caché se instrumentará en el middleware de observabilidad (`app/main.py:46-77`) registrando:
- `cache_hit_ratio = total_hits / (total_hits + total_misses)`: Objetivo ≥ 85% durante horario pico (QS-02).
- Latencia p95 con *hit* (< 5 ms) vs latencia p95 con *miss* (< 50 ms).
- Conteo de invalidaciones por hora según tipo de evento de escritura.

### 6.3 Estrategia de Pruebas
1. **Pruebas Unitarias de Invalidación (`tests/test_cache.py` - Propuesta):**  
   Verificar con inyección de reloj simulado que tras invocar `crear_prestamo` o `devolver_prestamo`, la siguiente llamada a `GET /resources` refleja el nuevo estado del recurso y la versión del grupo se incrementa.
2. **Pruebas de Concurrencia y Resiliencia (`tests/test_cache_concurrency.py` - Propuesta):**  
   Simular 50 peticiones simultáneas sobre una clave a punto de expirar verificando que la base de datos reciba exactamente 1 consulta gracias al mecanismo *single-flight*.

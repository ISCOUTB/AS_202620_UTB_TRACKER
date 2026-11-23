# Medición Empírica de Atributo de Calidad — Escenarios QS-03 y QS-02

> **Documento de evidencia técnica S14 — UTB Tracker.**  
> Resultados obtenidos a partir de la ejecución de carga concurrente sobre la API REST real contra PostgreSQL.  
> Toda cifra citada proviene de la salida cruda de los scripts de medición y siembra en el entorno local.

---

## 1. Escenarios de Calidad Evaluados (arc42 Sección 10)

Los escenarios fueron tomados textualmente de `docs/arc42/arc42.md` sección 10:

### QS-03 — Rendimiento (concurrencia)
- **Fuente:** Auxiliar o profesor/estudiante
- **Estímulo:** Múltiples usuarios usan el sistema al mismo tiempo (hora pico)
- **Ambiente:** Operación normal
- **Artefacto:** Backend / API de UTB Tracker
- **Respuesta:** El sistema procesa las solicitudes sin degradar el servicio
- **Medida:** Soporta al menos 300 usuarios simultáneos sin errores ni caídas

### QS-02 — Rendimiento (tiempo de respuesta)
- **Fuente:** Auxiliar o profesor/estudiante
- **Estímulo:** Abre la aplicación o navega a una nueva vista
- **Ambiente:** Operación normal, dispositivo conectado (probablemente) al internet del campus
- **Artefacto:** Servicio movil de UTB Tracker
- **Respuesta:** La vista carga y queda interactiva
- **Medida:** Tiempo de carga ≤ 3 segundos (3000 ms)

---

## 2. Método de Medición

La prueba evalúa el comportamiento del backend Uvicorn frente a ráfagas de usuarios simultáneos que consultan los datos del inventario y las aulas durante horas de alta demanda en el campus.

### 2.1 Scripts Utilizados
- **Siembra de base de datos (`scripts/sembrar_medicion.py`):**
  - Creación del esquema relacional completo con `Base.metadata.create_all()` (`scripts/sembrar_medicion.py:38`).
  - Poblado con volumen realista:
    - 3 usuarios institucionales con contraseña cifrada con `bcrypt` (1 por cada rol: `usuario_utb`, `auxiliar`, `administrador`, líneas 46-63).
    - 35 salones físicos distribuidos en 5 edificios y múltiples pisos (líneas 65-88).
    - Horarios académicos de lunes a viernes asignados a los salones (líneas 90-116).
    - 210 recursos físicos clasificados en 5 categorías (`video_beam`, `computador`, `aire_ac`, `tv`, `audio`) asignados a salones (líneas 118-135).
- **Ejecutor de carga concurrente (`scripts/medir_qs03.py`):**
  - Autenticación previa en `POST /auth/login` con el usuario sembrado para obtener el token Bearer JWT (`scripts/medir_qs03.py:25-45`).
  - Generación de hilos mediante `ThreadPoolExecutor` para simular usuarios concurrentes (`scripts/medir_qs03.py:99-112`).
  - Medición individual de cada petición HTTP mediante `time.perf_counter()` (`scripts/medir_qs03.py:53-64`).
  - Timeout por petición: **5.0 segundos** (`TIMEOUT_DEFAULT = 5.0` en `scripts/medir_qs03.py:22`).
  - Niveles de concurrencia evaluados: **50, 150 y 300 usuarios simultáneos**, con **2 corridas independientes por cada nivel** para observar variabilidad.

### 2.2 Endpoints Medidos
Las peticiones se distribuyeron equitativamente en round-robin entre los 3 endpoints de lectura de hora pico (`scripts/medir_qs03.py:85-89`):
1. `GET /recursos`: Catálogo general de equipos (`app/routers/resources.py:37`, montado en `app/main.py:85`).
2. `GET /salones`: Listado de aulas y salones (`app/routers/salones.py:31`, montado en `app/main.py:87`).
3. `GET /salones/1/disponibilidad?dia_semana=1`: Cruce de horarios y reservas del aula (`app/routers/salones.py:77`, montado en `app/main.py:87`).

### 2.3 Requisitos para Reproducir
- **Dependencias de los scripts:**
  - `scripts/medir_qs03.py`: Utiliza exclusivamente la biblioteca estándar de Python (`argparse`, `sys`, `time`, `concurrent.futures`, `urllib.request`, `urllib.error`, `json`). No requiere librerías externas de terceros como `requests`.
  - `scripts/sembrar_medicion.py`: Requiere `SQLAlchemy` (incluida en `requirements.txt`), los modelos de dominio y hashing del backend (`app.core.database`, `app.core.hashing`, `app.models.*`) y la variable de entorno `$env:PYTHONPATH = (Get-Location).Path` para la resolución de módulos internos.
- **Base de datos:** Requiere una base de datos PostgreSQL activa accesible mediante la variable de entorno `DATABASE_URL` (enmascarada como `postgresql+psycopg://postgres:***@localhost:5432/utb_tracker_medicion`).
- **Orden estricto de ejecución:**
  1. Configuración de variables de entorno (`DATABASE_URL` y `PYTHONPATH`).
  2. Ejecución de siembra con `scripts/sembrar_medicion.py`.
  3. Inicio del servidor Uvicorn en una terminal separada.
  4. Ejecución del script de carga con `scripts/medir_qs03.py`.

### 2.4 Comandos de Reproducción
```powershell
# 1. Exportar variables de entorno (enmascarada)
$env:DATABASE_URL = "postgresql+psycopg://postgres:***@localhost:5432/utb_tracker_medicion"
$env:PYTHONPATH = (Get-Location).Path

# 2. Inicializar esquema y sembrar datos
.\venv\Scripts\python.exe scripts/sembrar_medicion.py

# 3. Arrancar servidor API en terminal independiente
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# 4. Ejecutar suite de medición
.\venv\Scripts\python.exe scripts/medir_qs03.py
```

---

## 3. Entorno de Ejecución

- **Fecha y hora:** 2026-11-08 14:01:42 -05:00
- **Sistema Operativo:** Microsoft Windows 11 Home Single Language (NT 10.0.26200.0)
- **Hardware:** Procesador Intel(R) Core(TM) i5-12450H (12th Gen, 8 núcleos / 12 hilos lógicos), 7.70 GB de memoria RAM
- **Versión de Python:** Python 3.14.4 (intérprete en `venv/Scripts/python.exe`)
- **Motor de Base de Datos:** PostgreSQL 18.1 local. *(Nota: el pipeline de integración continua en `.github/workflows/ci.yml:14` utiliza PostgreSQL 16)*
- **Parámetros del pool de conexiones (`app/core/database.py:21-24`):**
  - `pool_size = 10`
  - `max_overflow = 20`
  - `pool_timeout = 30`
  - `pool_recycle = 1800`
  - Capacidad máxima concurrente del pool: **30 conexiones**.
- **Servidor Web:** Uvicorn con 1 worker (`--host 127.0.0.1 --port 8000`).
- **Topología de red:** El generador de carga y el servidor Uvicorn se ejecutaron en la misma máquina física (comunicación sobre interfaz de loopback `127.0.0.1`).

---

## 4. Resultados de la Medición

### 4.1 Resumen Tabular

| Concurrencia | Intento | Total Peticiones | Éxitos (200) | Errores / Caídas | p50 (ms) | p95 (ms) | p99 (ms) | Máximo (ms) | Throughput (Req/s) |
|---|---|---|---|---|---|---|---|---|---|
| **50 usuarios** | 1 | 50 | 50 | 0 | 598.75 | 754.17 | 762.64 | 762.64 | 60.9 |
| **50 usuarios** | 2 | 50 | 50 | 0 | 663.06 | 1042.28 | 1050.27 | 1050.27 | 45.4 |
| **150 usuarios** | 1 | 150 | 150 | 0 | 1316.69 | 2269.56 | 2295.33 | 2296.88 | 56.3 |
| **150 usuarios** | 2 | 150 | 150 | 0 | 1380.41 | 2449.13 | 2477.43 | 2479.55 | 56.4 |
| **300 usuarios** | 1 | 300 | 300 | 0 | 1434.07 | 2523.37 | 2584.95 | 2595.30 | 102.3 |
| **300 usuarios** | 2 | 300 | 300 | 0 | 1684.12 | 2916.04 | 2974.16 | **2975.91** | 90.0 |

### 4.2 Salida Cruda de la Terminal (`scripts/medir_qs03.py`)

```text
================================================================================
MEDICIÓN EMPÍRICA QS-03 — UTB Tracker
URL Base: http://127.0.0.1:8000
Niveles de concurrencia: [50, 150, 300]
Timeout por petición: 5.0 s
================================================================================
Obteniendo token de autenticación JWT...
Token obtenido con éxito. Iniciando corridas de medición...

--> Ejecutando corrida: 50 usuarios concurrentes (Intento 1/2)...
    Completado en 0.82s | Éxitos: 50/50 | Errores: 0 | p50: 598.75ms | p95: 754.17ms | p99: 762.64ms | max: 762.64ms      
--> Ejecutando corrida: 50 usuarios concurrentes (Intento 2/2)...
    Completado en 1.10s | Éxitos: 50/50 | Errores: 0 | p50: 663.06ms | p95: 1042.28ms | p99: 1050.27ms | max: 1050.27ms   
--> Ejecutando corrida: 150 usuarios concurrentes (Intento 1/2)...
    Completado en 2.67s | Éxitos: 150/150 | Errores: 0 | p50: 1316.69ms | p95: 2269.56ms | p99: 2295.33ms | max: 2296.88ms
--> Ejecutando corrida: 150 usuarios concurrentes (Intento 2/2)...
    Completado en 2.66s | Éxitos: 150/150 | Errores: 0 | p50: 1380.41ms | p95: 2449.13ms | p99: 2477.43ms | max: 2479.55ms
--> Ejecutando corrida: 300 usuarios concurrentes (Intento 1/2)...
    Completado en 2.93s | Éxitos: 300/300 | Errores: 0 | p50: 1434.07ms | p95: 2523.37ms | p99: 2584.95ms | max: 2595.30ms
--> Ejecutando corrida: 300 usuarios concurrentes (Intento 2/2)...
    Completado en 3.33s | Éxitos: 300/300 | Errores: 0 | p50: 1684.12ms | p95: 2916.04ms | p99: 2974.16ms | max: 2975.91ms

================================================================================
RESUMEN TABULAR DE RESULTADOS (SALIDA CRUDA)
================================================================================
Usuarios   Intento   Total    Éxitos   Errores  p50 (ms)   p95 (ms)   p99 (ms)   Max (ms)   Req/s
--------------------------------------------------------------------------------------------
50         1         50       50       0        598.75     754.17     762.64     762.64     60.9
50         2         50       50       0        663.06     1042.28    1050.27    1050.27    45.4
150        1         150      150      0        1316.69    2269.56    2295.33    2296.88    56.3
150        2         150      150      0        1380.41    2449.13    2477.43    2479.55    56.4
300        1         300      300      0        1434.07    2523.37    2584.95    2595.30    102.3
300        2         300      300      0        1684.12    2916.04    2974.16    2975.91    90.0
================================================================================
```

---

## 5. Veredicto Frente a los Escenarios de Calidad

| Escenario | Criterio de Aceptación (arc42) | Valor Real Medido | Veredicto |
|---|---|---|---|
| **QS-03** | Soporta al menos 300 usuarios simultáneos sin errores ni caídas | **0 errores en 300 peticiones** en intento 1 y 2 (100% éxito HTTP 200) | **CUMPLE** |
| **QS-02** | Tiempo de carga / respuesta ≤ 3.0 s (3000 ms) | **Máximo de 2975.91 ms** en intento 2 de 300 usuarios (p95: 2916.04 ms) | **CUMPLE POR MARGEN MÍNIMO** |

### Declaración de Margen Estrecho
El sistema cumple estrictamente con la cota de 300 usuarios simultáneos sin caídas del proceso Uvicorn ni timeouts de conexión (QS-03). No obstante, para QS-02 el cumplimiento ocurre por un margen mínimo: el tiempo máximo registrado alcanzó **2975.91 ms**, ubicándose a solo **24.09 ms (0.8%)** del umbral de fallo de 3000 ms.

---

## 6. Hallazgo Técnico: Discrepancia con Pruebas Sintéticas Previas

La evidencia previa documentada en `docs/arc42/arc42.md` secciones 10.2 y 10.3 reportaba:
> *"p50 de respuesta API ~4 ms, p95 < 25 ms... 50 peticiones simultáneas con ThreadPool, 100% de tasa de éxito"*.

Dicha cifra provenía de `tests/test_performance.py`, el cual ejecuta peticiones mediante `TestClient` sobre el endpoint `GET /salud`. `GET /salud` ejecuta un `SELECT 1` elemental sin autenticación JWT ni procesamiento de modelos de dominio.

Al contrastar la medición contra peticiones HTTP reales a través de red loopback y sobre endpoints de negocio (`GET /recursos`, `GET /salones`, `GET /salones/1/disponibilidad`), la latencia mediana (p50) sube a un rango de **598.75 ms a 1684.12 ms**, y el percentil 95 escala hasta **2916.04 ms** bajo 300 usuarios. La medición con endpoints de dominio y persistencia real revela el comportamiento efectivo del backend bajo contención.

---

## 7. Hipótesis Técnica sobre Crecimiento de Latencia (No Verificada)

Los datos medidos de throughput según el nivel de concurrencia reflejan los siguientes rangos:
- **50 usuarios:** 45.4 a 60.9 req/s
- **150 usuarios:** 56.3 a 56.4 req/s
- **300 usuarios:** 90.0 a 102.3 req/s

A medida que la concurrencia escala de 50 a 300 usuarios, la latencia mediana (p50) sube de 598.75 ms a 1684.12 ms y el percentil 95 alcanza hasta 2916.04 ms (máximo absoluto de 2975.91 ms).

La causa de este crecimiento en los tiempos de respuesta se define estrictamente como una **hipótesis no verificada**, ya que el protocolo de medición ejecutado no aisló las variables intervinientes. Se plantean dos causas candidatas:
1. **Un solo worker de Uvicorn:** La API se ejecutó con un único proceso servidor, por lo que las peticiones concurrentes compiten por la ejecución en el bucle de eventos asyncio y por los recursos de CPU asignados a ese único proceso.
2. **Capacidad del pool de conexiones a base de datos:** El pool configurado en `app/core/database.py:21-24` opera con `pool_size=10` y `max_overflow=20`, estableciendo un tope de 30 conexiones simultáneas. Al llegar ráfagas de 50, 150 y 300 peticiones concurrentes, las solicitudes que superan la capacidad disponible deben aguardar turno en cola hasta que se liberen conexiones dentro del margen de `pool_timeout=30`.

La medición no aisló experimentalmente cuál de estos dos factores fue el determinante principal del incremento de latencia ni en qué proporción contribuyó cada uno. No se debe asumir el pool de conexiones como una causa comprobada.

---

## 8. Límites de la Medición

1. **Cliente y servidor en la misma máquina:** Al correr Uvicorn y el script de carga sobre el mismo hardware, ambos procesos compiten por ciclos de CPU, memoria y buffers del stack de red de Windows.
2. **Ráfaga única en lugar de carga sostenida:** La prueba mide ráfagas puntuales de 50, 150 y 300 peticiones concurrentes, sin evaluar degradación bajo flujo constante prolongado en el tiempo.
3. **Volumen de datos sembrado:** La prueba se ejecutó con 35 salones y 210 recursos. Un inventario histórico con decenas de miles de registros de préstamos podría degradar los tiempos de respuesta si faltan índices o paginación adecuada.
4. **Disponibilidad sobre un único salón:** Las peticiones a disponibilidad apuntaron todas a `salon_id=1`. No se evaluó la dispersión sobre múltiples salones en paralelo.
5. **Esquema generado por `create_all`:** Se utilizó `Base.metadata.create_all()` en lugar de aplicar migraciones Alembic consecutivas, dada la deuda técnica de Alembic documentada en R-03.
6. **Muestra acotada:** Se ejecutaron dos intentos por nivel de concurrencia, lo suficiente para constatar variación estadística entre corridas, pero sin constituir una muestra para análisis de desviación estándar formal.

---

## 9. Enlaces y Trazabilidad de Amenazas

- **T-08 (Saturación de conexiones de base de datos en hora pico):** Documentada en `docs/seguridad/modelo-amenazas.md:155` y respaldada por la propuesta de caché en `docs/datos/diseno-cache.md`.
- **T-13 (Inoperancia de bloqueo pesimista en SQLite vs PostgreSQL):** Documentada en `docs/seguridad/modelo-amenazas.md:160`.
- **R-03 (Deuda técnica de migraciones Alembic):** Documentada en `docs/arc42/arc42.md:565`.

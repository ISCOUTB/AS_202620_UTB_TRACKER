# 0012 - Empaquetar el sistema en contenedores con Docker Compose

## Estado

Aceptado (pendiente de verificar en una máquina con Docker)

## Contexto

Levantar UTB Tracker en una máquina nueva exige instalar Python, Flutter y PostgreSQL con las
versiones correctas. En Windows el script `iniciar.ps1` lo resuelve con SQLite, pero eso no es
igual a producción (PostgreSQL 16 en el servidor, ver arc42 §7). Cada integrante del equipo tenía
un entorno distinto, y algunos errores solo aparecían en el servidor.

## Decisión

Se agregan `Dockerfile` (backend), `frontend/Dockerfile` (app web) y `docker-compose.yml` con
cuatro servicios y uno opcional:

| Servicio | Imagen | Función |
|---|---|---|
| `db` | `postgres:16-alpine` | Base de datos (la misma versión que producción y el CI) |
| `api` | `Dockerfile` | Ejecuta `alembic upgrade head` y luego la API FastAPI |
| `worker` | misma imagen | `python -m app.messaging`: entrega del outbox (ADR-0006) |
| `web` | `frontend/Dockerfile` | Compila Flutter web y la sirve con nginx |
| `seed` (perfil `demo`) | misma imagen | Carga los datos de ejemplo |

- La API y el worker comparten imagen: es un **monolito modular** (ADR-0005), no microservicios.
- `requirements.txt` se instala con `--require-hashes` y el contenedor corre con un usuario sin
  privilegios.
- Los secretos del compose son solo de desarrollo; en producción van en un `.env` fuera del repo.

## Alternativas consideradas

- **Seguir solo con `iniciar.ps1`:** funciona en Windows, pero no reproduce PostgreSQL ni el
  worker.
- **Kubernetes:** desproporcionado para un proyecto académico con un solo servidor.

## Consecuencias

- **Positivas:** `docker compose up --build` levanta lo mismo que producción; el despliegue
  queda descrito como código (arc42 §7).
- **Negativas:** la primera compilación de la imagen web es lenta (descarga Flutter); hace falta
  Docker Desktop en Windows. La configuración todavía no se ha probado en una máquina con Docker.

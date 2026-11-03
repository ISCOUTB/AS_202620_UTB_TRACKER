# UTB Tracker
https://129-80-171-141.nip.io/docs#/
Backend desplegado

Sistema de inventario y préstamo de equipos y salones de la Universidad
Tecnológica de Bolívar. El backend está construido con FastAPI y el cliente
móvil con Flutter.

## Estado actual

- Backend FastAPI modular con autenticación JWT, préstamos, recursos, salones,
  mantenimiento, estadísticas, recuperación de contraseña y mensajería.
- PostgreSQL 16 es la base de datos usada en CI y producción.
- Alembic administra el esquema; la revisión actual se aplica con
  `alembic upgrade head`.
- Suite backend: 78 pruebas automatizadas.
- Auditoría de dependencias con `pip-audit` como gate bloqueante del CI.
- Despliegue por SSH con migración, reinicio de systemd y smoke test de salud.
- Firebase Cloud Messaging está integrado en Android: la app solicita permiso,
  registra el token en el backend y escucha su rotación. El envío automático
  desde el worker requiere configurar Firebase Admin y una cuenta de servicio
  fuera del repositorio.

## API pública

- Swagger: <https://129-80-171-141.nip.io/docs#/>
- Salud profunda: <https://129-80-171-141.nip.io/salud>

El endpoint `/salud` valida la conexión real con PostgreSQL mediante `SELECT 1`.
No se deben publicar credenciales ni claves en el repositorio.

## Desarrollo local

### Requisitos

- Python 3.12+
- PostgreSQL 16 para reproducir el entorno de CI
- Flutter/Dart para el cliente móvil

Instala el backend usando el lock con hashes:

```bash
python -m venv venv
venv\Scripts\activate
python -m pip install --require-hashes -r requirements.txt
```

Configura `DATABASE_URL` con una base PostgreSQL de desarrollo y define
`SECRET_KEY` y `FORGET_PWD_SECRET_KEY` como valores aleatorios distintos.
Después aplica el esquema:

```bash
alembic upgrade head
uvicorn app.main:app --reload
```

La documentación local queda disponible en
<http://127.0.0.1:8000/docs>.

También puede usarse `./run.sh` en entornos compatibles con POSIX; el script
instala dependencias, ejecuta las pruebas y arranca el servidor.

## Pruebas

Las pruebas usan exclusivamente `TEST_DATABASE_URL` cuando se proporciona. Si
no existe, crean una base SQLite temporal aislada para desarrollo local; nunca
reutilizan `DATABASE_URL` para ejecutar `drop_all`.

```bash
python -m pytest tests/ -v
```

Para reproducir CI con PostgreSQL:

```bash
$env:TEST_DATABASE_URL="postgresql+psycopg://postgres@localhost:5432/utb_tracker_test"
python -m pytest tests/ -v
```

Audita exactamente el lock:

```bash
python -m pip_audit -r requirements.txt --require-hashes
```

El CI no usa `continue-on-error` ni exclusiones silenciosas. Una vulnerabilidad
sin corregir bloquea el despliegue; cualquier excepción temporal debe quedar
documentada con responsable, justificación y fecha de vencimiento.

## Despliegue

El workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. Levanta PostgreSQL 16 en GitHub Actions.
2. Instala `requirements.txt` con hashes y ejecuta las 78 pruebas.
3. Ejecuta `pip-audit` como gate bloqueante.
4. Actualiza el servidor, instala dependencias y ejecuta `alembic upgrade head`.
5. Reinicia `utb-tracker` y exige `GET /salud` con `curl --fail`.

El correo SMTP real es opt-in mediante `USE_REAL_MAIL=1` y variables SMTP
configuradas fuera del repositorio. Sin esa configuración, el notificador no
simula una entrega externa exitosa.

## Funcionalidades principales

- Registro, inicio de sesión, rate limiting, refresh tokens y recuperación de
  contraseña.
- CRUD de recursos con estados disponibles, prestados y en mantenimiento.
- Préstamos con validación de disponibilidad, fechas, vencimiento y
  autocancelación.
- Solicitudes de préstamo de salones con fecha, hora y motivo.
- Reporte y seguimiento de órdenes de mantenimiento.
- Publicación de eventos de dominio y procesamiento de notificaciones.
- Registro de tokens FCM y resumen de estadísticas.
- Notificaciones Android listas para probar con Firebase Console en un
  dispositivo real.

## Estructura

```text
app/                    Backend FastAPI y módulos de dominio
alembic/                Migraciones del esquema PostgreSQL
tests/                  Pruebas backend
frontend/               Aplicación Flutter
docs/                   Arquitectura, decisiones y seguridad
requirements.in         Dependencias fuente
requirements.txt        Lock reproducible con hashes
```

Consulta [`docs/arc42.md`](docs/arc42.md) para la arquitectura y
[`docs/seguridad/analisis-dependencias.md`](docs/seguridad/analisis-dependencias.md)
para la política de auditoría.

## Seguimiento de remediación

La actualización del 3 de noviembre de 2026 corrigió las contradicciones
documentales y operativas señaladas en la revisión externa: PostgreSQL y
Alembic ya son la ruta declarada, el fallback destructivo de pruebas no usa
`DATABASE_URL`, el audit dejó de continuar ante errores y el deploy comprueba
salud después del reinicio. Starlette y PyJWT se fijan en versiones
actualizadas en `requirements.in` y `requirements.txt`; la compatibilidad se
verifica con la suite antes de desplegar.

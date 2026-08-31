# UTB Tracker

Sistema de inventario y préstamos de equipos electrónicos de la UTB. Ver `docs/arc42.md` para la documentación de arquitectura completa.

## Cómo arrancar (un solo comando)

```bash
./run.sh
```

Esto crea el entorno virtual si no existe, instala dependencias, corre las pruebas y levanta el servidor en `http://127.0.0.1:8000`. La documentación interactiva de la API (Swagger, generada sola por FastAPI) queda en `http://127.0.0.1:8000/docs`.

## Corte vertical ejecutable (S4)

Esta entrega incluye una funcionalidad real de punta a punta, no solo esqueleto: **registrar un préstamo respetando el estado del recurso**. Es la regla de negocio central del sistema (documento de idea, sección 6) y corresponde al escenario **QS-06** (`docs/arc42.md`, sección Requisitos de calidad) y al aspecto **A-06** (`docs/aspectos.md`).

### Prueba manual (con el servidor corriendo):

```bash
# 1. Crear un recurso (queda en estado "disponible")
curl -X POST http://127.0.0.1:8000/recursos \
  -H "Content-Type: application/json" \
  -d '{"categoria":"video_beam","salon_id":"A1-304","serial":"VB-DEMO-01"}'

# 2. Prestarlo (funciona, el recurso pasa a "prestado")
curl -X POST http://127.0.0.1:8000/prestamos \
  -H "Content-Type: application/json" \
  -d '{"recurso_id":1,"usuario_id":1,"fecha_devolucion_esperada":"2026-09-20T18:00:00"}'

# 3. Intentar prestarlo de nuevo (falla con 409, porque ya no está disponible)
curl -X POST http://127.0.0.1:8000/prestamos \
  -H "Content-Type: application/json" \
  -d '{"recurso_id":1,"usuario_id":2,"fecha_devolucion_esperada":"2026-09-21T18:00:00"}'
```

### Prueba automatizada (misma regla, sin necesidad de tener el servidor corriendo a mano):

```bash
./venv/bin/python -m pytest tests/test_loans.py -v
```

## Estructura (Monolito Modular)

```text
app/
  main.py              # arma la app FastAPI, monta los routers
  database.py           # configuración SQLAlchemy (SQLite en dev/CI, PostgreSQL en despliegue)
  models.py              # modelos: Usuario, Recurso, Prestamo
  schemas.py              # contratos Pydantic de entrada/salida de la API
  routers/
    health.py              # endpoint de verificación (S3)
    usuarios.py             # módulo declarado, sin lógica todavía
    resources.py             # CRUD de recursos (S4)
    loans.py                  # préstamos + regla de disponibilidad (S4)

tests/
  conftest.py                 # fixture de base de datos aislada por prueba
  test_health.py                # 1 prueba (S3)
  test_resources.py              # 3 pruebas (S4)
  test_loans.py                   # 3 pruebas (S4) — cubre la regla de negocio central
```

Cada módulo en `app/routers/` es la frontera de un aspecto (ver `docs/aspectos.md`). La tabla de bloques completa está en la sección 5 de `docs/arc42.md`.

## Base de datos

En desarrollo y CI se usa SQLite (`utbtracker.db`, se crea sola al arrancar — sin configuración). En despliegue se apunta a PostgreSQL con la variable de entorno `DATABASE_URL`. Las migraciones con Alembic quedan pendientes (ver [ADR-0002](docs/adr/0002-cambio-stack-fastapi-flutter.md), "Deuda aceptada a sabiendas").

## Pruebas

```bash
./venv/bin/python -m pytest tests/ -v
```

Actualmente hay 7 pruebas, todas en verde.

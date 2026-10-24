# UTB Tracker

API de inventario y préstamos de equipos de la UTB. FastAPI + SQLAlchemy 2 (psycopg / sqlite local), pytest + httpx. Monolito modular.

## Estructura
- `app/main.py` app y registro de routers; `database.py` engine/`get_db`; `models.py` (Usuario, Recurso, Prestamo); `schemas.py` (Pydantic)
- `app/routers/`: `users`, `resources`, `loans` (regla central: no prestar un recurso no disponible, 409), `health`
- `tests/` pruebas de la API y de contrato; `app/tests/` prueba mínima que ejecuta el CI
- `docs/`: arc42 (`arc42/arc42.md`, ~22 KB, leer solo por sección), ADR 0001-0003, C4, `aspectos.md`, `contracts/openapi.json` (no leer entero)

## Comandos
- Todo (venv, deps, tests, servidor): `./run.sh`
- Tests: `./venv/bin/python -m pytest tests/ -v`
- Swagger: http://127.0.0.1:8000/docs

## Ahorro de tokens
- Repo pequeño (~35 archivos): lee archivos directamente; no hace falta el grafo para un router o modelo concreto.
- Usa `graphify query|path|explain` solo para preguntas que crucen docs y código. Grafo local en `graphify-out/` (ignorado por git); antes de usarlo tras editar código: `graphify update .`.
- No leas `docs/contracts/openapi.json` ni `arc42.md` completos: usa Grep por sección.
- Responde en español.

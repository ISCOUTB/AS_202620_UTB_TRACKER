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
- Grafo local en `graphify-out/` (ignorado por git); reglas de uso en la sección `## graphify` más abajo.
- No leas `docs/contracts/openapi.json` ni `arc42.md` completos: usa Grep por sección.
- Responde en español.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

# ADR-0027 — Organización del backend por carpetas (config, db, middleware, handler, service, repository, models)

- **Estado:** Aceptado (2026-11-23) — entrega-final
- **Relacionado:** [ADR-0001](0001-estilo-arquitectonico.md), [ADR-0023](0023-retiro-del-prestamo-de-equipos-y-control-de-erosion.md), [ADR-0025](0025-matriz-de-permisos-en-un-archivo-de-datos.md)

## Contexto
El backend tenía las carpetas `core/`, `routers/` y `services/`; `core/` mezclaba configuración, base de
datos, seguridad y reglas. Se tomó como referencia la organización del proyecto `biblioteca-api`
(`config, db, handler, middleware, models, repository, service`) para dejar cada responsabilidad en
su carpeta. **Solo se reorganizó: ninguna regla de negocio, ruta, respuesta ni tabla cambió.**

## Decisión
| Antes | Ahora | Contenido |
|---|---|---|
| `core/config.py` | `config/config.py` | variables de entorno y reglas de producción |
| `core/database.py` | `db/database.py` | motor, sesión y `Base` |
| `core/deps.py`, `permisos.py`, `security.py`, `hashing.py`, `matriz_permisos.json` | `middleware/` | autenticación (JWT), permisos por rol |
| `routers/` | `handler/` | rutas HTTP; el registro de rutas pasó de `main.py` a `handler/routes.py` |
| `services/` (+ `core/politica.py`, `core/resilience.py`) | `service/` | reglas de negocio |
| (consultas dentro de los servicios) | `repository/` | acceso a datos: `limite_`, `mantenimiento_`, `usuario_repository` |
| `models/`, `schemas/`, `messaging/` | sin cambio | |

Dependencias (las vigila `tests/test_erosion_capas.py`): `handler → service → repository → models → db/config`;
`middleware` solo depende de `models`, `db` y `config`.

## Consecuencias
- Los nombres de módulo se conservaron (`handler/auth.py`, `service/auth.py`…), así el cambio es de ruta de importación.
- La capa `repository/` empezó con tres repositorios; mover el resto de las consultas es trabajo posterior, módulo por módulo, para no arriesgar la lógica.
- `docs/contracts/openapi.json` no cambia (lo valida `tests/test_contract.py`).

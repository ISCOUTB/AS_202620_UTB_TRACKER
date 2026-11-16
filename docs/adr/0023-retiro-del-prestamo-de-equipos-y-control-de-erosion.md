# 0023 - Retiro del estado "prestado" de los equipos y control automático de erosión

## Estado

Aceptado (2026-11-16). Completa ADR-0010 (los equipos no se prestan) y ADR-0001 (estilo en
capas). Atiende R-09 y R-10 de `docs/revision-app.md` y la guía S09 del curso (verificación y
erosión).

## Contexto

- El producto ya no presta equipos, pero quedaban tres restos del préstamo:
  - el valor `prestado` en `EstadoRecurso`;
  - `PUT /recursos/{id}` todavía lo aceptaba;
  - los endpoints `/prestamos/*`.
- Esos endpoints siguen siendo la evidencia de los experimentos del curso sobre
  idempotencia, bloqueo pesimista y outbox (S9 y S11, QS-06). Borrarlos rompería esa evidencia
  y a cualquier cliente viejo que los llame.
- El curso (S09) pide **verificar** el código hecho con IA y **evitar la erosión**: que las
  capas documentadas y el código no se separen con el tiempo.
- Una revisión manual encontró tres rupturas:
  - un router consultaba la base;
  - otro router hacía `commit` sin auditar;
  - un modelo importaba un servicio.

## Decisión

1. **"prestado" deja de ser un estado válido para algo nuevo:**
   - `PUT /recursos/{id}` y `PATCH /recursos/{id}/estado` lo rechazan con 422 y un mensaje en
     español.
2. **Migración de datos `e1f2a3b4c5d6`:**
   - Los equipos en `prestado` **sin** un préstamo activo o vencido pasan a `disponible`.
     Cada cambio queda en la tabla `auditoria`.
   - No se toca ningún préstamo, y los equipos con un préstamo vivo quedan igual.
   - No hay cambios de esquema.
3. **`/prestamos/*` queda como legado:**
   - Se marca `deprecated` en el OpenAPI, con la etiqueta "prestamos (legado)".
   - No lo usa ninguna pantalla. Se conserva como evidencia del curso.
   - Se podrá quitar cuando ninguna APK en uso lo llame.
4. **Control automático de erosión** con `tests/test_erosion_capas.py`, que corre en el CI:
   - **Backend:**
     - los routers no importan `app.models` ni hacen consultas (`db.query`, `db.commit`, …);
     - los servicios no importan routers;
     - los modelos no dependen de schemas, servicios ni routers;
     - `core` no depende de routers ni de servicios.
   - **Flutter** (Clean Architecture del Blueprint del curso):
     - `domain/` es Dart puro (sin Flutter, sin `http`, sin `data/` ni `presentation/`);
     - `data/` no conoce `presentation/`.
5. **Rupturas corregidas para que la regla pase:**
   - `GET /stats/resumen` pasó a `services/estadisticas.resumen_operativo`. Además se corrigió
     el conteo de ocupados, que contaba un "ocupado" guardado que ya no existe (ADR-0022).
   - `POST /mantenimientos` ahora confirma **y audita** en el servicio.
   - `/salud` consulta la base desde `services/salud.py`.
   - El texto de "salón deshabilitado" vive en el modelo `Salon`.

## Consecuencias

- **Positivas:**
  - Las capas que dicen arc42 §5 y §8.1 se comprueban en cada cambio: una regla rota hace
    fallar el CI con el archivo y la línea.
  - Ningún dato nuevo puede quedar en "prestado".
- **Negativas:**
  - `prestado` sigue en el enum, porque los datos viejos y el legado lo usan.
- **Compatibilidad:**
  - La migración es solo de datos y es idempotente.
  - No hacen falta variables nuevas.

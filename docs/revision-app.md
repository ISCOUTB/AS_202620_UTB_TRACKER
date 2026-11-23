# Revisión de la app (fase 6, 2026-11-16)

**Alcance real de esta revisión.** Se revisó leyendo el código y con pruebas automáticas:

- pytest del backend;
- pruebas de pantallas Flutter a 360 dp, con texto ×1,0 y ×1,3;
- la matriz endpoint × rol;
- el contrato OpenAPI;
- un recorrido con datos sembrados en una base local.

**No** se recorrió cada pantalla a mano en un teléfono con cada rol. Eso queda en la guía
[guia-pruebas.md](guia-pruebas.md) para hacerlo con la APK.

| Id | Dónde | Qué pasa | Gravedad | Estado | Cómo se verificó |
|---|---|---|---|---|---|
| R-01 | `GET /salones/ocupacion` (panel del Auditor) | Hacía unas 5 consultas por salón cada 30 s (N+1); con el catálogo de 59 salones son unas 300 por refresco | Alta | Arreglado (consultas fijas) | `test_listados_sin_n_mas_1` (mismas consultas con 2 y con 10 salones) |
| R-02 | `GET /recursos` | Una consulta por equipo para el nombre del salón (N+1) | Media | Arreglado (`joinedload`) | Misma prueba |
| R-03 | `GET /salones` | Límite de 50: con el catálogo, la APK vieja y la nueva no veían todos los salones | Alta | Arreglado: límite 100 por defecto y la app pide todas las páginas | `test_filtros_por_edificio_y_piso_y_orden_natural`, `catalogo_test.dart` |
| R-04 | `Salon.estado` | Mezclaba una decisión manual (mantenimiento) con un hecho (ocupado); un salón en mantenimiento se podía solicitar y aprobar | Alta | Arreglado (ADR-0022) | `test_habilitacion_equipos.py` |
| R-05 | Crear salones | El Auditor podía crear salones con códigos mal formados | Media | Arreglado (ADR-0021) | `test_catalogo_salones.py` |
| R-06 | Textos de la app y del servidor | "préstamo" en vez de "solicitud" en errores de solicitudes de salón y en "crear equipo" ("se gestiona con los préstamos") | Baja | Arreglado | Revisión de textos y suites en verde |
| R-07 | Detalle del salón (Auditor) | La tarjeta nueva de habilitación se desbordaba a 360 dp con texto ×1,3 | Media | Arreglado antes de publicar | `escala_test.dart` |
| R-08 | Apertura de la app | En Android 12+ el ícono salía como un cuadrado azul y la app pasaba un instante por el login antes de entrar | Baja | Arreglado: círculo con el pin y una pantalla de arranque en Flutter con fundido | Revisión visual de la imagen generada y `flutter test` |
| R-09 | `EstadoRecurso.PRESTADO` | Era un resto del préstamo de equipos y `PUT /recursos/{id}` lo aceptaba | Media | Arreglado (ADR-0023): 422, y la migración `e1f2a3b4c5d6` pasa los huérfanos a disponible con auditoría | `test_put_de_recurso_rechaza_prestado`; migración probada en PostgreSQL |
| R-10 | Endpoints `/prestamos/*` (legado) | Préstamo de equipos, ya sin pantalla en la app | Media | Arreglado (ADR-0023): marcados como obsoletos en el OpenAPI. Se conservan como evidencia de S11 | `test_prestamos_de_equipos_figuran_como_obsoletos` |
| R-11 | `alembic upgrade head` sobre SQLite vacío | Falla en una migración antigua (`prestamos`); en PostgreSQL sí funciona | Baja | Decidido: no se reescriben migraciones ya desplegadas. En local se usa `scripts/preparar_bd.py` o `create_all` + `alembic stamp head` (ver COMO_EJECUTAR) | Reproducido el 2026-11-16 |
| R-13 | Capas (erosión, S09) | `routers/stats.py` consultaba la base y contaba un "ocupado" que ya no se guarda (siempre daba 0); `routers/maintenance.py` hacía `commit` sin auditar; `models/salon_models.py` importaba un servicio | Media | Arreglado (ADR-0023) y regla automática en el CI | `tests/test_erosion_capas.py` |
| R-12 | APK vieja | Ve `estado = "ocupado"` durante una clase y no deja pedir ese salón para más tarde (la APK nueva sí deja) | Baja | Aceptado (ADR-0022) | — |

## Propuestas

R-09, R-10 y R-11 se resolvieron el 2026-11-16 (ADR-0023). Queda pendiente quitar `/prestamos/*` del todo cuando ninguna APK en uso lo llame.

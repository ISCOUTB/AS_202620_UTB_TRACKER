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
| R-09 | `EstadoRecurso.PRESTADO` | Es un resto del préstamo de equipos. `PUT /recursos/{id}` todavía lo acepta y `/prestamos` (legado) lo usa | Media | **Propuesta** (no se hizo) | — |
| R-10 | Endpoints `/prestamos/*` (legado) | Préstamo de equipos, ya sin pantalla en la app | Media | **Propuesta** | — |
| R-11 | `alembic upgrade head` sobre SQLite vacío | Falla en una migración antigua (`prestamos`). En local se usa `create_all` o `scripts/preparar_bd.py`; en PostgreSQL funciona | Baja | **Propuesta**: no se reescriben migraciones desplegadas | Reproducido el 2026-11-16 |
| R-12 | APK vieja | Ve `estado = "ocupado"` durante una clase y no deja pedir ese salón para más tarde (la APK nueva sí deja) | Baja | Aceptado (ADR-0022) | — |

## Propuestas (decisión de producto, no se hicieron)

- **R-09 y R-10 — retirar el préstamo de equipos sin romper datos viejos.** Recomendación:
  1. Que `PUT /recursos/{id}` rechace `prestado` con 422, igual que el endpoint nuevo.
  2. Migración de datos: los equipos en `prestado` pasan a `disponible` y se registra en la
     auditoría. Las filas de `prestamos` se conservan como histórico.
  3. Marcar `/prestamos/*` como obsoleto en la documentación de la API.
  4. Quitarlo en una versión posterior, cuando ninguna APK en uso lo llame.
- **R-11.** Agregar una migración nueva que tolere la base vacía, o documentar que en local solo
  se usa `preparar_bd.py`. No se deben tocar las migraciones existentes.

# Estrategia de Datos y Eventos — UTB Tracker

Este directorio agrupa la documentación arquitectónica de persistencia, concurrencia, mensajería asíncrona y diseño de caché del sistema UTB Tracker.

---

## 1. Resumen Ejecutivo (5 Líneas)

1. La regla central de negocio (préstamos de equipos) opera de forma síncrona con consistencia fuerte y bloqueo pesimista en PostgreSQL (`.with_for_update()`), asegurando el escenario QS-06.
2. Múltiples operaciones críticas (`POST /prestamos-salon`, `POST /horarios`, `PATCH /prestamos/{id}/devolver`) operan bajo el patrón "comprobar y luego escribir" en Python sin bloqueo en BD, quedando expuestas a condiciones de carrera concurrentes.
3. El flujo de eventos desacopla las notificaciones mediante Transactional Outbox (`mensajes_outbox`) con entrega at-least-once, pero formalmente **sin garantía de orden de entrega**, sin `SKIP LOCKED` y sin despliegue automatizado del worker.
4. Se formula una propuesta de caché en memoria de proceso acotada por TTL (60 s / 120 s) con invalidación por versiones, garantizando que ninguna operación de escritura dependa de la caché.
5. Se documenta retroactivamente en el ADR-0007 la decisión de usar identificadores enteros autoincrementales, demostrando cuantitativamente por qué es la decisión de datos más costosa de revertir (10 tablas, 9 FKs, 16 endpoints, 14 archivos de frontend).

---

## 2. Índice de Documentos

- [`consistencia-por-operacion.md`](consistencia-por-operacion.md): Matriz exhaustiva de operaciones de lectura/escritura, escenarios de calidad (QS-01 a QS-06), garantías requeridas vs reales, análisis del flujo outbox y catálogo de brechas.
- [`diseno-cache.md`](diseno-cache.md): Especificación arquitectónica de la capa de caché en memoria, espacio de nombres, política de invalidación por versión y modos de fallo. *(DISEÑO PROPUESTO — NO IMPLEMENTADO)*.
- [`../adr/0007-identificadores-enteros-autoincrementales.md`](../adr/0007-identificadores-enteros-autoincrementales.md): ADR formal sobre la elección de claves primarias enteras frente a UUIDs y cuantificación del costo de reversión.
- [`../c4/C2.md`](../c4/C2.md): Diagrama C2 de contenedores actualizado con el Worker de mensajería y la matización de comunicación síncrona/asíncrona.
- [`../arc42/arc42.md`](../arc42/arc42.md): Secciones 8.8, 8.9 y actualización de la tabla de riesgos y deudas técnicas (R-06 a R-11).

---

## 3. Metodología de Verificación en el Repositorio

Toda afirmación técnica contenida en estos documentos se verificó directamente sobre el código fuente mediante herramientas automatizadas:

- **Bloqueos de concurrencia (`with_for_update`):** Verificado mediante búsqueda en el árbol de servicios. Se constató que únicamente existe en `app/services/loans.py:58` condicionado al motor PostgreSQL; ausente en `devolver_prestamo` y `prestamos_salon.py`.
- **Restricciones de unicidad en base de datos:** Verificado en `app/models/auth_models.py` (`email` único en L20; `nombre` sin restricción única en L19).
- **Procesamiento y orden del worker:** Verificado en `app/messaging/worker.py:65-72`. El filtro `siguiente_intento <= ahora` combinado con `order_by(creado_en)` rompe el orden global estricto ante reintentos con backoff.
- **Topología de despliegue:** Verificado en `.github/workflows/ci.yml:68` y `run.sh:19`. No se define número de workers de Uvicorn en el repo y el worker de mensajería no forma parte del pipeline de arranque automático.
- **Vulnerabilidad de autorización en perfil de usuario:** Verificado en `app/routers/auth.py:53-59` y `app/services/auth.py:118-124`. `get_user_endpoint` solo valida autenticación genérica (`CurrentUser`), permitiendo enumeración de identificadores enteros.
- **Métricas cuantitativas de impacto:** Verificado mediante scripts de inspección estática (conteos de `primary_key=True`, `ForeignKey`, endpoints con `{id}` y archivos Dart en `frontend/lib/`).

---

## 4. Enlace al Commit

<PEGAR URL DEL COMMIT>

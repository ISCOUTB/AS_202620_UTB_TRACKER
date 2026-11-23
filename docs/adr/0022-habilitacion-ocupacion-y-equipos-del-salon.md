# 0022 - Habilitación del salón separada de su ocupación, y equipos fijos con estado

## Estado

Aceptado (2026-11-16). Amplía ADR-0009 (administración de salones), ADR-0010 (equipos fijos
que no se prestan) y ADR-0017 (equipamiento calculado).

## Contexto

- `Salon.estado` (`disponible | ocupado | mantenimiento | fuera_servicio`) mezclaba dos ideas:
  - una decisión manual: el salón está cerrado por mantenimiento;
  - un hecho que cambia solo: ahora hay clase.
- Nadie guardaba "ocupado" de forma confiable, y un salón en mantenimiento no explicaba por
  qué ni hasta cuándo.
- Un salón cerrado se podía seguir solicitando y aprobando.
- No había historial del salón ni forma de cambiar el estado de sus equipos. Tampoco había
  forma de cargar el equipamiento de muchos salones sin hacerlo uno por uno.
- Las APK instaladas leen `estado` con esos cuatro valores y algunas lo cambian con
  `PUT /salones/{id}`.
- El panel del Auditor hacía unas 5 consultas **por salón** cada 30 segundos (N+1). Con el
  catálogo de 59 salones (ADR-0021) eso son unas 300 consultas.

## Decisión

### 1. Dos conceptos distintos

- **HABILITACIÓN (manual):** columnas nuevas `habilitado` (true por defecto),
  `motivo_deshabilitado`, `nota_deshabilitado` y `reapertura_estimada`.
  - La deciden el Administrador o el Auditor (`salones.administrar`) con
    `PATCH /salones/{id}/habilitacion`.
  - Para deshabilitar, el **motivo es obligatorio**: `mantenimiento`, `danio`, `evento` u
    `otro`. Con `otro` también es obligatoria una nota.
  - La fecha de reapertura es opcional y no puede estar en el pasado.
- **OCUPACIÓN (calculada):** el salón está ocupado si hay una clase de su horario en curso
  (hora del campus, UTC-5) o una solicitud aprobada o en uso (UTC sin zona). No se edita.
  - Se calcula para muchos salones con un número **fijo** de consultas
    (`app/service/estado_salon.py`).

### 2. `estado` sigue existiendo y se calcula

| Habilitación | Ocupación | `estado` devuelto |
|---|---|---|
| deshabilitado por mantenimiento | — | `mantenimiento` |
| deshabilitado por daño, evento u otro | — | `fuera_servicio` |
| habilitado | hay clase o solicitud ahora | `ocupado` |
| habilitado | libre | `disponible` |

- Son los mismos cuatro valores de siempre: una APK vieja los entiende.
- La columna guardada solo refleja la habilitación: nunca se guarda "ocupado".
- Campos nuevos en la respuesta (aditivos): `habilitado`, `motivo_deshabilitado`,
  `nota_deshabilitado`, `reapertura_estimada`, `aviso_deshabilitado` (texto listo) y
  `ocupado_ahora`.
- **Clientes viejos que mandan `estado`:** se traduce a habilitar o deshabilitar, con su
  historial y su auditoría:
  - `mantenimiento` → deshabilitar con motivo mantenimiento;
  - `fuera_servicio` → deshabilitar con motivo daño;
  - `disponible` → habilitar;
  - `ocupado` → se ignora, porque ahora se calcula.
- **Migración `d0e1f2a3b4c5`:**
  - los salones en `mantenimiento` pasan a deshabilitados con motivo mantenimiento;
  - los de `fuera_servicio` pasan a deshabilitados con motivo daño;
  - no se borra nada.

### 3. Qué pasa con un salón deshabilitado

- No se puede solicitar (`POST /prestamos-salon` → 409 con el motivo) ni aprobar.
- No sale como disponible y no ofrece franjas libres.
- La app lo muestra con su motivo y su fecha de reapertura.
- **Solicitudes afectadas** (pendientes o aprobadas que aún no terminan):
  - **no se cancelan solas**;
  - quedan señaladas con `aviso_salon` en la bandeja del Auditor y en "Mis solicitudes";
  - a cada estudiante le llega un correo `salon_deshabilitado` por el outbox, en la misma
    transacción. Es de la categoría "salones", así que respeta sus preferencias.
  - El Auditor decide si rechaza o reubica. Rechazar sí está permitido.
- **Deshabilitar por lote:** sirve para un edificio o un piso, con vista previa (salones que
  cambian y cuántas solicitudes quedan afectadas). Es todo o nada.

### 4. Historial del salón

- **Tabla `historial_salon`:** guarda un resumen legible de cada cambio:
  - deshabilitado o habilitado;
  - cambio de estado de un equipo;
  - equipo agregado o retirado;
  - plantilla aplicada.
- Se ve en el detalle del salón (`GET /salones/{id}/historial`).
- No reemplaza a la bitácora de auditoría (ADR-0010). Cada acción también se audita con
  `actor_id` en la misma transacción: `salon.habilitacion`, `recurso.estado` y
  `recurso.plantilla`.

### 5. Equipos fijos: solo cambia su estado

- `PATCH /recursos/{id}/estado` acepta: operativo (se guarda `disponible`), dañado o en
  mantenimiento. **"prestado" se rechaza con 422.**
- Agregar un equipo es `POST /recursos`. Retirarlo es `DELETE /recursos/{id}`: se desactiva, no
  se borra.
- Un equipo dañado baja `operativos` pero no `total` (el equipamiento se calcula, ADR-0017).
- **Sin automatismos sorpresivos:** al marcar un equipo dañado, la respuesta solo **sugiere**
  (`sugerir_reporte`) abrir un reporte, y lista los reportes de tipo equipo ya abiertos en el
  salón. Se puede vincular uno: columna nueva `reportes_salon.recurso_id`.
- **Plantillas:** "aula estándar" (1 video beam, 1 aire y 1 computador del docente) y
  "laboratorio" (N computadores).
  - Se aplican solo a los salones elegidos y con vista previa.
  - Solo crean lo que falta: nunca duplican ni quitan.

### 6. Complementos que se hicieron (y por qué)

- **Ocupación por edificio y piso** (`GET /salones/ocupacion/resumen`): el Auditor ve cuántos
  salones están libres ahora por piso sin tener que contarlos.
- **Exportar catálogo y equipos a CSV** (`GET /salones/exportar.csv`): sirve para revisar la
  lista provisional con Planta Física.
  - No lleva datos personales.
  - Evita la inyección de fórmulas: una celda que empieza por `=`, `+`, `-` o `@` se escapa.
  - La app lo copia al portapapeles, sin paquetes nuevos.
- **Etiqueta "estimado"** en la capacidad que no es oficial (viene de ADR-0021).
- **El panel deja de hacer N+1:** las consultas son fijas sin importar el número de salones.
  Hay una prueba que compara 2 contra 10 salones.

### 7. El estado "prestado" de los equipos (resto del préstamo)

- No se usa en nada nuevo.
- La propuesta para retirarlo sin romper datos viejos queda en `docs/revision-app.md` (fase 6).

## Consecuencias

- **Positivas:**
  - Cada estado se explica: tiene motivo, fecha y quién lo cambió.
  - No se puede pedir un salón cerrado.
  - Los estudiantes afectados se enteran y nadie pierde su solicitud sin una decisión humana.
  - El panel escala con el catálogo.
- **Negativas:**
  - `estado` cambia solo durante el día (ocupado/disponible).
  - Una APK vieja muestra "ocupado" durante una clase y no deja pedir ese salón para más tarde
    desde la lista. La APK nueva usa `habilitado` y sí deja.
- **Compatibilidad:**
  - Solo cambios aditivos: columnas con `server_default`, una tabla nueva y campos nuevos con
    valor por defecto.
  - Los valores guardados de `estado` y de `rol` no cambian.
  - No hacen falta variables nuevas.

# 0017 - Tipo de salón y equipamiento calculado desde los recursos

## Estado

Aceptado (2026-11-14).

## Contexto

Para pedir o asignar un salón no basta con el código y la capacidad: quien necesita una sala
con computadores o un auditorio con sonido tenía que adivinar. Los equipos ya existen como
recursos fijos de cada salón (ADR-0009/0011: no se prestan), así que la información estaba en
la base, pero la API no la entregaba junto al salón.

## Decisión

1. **`Salon.tipo`** (enum `TipoSalon`: `aula`, `laboratorio_computo`, `sala_audiovisual`,
   `auditorio`, `sala_reuniones`, `otro`; por defecto `aula`) y **`Salon.descripcion`**
   (opcional, máximo 500, se recortan los espacios; vacía = sin descripción). Migración
   `e5f6a7b8c9d0` con `server_default 'aula'`: los salones existentes quedan como aula.
2. **El equipamiento NO se guarda.** Se calcula desde los recursos **activos** del salón,
   agrupado por categoría: `{categoria, total, operativos}`. Un equipo dañado o en
   mantenimiento baja `operativos` pero no `total`; uno dado de baja (`activo = false`) no
   cuenta. Se calcula con **una sola consulta agrupada** para todos los salones de la respuesta
   (`app/services/equipamiento.py::calcular`), nunca una por salón.
3. **`tipo_sugerido`**: regla simple y explicable (8 o más computadores → laboratorio de
   cómputo; capacidad ≥ 100 con audio o video beam → auditorio; video beam + audio + TV → sala
   audiovisual). Es **solo una sugerencia**: nunca cambia el tipo guardado. La app la muestra
   como "Sugerido: … [Usar]" y el cambio lo hace una persona (queda en la auditoría como
   `salon.actualizar` con `{"tipo": {"de", "a"}}`).
4. **API** (cambio aditivo; los campos nuevos de respuesta tienen valor por defecto):
   `SalonCreate/Update/Response` con `tipo` y `descripcion`; la respuesta trae `equipamiento` y
   `tipo_sugerido`; `GET /salones` acepta `tipo`, `con_equipo` (salones con al menos un equipo
   **operativo** de esa categoría) y `busqueda` también sobre la descripción;
   `/salones/ocupacion` y `/salones/{id}/ocupacion` traen tipo, descripción y equipamiento.
5. **App:** widget compartido `EquipamientoChips` (figura de `assets/figuras`, conteo y el texto
   "1 dañado" además del color); tarjetas compactas con tipo + chips; sección "Equipamiento"
   con la descripción y "Editar" en el control del salón; filtros por tipo y por equipo en el
   panel; formulario de crear salón con tipo y descripción y hoja de edición con la sugerencia;
   la pantalla donde el usuario UTB solicita un salón muestra tipo, descripción y equipamiento.
6. **Datos de ejemplo:** un laboratorio con 20 computadores (LAB-SIS1), un auditorio (AUD-CT),
   una sala audiovisual (A4-301), salas de reuniones, aulas con video beam, equipos dañados, y
   LAB-SIS2 guardado a propósito como "aula" con 12 computadores para ver la sugerencia.

## Alternativas consideradas

- **Guardar el equipamiento en el salón** (columnas o JSON): se desincroniza en cuanto se daña
  o se mueve un equipo, y duplicaría lo que ya registran los recursos.
- **Calcularlo en la app** pidiendo `/recursos`: muchas peticiones, lógica duplicada y sin
  filtro `con_equipo` en el servidor.
- **Que el sistema cambie el tipo solo** según el equipamiento: un salón con computadores
  puede seguir siendo un aula; la decisión es de la persona.

## Consecuencias

- **Positivas:** el equipamiento siempre coincide con el inventario; filtros útiles para el
  auxiliar y para quien solicita; sin consultas N+1 (lo cubre una prueba que cuenta consultas).
- **Negativas:** cada listado hace una consulta extra agrupada (barata, con índice en
  `recursos.salon_id`); la regla de sugerencia es fija en el código.

## Trazabilidad

| Decisión | Código | Pruebas |
|---|---|---|
| Tipo y descripción | `app/schemas/enums.py::TipoSalon`, `app/models/salon_models.py`, `app/schemas/salones.py`, migración `e5f6a7b8c9d0` | `tests/test_salones_tipo_equipamiento.py::test_tipo_por_defecto_y_descripcion_recortada`, `test_tipo_invalido_y_descripcion_larga_dan_422` |
| Equipamiento calculado | `app/services/equipamiento.py` | `test_equipamiento_solo_con_recursos_activos_y_operativos`, `test_equipamiento_no_hace_una_consulta_por_salon` |
| Filtros | `app/services/salones.py::listar_salones`, `app/routers/salones.py` | `test_filtros_por_tipo_por_equipo_y_busqueda_en_descripcion` |
| Ocupación | `app/services/salones_admin.py` | `test_ocupacion_trae_tipo_descripcion_y_equipamiento` |
| Auditoría del tipo | `app/services/salones.py::actualizar_salon` | `test_la_sugerencia_desaparece_al_aceptarla_y_el_cambio_queda_auditado` |
| App | `frontend/lib/shared/equipamiento_chips.dart`, `frontend/lib/features/salones/presentation/tipo_salon_campos.dart`, `panel_salones_page.dart`, `salon_control_page.dart`, `salon_detalle_page.dart` | `frontend/test/equipamiento_test.dart`, `frontend/test/escala_test.dart` |
| Datos de ejemplo | `scripts/seed_demo.py` | revisión manual |

# Documentación de UTB Tracker: índice

La documentación está organizada según el curso de Arquitectura de Software:

- **S04 (documentación arquitectónica):** arc42 + C4 + ADR + aspectos, con coherencia,
  correspondencia y trazabilidad.
- **S09 (IA, verificación y erosión):** registro del uso de IA y reglas que se comprueban
  solas.

Cada decisión queda en un ADR. Cada ADR aparece en arc42 §9 y en `aspectos.md`, con las rutas
reales del código y las pruebas que lo verifican.

## 1. Vista general (empieza aquí)

| Documento | Para qué sirve |
|---|---|
| [arc42/arc42.md](arc42/arc42.md) | Documento principal: las 12 secciones de arc42 (objetivos, restricciones, contexto, solución, bloques, ejecución, despliegue, conceptos, decisiones, calidad, riesgos y glosario) |
| [c4/c4_nivel1.md](c4/c4_nivel1.md) | C4 nivel 1: contexto (personas por rol y sistemas externos) |
| [c4/C2.md](c4/C2.md) | C4 nivel 2: contenedores (app Flutter, API FastAPI, worker, PostgreSQL) |
| [ficha_problema.md](ficha_problema.md), [matriz_estilos.md](matriz_estilos.md) | Problema de negocio y comparación de estilos arquitectónicos |

## 2. Decisiones (ADR)

[adr/](adr/): de 0001 a 0023. Todas tienen Estado, Contexto, Decisión y Consecuencias. Las más
recientes:

| ADR | Decisión |
|---|---|
| [0018](adr/0018-modelo-de-roles-y-permisos.md) | Roles y permisos (matriz única) |
| [0019](adr/0019-correo-institucional-y-rol-por-asignacion.md) | Correo institucional y rol por asignación |
| [0020](adr/0020-foto-de-perfil.md) | Foto de perfil |
| [0021](adr/0021-catalogo-de-salones-utb.md) | Catálogo de salones UTB |
| [0022](adr/0022-habilitacion-ocupacion-y-equipos-del-salon.md) | Habilitación, ocupación y equipos |
| [0023](adr/0023-retiro-del-prestamo-de-equipos-y-control-de-erosion.md) | Retiro de "prestado" y control de erosión |

## 3. Trazabilidad y calidad

| Documento | Para qué sirve |
|---|---|
| [aspectos.md](aspectos.md) | Matriz aspecto → atributo de calidad (QS) → ADR → código → prueba → evidencia |
| [calidad/medicion-qs03.md](calidad/medicion-qs03.md) | Medición del escenario de concurrencia |
| [contracts/](contracts/) | Contrato OpenAPI congelado, verificado por `tests/test_contract.py` |
| `tests/test_erosion_capas.py` | Regla automática de capas, para el backend y para la app (S09) |
| [revision-app.md](revision-app.md) | Revisión de la app: hallazgos, gravedad, arreglos y propuestas |

## 4. Seguridad y privacidad

[seguridad/](seguridad/) contiene:

- el modelo de amenazas STRIDE (T-01 a T-35);
- la matriz de permisos endpoint × rol, verificada por una prueba;
- el documento de privacidad;
- el análisis de dependencias y el SBOM.

## 5. Datos, mensajería y despliegue

| Carpeta o documento | Contenido |
|---|---|
| [datos/](datos/) | Consistencia y caché |
| [mensajeria/](mensajeria/) | Outbox y worker |
| [despliegue/worker.md](despliegue/worker.md) | Despliegue del worker y del correo |
| [despliegue/catalogo-salones.md](despliegue/catalogo-salones.md) | Cómo cargar el catálogo de salones |
| [COMO_EJECUTAR.md](COMO_EJECUTAR.md), [guia-pruebas.md](guia-pruebas.md) | Ejecutar la app y probarla con los datos de ejemplo |

## 6. Uso de IA (S09)

[ia.md](ia.md): una fila por cada trabajo hecho con IA. Cada fila dice qué se aceptó, qué se
descartó y cómo se verificó.

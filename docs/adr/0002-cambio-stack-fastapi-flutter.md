# 0002 - Cambio de stack: Django (web) → FastAPI + Flutter (API + móvil)

## Estado

Aceptado

## Contexto

El proyecto original (Tractar) se documentó y se comenzó a construir sobre Django, con una
interfaz web servida directamente por el propio backend (restricción técnica del proyecto
original). El profesor autorizó el cambio de tema hacia **UTB Tracker**, dirigido a auxiliares
de planta y laboratorio.

Ese cambio trajo un requisito nuevo que Django, en su forma original (sirviendo HTML), no
encajaba tan bien: el cliente pasó a ser una **app móvil separada** (Flutter), no una interfaz
web integrada al backend. Con un cliente móvil real, el backend necesita ser puramente una API
— y ahí es donde entra la comparación de herramientas que lleva a esta decisión. La elección de
*estilo* arquitectónico (monolito modular) es una decisión aparte, ya redactada para este stack
en [ADR-0001](0001-estilo-arquitectonico.md); este ADR-0002 documenta específicamente por qué
FastAPI y no otra alternativa de API.

## Decisión

Se cambia el backend de Django a **FastAPI**, expuesto como API REST/JSON consumida por un
cliente **Flutter** separado. Persistencia en SQL vía **SQLAlchemy**, con **Alembic** pendiente
para migraciones versionadas (ver Restricciones, arc42 sección 2).

## Alternativas consideradas

**Seguir con Django, agregando Django REST Framework (DRF) para exponer la API.** Se descartó
porque hubiera significado cargar con toda la maquinaria de Django (templates, forms, admin
pensado para HTML) que ya no se usa con un cliente Flutter — payload y complejidad que no
aportan nada al nuevo alcance. FastAPI, al ser API-first desde el diseño, no arrastra esa capa
sin uso.

**Flask + una librería de validación aparte.** Se descartó porque FastAPI ya trae, sin
configuración extra, exactamente lo que el equipo necesitaba para QS-05 (usabilidad, validación
de formularios) y para documentar el contrato HTTP/JSON entre backend y Flutter: validación
automática con Pydantic y documentación interactiva (Swagger/OpenAPI) generada sola. Armar eso
a mano sobre Flask hubiera costado tiempo que el equipo no tiene en el semestre.

## Consecuencias

**Se gana:** contrato de API auto-documentado (`/docs`), validación de entrada automática vía
Pydantic (reduce errores de datos mal formados llegando a la base — relevante para QS-06,
confiabilidad de los datos), y un desarrollo backend más liviano al no cargar con lo que Django
ofrece para servir HTML, que ya no se necesita.

**Se asume:** el equipo pierde el Admin de Django (panel administrativo gratis) — cualquier
herramienta de administración para el catálogo de recursos hay que construirla como parte de la
propia app o como endpoints adicionales, no viene incluida.

**Deuda aceptada a sabiendas:** las migraciones con Alembic no están configuradas todavía; el
esquema se crea con `Base.metadata.create_all()` al arrancar. Esto es aceptable para el corte
vertical de esta entrega, pero antes de tener datos reales de producción, Alembic debe
configurarse — de lo contrario, cualquier cambio de esquema futuro puede requerir borrar y
recrear la base de datos manualmente.
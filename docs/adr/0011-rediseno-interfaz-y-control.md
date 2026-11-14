# 0011 - Rediseño de la interfaz al estilo de UTB App y pestaña "Control" en lugar de préstamos de equipos

## Estado

Aceptado

## Contexto

Después de ADR-0009 la app ya se centraba en los salones, pero la interfaz seguía mostrando
restos del modelo de préstamo de equipos: el inicio decía "Presta en segundos" y "Préstamos
activos", la pestaña "Actividad" listaba préstamos y la ficha de cada equipo tenía un
"Historial de préstamos". Eso contradecía la regla de negocio (los equipos están fijos en el
salón y no se prestan) y rompía la correspondencia entre la documentación y el código.

Había además dos problemas visibles:

- La ficha de un equipo mostraba el **id interno** del salón ("Salón 5") en lugar de su código
  real ("A1-101"), porque la API de recursos solo devolvía `salon_id`.
- El estilo era plano (negro y gris), muy distinto de la app oficial **UTB App** que usan los
  estudiantes, así que UTB Tracker no se sentía parte de la Universidad.

## Decisión

1. **Navegación de 4 pestañas:** Inicio · Salones · Control · Perfil. Los equipos dejan de
   tener pestaña propia: se consultan por salón o desde "Inventario" (Perfil del auxiliar).
2. **"Control" reemplaza a "Actividad":** el auxiliar aprueba o rechaza solicitudes de salón y
   resuelve los reportes de todos los salones (`GET /salones/reportes`, nuevo); el usuario UTB
   sigue el estado de sus solicitudes. Se eliminan del frontend `actividad_page.dart` y la hoja
   de solicitar préstamo de equipos. El backend `/prestamos` se conserva solo como corte
   vertical del curso (ADR-0009).
3. **Nombres reales de salón en la API:** `RecursoOut`, `ReporteSalonResponse` y
   `PrestamoSalonResponse` exponen `salon_nombre` (y edificio, ubicación o nombre del usuario)
   mediante propiedades del modelo SQLAlchemy. La app nunca muestra el id interno.
4. **Lenguaje visual inspirado en UTB App** (`frontend/lib/shared/utb_ui.dart`): encabezado con
   degradado azul → índigo y arcos, tarjeta destacada con barra de estado, control segmentado en
   píldora, línea de tiempo, credencial tipo carnet, fondo con brillos difuminados, tarjetas de
   vidrio y transiciones suaves (desvanecer + subir) entre pantallas y elementos. No se copia el
   logo ni la mascota de la UTB (ver `docs/identidad/identidad-visual.md`).
5. **Datos de ejemplo con salones reales** del Campus Tecnológico (Aulas 1, 2 y 4, Alcatraz,
   laboratorios y biblioteca; códigos tipo A4-204).

## Alternativas consideradas

- **Mantener "Actividad" y solo cambiar textos:** más barato, pero seguiría girando alrededor de
  préstamos de equipos, que no existen en el negocio.
- **Resolver el nombre del salón en el cliente** cruzando `/recursos` con `/salones`: dos
  peticiones por pantalla y lógica duplicada; se prefirió que la API entregue el dato listo.

## Consecuencias

- **Positivas:** la interfaz corresponde a la regla de negocio; el auxiliar tiene en una sola
  pestaña lo que debe atender; la app se reconoce como parte del ecosistema UTB.
- **Negativas:** más efectos visuales (desenfoques, sombras) cuestan algo de rendimiento en
  equipos de gama baja; las propiedades `salon_nombre` cargan la relación del salón (consulta
  extra por fila si no se usa `joinedload`), aceptable con los volúmenes del campus.

## Trazabilidad

| Decisión | Código | Prueba |
|---|---|---|
| Nombres reales de salón | `app/models/recurso_models.py`, `app/models/salon_models.py` | `tests/test_salones_admin.py::test_recurso_expone_el_codigo_real_del_salon`, `frontend/test/control_test.dart` |
| Reportes de todos los salones | `app/routers/salones_admin.py` (`GET /salones/reportes`) | `tests/test_salones_admin.py::test_reportes_de_todos_los_salones_traen_nombre_del_salon` |
| Pestaña Control | `frontend/lib/features/control/` | `frontend/test/control_test.dart` |
| Lenguaje visual | `frontend/lib/shared/utb_ui.dart`, `frontend/lib/core/theme/app_theme.dart` | revisión visual (capturas) |

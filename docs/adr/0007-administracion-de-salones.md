# 0007 - Administración de salones: ocupación en vivo, presencia del profesor y reportes

## Estado

Aceptado

## Contexto

La ficha del problema pide que el auxiliar sepa, en cualquier momento, **quién tiene cada
salón**, pueda **informar si el profesor llegó** a su clase y **reportar novedades** del salón.
Hasta ahora el backend solo exponía el CRUD de salones, los horarios académicos y las solicitudes
de préstamo de salón; ninguno responde "¿quién lo tiene ahora?" y no existía el concepto de
presencia del profesor ni de reporte de salón (los reportes eran solo de recursos).

La app móvil necesita esa respuesta en una sola llamada: pedirle al cliente que cruce horarios,
préstamos y nombres de usuario por separado multiplicaría las peticiones y dejaría la regla de
negocio en Flutter.

## Decisión

Se agrega al módulo de salones (monolito modular, ADR-0001) un submódulo de administración con:

- `GET /salones/ocupacion` y `GET /salones/{id}/ocupacion`: calculan en el servidor el estado
  vivo de cada salón (`libre | clase | prestamo`), con la clase en curso, el préstamo vigente
  (con el nombre de quien lo tiene), el estado de presencia del profesor y los contadores de
  solicitudes pendientes y reportes abiertos. Solo auxiliar/administrador.
- `PUT /salones/{id}/presencia`: registra si el profesor llegó. Es **un registro por clase y
  fecha** (restricción única `horario_id + fecha`), así que corregir una marca no la duplica.
  Responde 409 si no hay clase en curso.
- `POST|GET /salones/{id}/reportes` y `PATCH /salones/{id}/reportes/{reporte_id}`: cualquier
  usuario autenticado reporta; solo auxiliar/administrador resuelve o reabre.
- Migración Alembic `7d1e2f3a4b5c` con las tablas `presencias_salon` y `reportes_salon`.

El reloj del campus es **UTC-5 fijo** (Colombia no tiene horario de verano): los horarios
académicos se guardan como hora local, y los préstamos de salón como UTC sin zona. El servicio
convierte entre ambos; el parámetro opcional `momento` permite consultar otra hora y hace las
pruebas deterministas.

En el cliente Flutter la funcionalidad vive en `features/salones_admin/` con la misma
estructura domain / data / presentation del resto de la app. Para el auxiliar, la pestaña
"Salones" muestra el panel (plano + hoja arrastrable); el usuario UTB conserva la pantalla de
consulta y solicitud existente.

## Alternativas consideradas

**Que el cliente calcule la ocupación** con `GET /horarios`, `GET /prestamos-salon` y
`GET /auth/user/{id}`. Se descartó: N+1 peticiones por pantalla, la hora local del campus y la
regla "clase gana sobre préstamo" quedarían duplicadas en Dart, y los usuarios corrientes
tendrían que poder leer datos que hoy solo ve el auxiliar.

**Guardar la presencia en `horarios`** (un campo `profesor_presente`). Se descartó porque un
horario se repite cada semana: la presencia es un hecho de un día concreto, no del horario.

**Notificar por correo cuando el profesor no llega** (outbox, ADR-0006). Queda fuera de este
ADR; la marca de presencia ya queda registrada y puede publicarse como evento después.

## Consecuencias

**Se gana:** el panel del auxiliar se pinta con una sola petición (`/salones/ocupacion`); la
regla de "quién tiene el salón" tiene un único dueño (el backend) y está cubierta por pruebas
(`tests/test_salones_admin.py`).

**Se asume:** `/salones/ocupacion` hace varias consultas por salón; con pocas decenas de
salones es aceptable, pero habría que consolidarlas en una consulta con joins si el campus crece
a cientos. Las rutas nuevas se registran **antes** del router de salones para que
`/salones/ocupacion` no se interprete como `/salones/{salon_id}`.

**Deuda aceptada a sabiendas:** el contrato congelado `docs/contracts/openapi.json` todavía no
incluye estas rutas; la prueba de contrato solo exige que lo ya prometido siga existiendo, así
que no se rompe, pero conviene regenerarlo cuando el equipo congele la siguiente versión. La app
refresca el panel cada 30 segundos (sondeo), no por eventos.

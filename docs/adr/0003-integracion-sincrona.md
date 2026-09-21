# 0003 - Estrategia de integración: síncrona (REST sobre HTTP)

## Estado

Aceptado

## Contexto

El cliente Flutter y el backend FastAPI son dos programas separados que solo se comunican por
red (ver ADR-0002). Hay que decidir explícitamente cómo se comunican: **síncrono** (el cliente
espera la respuesta antes de continuar, como en una llamada HTTP normal) o **asíncrono** (el
cliente dispara la solicitud y sigue, y la respuesta/confirmación llega después por otro
canal — colas, eventos, notificaciones push).

Esto pesa directamente sobre QS-06 (confiabilidad de los datos): la regla de negocio central
del sistema — *"un recurso solo puede prestarse si está disponible"* — depende de que el
cliente sepa, en el mismo momento en que hace la solicitud, si el préstamo se aceptó o se
rechazó. También pesa QS-05 (usabilidad): el auxiliar necesita ver el resultado de su acción
de inmediato, sin esperar una notificación que llegue después.

## Decisión

Toda la comunicación entre el cliente Flutter y la API FastAPI es **síncrona**, sobre HTTP con
petición/respuesta REST — el mismo modelo que ya usa el corte vertical de préstamos
(`POST /prestamos` responde 201 o 409 en la misma llamada, nunca "se procesará después").

## Alternativas consideradas

**Asíncrono con cola de mensajes (ej. procesar el préstamo en segundo plano y notificar por
otro canal cuándo se confirma).** Se descartó porque rompe directamente el escenario QS-06: si
el auxiliar no sabe en el momento si el préstamo se aceptó, dos personas podrían intentar
prestar el mismo recurso casi a la vez sin que ninguna se entere del conflicto de inmediato —
justo el problema que el corte vertical de S4 evita al resolver la validación de estado en la
misma transacción. Async tiene sentido cuando el resultado puede esperar (por ejemplo, un
reporte que se genera en segundo plano); prestar un recurso no es ese caso.

**Asíncrono para las notificaciones (correo de confirmación/recordatorio) mientras el resto
sigue síncrono.** Esta sí es una alternativa razonable a futuro, pero queda fuera del alcance
de este ADR porque las notificaciones automáticas todavía no están confirmadas como parte del
alcance del proyecto (ver discrepancia pendiente entre arc42 sección 3 y el documento de idea,
sección 4). Si se confirman, ese canal específico sí ameritaría su propio ADR evaluando
asíncrono para esa pieza puntual — sin que eso cambie esta decisión para el resto de la API.

## Consecuencias

**Se gana:** el cliente Flutter siempre sabe, en la misma interacción, si su acción tuvo éxito
o no — necesario para QS-05 (usabilidad, "completa el registro... en su primer intento") y
QS-06 (confiabilidad). El modelo mental es simple: una petición, una respuesta, sin estados
intermedios que rastrear en el cliente.

**Se asume:** bajo alta concurrencia real (QS-03, 300 usuarios simultáneos), cada petición
síncrona mantiene una conexión abierta hasta responder — no hay forma de "encolar y procesar
después" para absorber picos de carga. Esto es aceptable para el volumen esperado de un campus
universitario, pero sería una limitación real si el sistema creciera mucho más.

**Deuda aceptada a sabiendas:** ninguna operación de este sistema hoy necesita ser asíncrona
por su propia naturaleza (no hay procesamiento pesado, no hay integración con sistemas
externos lentos). Si eso cambia — por ejemplo, si se agrega generación de reportes grandes o
integración con un sistema externo que responda lento — habrá que revisar esta decisión con su
propio ADR, no forzar esas operaciones dentro del modelo síncrono actual.

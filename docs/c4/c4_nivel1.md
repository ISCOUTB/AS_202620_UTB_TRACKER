# Diagrama de Contexto (C4 - Nivel 1) - UTB Tracker

Actualizado el 2026-11-16 (ADR-0018 a ADR-0023). UTB Tracker administra los **salones** del
Campus Tecnológico de la UTB.

- Los salones **sí se solicitan**.
- Los equipos son **fijos** en cada salón y **no se prestan** (ADR-0010). Solo se controla su
  estado.

Los roles son etiquetas sobre los valores que ya estaban guardados (ADR-0018):

| Valor guardado | Etiqueta |
|---|---|
| `usuario_utb` | Estudiante |
| `auxiliar` | Auditor |
| `administrador` | Administrador |

"Auditor" es un **rol**. No tiene que ver con la bitácora de auditoría.

```mermaid
C4Context
    title Diagrama de Contexto de Nivel 1 - UTB Tracker

    Person(estudiante, "Estudiante", "Busca salones por tipo y equipamiento, los solicita y sigue sus solicitudes.")
    Person(auditor, "Auditor (auxiliar de planta)", "Administra los salones: ocupación, presencia del profesor, solicitudes, habilitación, equipos y reportes.")
    Person(admin, "Administrador", "Todo lo del Auditor más catálogo de salones, usuarios y roles, bitácora y estadísticas.")

    System(utbTracker, "UTB Tracker", "App móvil y API para administrar y solicitar los salones del campus.")
    System_Ext(correo, "Servidor de correo (SMTP)", "Verificación de cuentas y avisos de solicitudes y salones deshabilitados.")
    System_Ext(fcm, "Firebase Cloud Messaging", "Notificaciones push (opcional).")

    Rel(estudiante, utbTracker, "Solicita salones, cancela y consulta sus solicitudes", "HTTPS")
    Rel(auditor, utbTracker, "Aprueba o rechaza, habilita salones y cambia el estado de los equipos", "HTTPS")
    Rel(admin, utbTracker, "Gestiona catálogo, usuarios, roles y bitácora", "HTTPS")
    Rel(utbTracker, correo, "Envía correos desde el outbox", "SMTP")
    Rel(utbTracker, fcm, "Envía notificaciones push", "HTTPS")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

Correspondencia con el código:

| Elemento del diagrama | Dónde está en el código |
|---|---|
| Personas | `app/middleware/permisos.py` (tabla rol → permisos) |
| Sistema UTB Tracker | `app/` y `frontend/` |
| Correo | `app/service/correo.py` y `app/messaging/worker.py` |
| Push | `NotificadorFCM` en `app/messaging/worker.py` |

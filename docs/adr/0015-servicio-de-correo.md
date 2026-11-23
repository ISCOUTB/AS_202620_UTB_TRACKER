# 0015 - Servicio de correo con plantillas y entrega por el outbox

## Estado

Aceptado (2026-11-14). Extiende ADR-0006 (outbox) a todos los correos de la cuenta.

## Contexto

El worker del outbox (ADR-0006) solo sabía mandar texto plano para préstamos y un "token" de
recuperación, el SMTP estaba apagado por defecto y en el servidor oficial el worker ni siquiera
se levantaba. Con ADR-0014 hacen falta correos que **deben** llegar: verificación, recuperación,
cambio de correo y avisos de seguridad.

## Decisión

1. **Interfaz única** `app/service/correo.py::enviar(destino, plantilla, datos)`. Los servicios
   no envían: llaman a `encolar(...)`, que escribe el evento `correo.enviar` en `mensajes_outbox`
   **en la misma transacción** del cambio. Si la transacción se revierte, no sale correo.
2. **Proveedores:** `ProveedorSMTP` (STARTTLS, `USE_REAL_MAIL=true` + `SMTP_*`) y
   `ProveedorDesarrollo`, que no envía: guarda el correo completo (`.eml` + `.html`) en
   `CORREOS_DIR` (`logs/correos/`, fuera de git) y escribe en el log la ruta y el enlace. Así
   se prueba todo el flujo sin cuenta de correo.
3. **Plantillas en español** (`app/service/plantillas_correo.py`), HTML + texto plano, con el
   verde `#187943` y el índigo `#332D83` del Manual de identidad UTB: verificación, bienvenida,
   recuperación, cambio de correo (al nuevo y aviso al anterior), cambio de contraseña e inicio
   de sesión sospechoso. Cada plantilla tiene una **categoría** (`seguridad` o `cuenta`); las de
   seguridad se envían siempre, las demás según las preferencias del usuario (Fase 2).
4. **Seguridad:** todo dato se escapa con `html.escape`; solo se aceptan enlaces http(s); el
   destino se valida y `EmailMessage` rechaza saltos de línea en cabeceras (sin inyección de
   cabeceras); el worker nunca escribe el payload en el log, y el proveedor de desarrollo solo
   escribe el enlace cuando `ENVIRONMENT != production`.
5. **Entrega fiable y rápida:** el worker reintenta con backoff exponencial (2, 4, 8… s; 5
   intentos y luego `muerto`). Un error de datos (destino o plantilla inválidos) se marca
   `muerto` sin reintentar. El intervalo de sondeo baja a `WORKER_POLL_INTERVAL=3` s: el correo
   de verificación llega en unos segundos, así que **no hace falta** enviarlo de forma síncrona
   desde la API (eso volvería a acoplar la disponibilidad del registro a la del SMTP, el problema
   que resolvió ADR-0006).
6. **El worker se levanta en los tres entornos:** ventana propia en `iniciar.ps1` (y `detener.ps1`
   lo apaga), servicio `worker` en `docker-compose.yml` con las mismas variables que la API, y
   en el servidor oficial un servicio systemd `utb-tracker-worker` que el CI reinicia
   (`docs/despliegue/worker.md`).

## Alternativas consideradas

- **Envío síncrono en la petición de registro:** correo en < 1 s, pero un SMTP lento o caído
  tumbaría el registro y no habría reintentos.
- **Servicio transaccional por API HTTP (SendGrid, Mailgun):** mejor entregabilidad, pero exige
  cuenta de pago o dominio propio y un paquete o cliente nuevo. SMTP funciona con cualquiera de
  ellos sin código nuevo.
- **Plantillas con Jinja2:** más cómodas, pero es un paquete nuevo. Con funciones Python y
  `html.escape` bastó.

## Consecuencias

- **Positivas:** un solo camino para todos los correos, con reintentos y prueba sin SMTP.
- **Negativas:** el outbox guarda los enlaces (con tokens) mientras no se entregan; la base ya
  está protegida igual que las contraseñas, y los tokens vencen en horas. Hay que crear la cuenta
  de envío y el servicio systemd en el servidor (pasos en `docs/despliegue/worker.md`).

## Trazabilidad

| Decisión | Código | Pruebas |
|---|---|---|
| Interfaz y proveedores | `app/service/correo.py` | `tests/test_correo_servicio.py` |
| Plantillas y escapado | `app/service/plantillas_correo.py` | `test_plantilla_escapa_html`, `test_no_permite_inyeccion_de_cabeceras` |
| Worker y reintentos | `app/messaging/worker.py::_procesar_correo` | `test_worker_reintenta_si_el_proveedor_falla`, `test_el_log_del_worker_no_incluye_el_token` |
| Despliegue | `iniciar.ps1`, `detener.ps1`, `docker-compose.yml`, `.github/workflows/ci.yml`, `docs/despliegue/worker.md` | revisión manual |

# Correo real y worker en el servidor oficial (ADR-0015)

El servidor oficial es `https://129-80-171-141.nip.io` (lo usan el APK y `.\iniciar.ps1 -Nube`).
Los correos (recuperación de contraseña, avisos de seguridad) los envía el **worker**: un
proceso aparte que lee la tabla `mensajes_outbox`. Si el worker no corre, los correos quedan
guardados en la base y **no salen**. Hoy el despliegue del CI solo reinicia la API.

## 1. Variables nuevas en el `.env` del servidor

Antes de unir esta rama a `main`, agrega al `.env` del servidor (fuera del repositorio):

```bash
ENVIRONMENT=production
# Cada secreto, distinto y largo:  python3 -c "import secrets; print(secrets.token_urlsafe(48))"
FORGET_PWD_SECRET_KEY=<secreto 1>
URL_PUBLICA=https://129-80-171-141.nip.io
USE_REAL_MAIL=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=<la cuenta que envía>@gmail.com
SMTP_PASSWORD=<contraseña de aplicación>
SMTP_FROM=UTB Tracker <la cuenta que envía@gmail.com>
WORKER_POLL_INTERVAL=3
```

> **Se puede desplegar antes de tener estas variables**: sin `URL_PUBLICA` se usa el servidor
> oficial y sin `USE_REAL_MAIL=true` los correos no se envían (quedan en `logs/correos`). Desde
> ADR-0024 **no hay verificación de correo**: registrarse funciona sin correo real. El correo real
> solo hace falta para recuperar la contraseña y los avisos de seguridad.
>
> Con `ENVIRONMENT=production` la API **no arranca** si `SECRET_KEY` o `FORGET_PWD_SECRET_KEY`
> quedan con su valor por defecto, o si `URL_PUBLICA` está definida y no es
> `https://`. Es intencional: así nunca se firman enlaces con un secreto público.

## 2. Proveedor de correo recomendado

Para un proyecto de curso con poco volumen (menos de 100 correos al día), lo más simple es una
**cuenta de Gmail dedicada** (por ejemplo `utbtracker.notificaciones@gmail.com`) con una
**contraseña de aplicación**. Si la Universidad da una cuenta institucional de Microsoft 365
con SMTP habilitado, también sirve (`smtp.office365.com`, puerto 587). Para más volumen o mejor
entregabilidad conviene un servicio transaccional (Brevo, Mailgun, Amazon SES) con dominio
propio y SPF/DKIM.

Pasos exactos con Gmail:

1. Crea la cuenta de Gmail que enviará los correos.
2. Entra a <https://myaccount.google.com/security> y activa la **Verificación en 2 pasos**
   (es obligatoria para lo siguiente).
3. Entra a <https://myaccount.google.com/apppasswords>, escribe el nombre "UTB Tracker" y toca
   **Crear**. Google muestra una contraseña de 16 letras: cópiala **sin espacios** en
   `SMTP_PASSWORD`. No es la contraseña normal de la cuenta, y solo sirve para enviar correo.
4. Nunca subas esa contraseña al repositorio: va solo en el `.env` del servidor.

## 3. Servicio systemd del worker

Crea `/etc/systemd/system/utb-tracker-worker.service` (ajusta `User` y la carpeta
`WorkingDirectory` a los mismos del servicio `utb-tracker`):

```ini
[Unit]
Description=UTB Tracker - worker del outbox (correos y notificaciones)
After=network-online.target postgresql.service

[Service]
User=ubuntu
WorkingDirectory=/ruta/al/repo
EnvironmentFile=/ruta/al/repo/.env
ExecStart=/ruta/al/repo/venv/bin/python -m app.messaging
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now utb-tracker-worker
sudo journalctl -u utb-tracker-worker -f   # ver que diga: Iniciando ... correo=ProveedorSMTP
```

El job `deploy` del CI reinicia este servicio si existe, y si no existe deja un aviso en el log.

## 4. Comprobar

1. Regístrate en la app con un correo tuyo y espera unos segundos: debe llegar "Confirma tu correo".
2. Si no llega: `journalctl -u utb-tracker-worker` muestra `FALLO ... error=` con la causa. Los
   correos que no se pueden entregar quedan en `mensajes_outbox` con `estado='muerto'` y
   `ultimo_error`.

"""
Configuración centralizada del proyecto UTB Tracker.

Lee variables de entorno con compatibilidad hacia atrás para nombres
legacy (JWT_ALGORITHM, JWT_EXPIRE_MINUTES) y los nombres actuales.
"""
import hashlib
import hmac
import logging
import os

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("utb_tracker")

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./utb_tracker.db")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").strip().lower()

SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
# Acepta JWT_ALGORITHM (legacy) y ALGORITHM (actual) para compatibilidad
ALGORITHM = os.getenv("JWT_ALGORITHM", os.getenv("ALGORITHM", "HS256"))
ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("JWT_EXPIRE_MINUTES", os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
)
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
FORGET_PWD_SECRET_KEY = os.getenv(
    "FORGET_PWD_SECRET_KEY", "change-me-in-production-reset"
)

# Firma los tokens de verificación y de cambio de correo (distinta de SECRET_KEY y de la de
# recuperación: un token de un propósito nunca sirve para otro). ADR-0014.
# Si no está definida se DERIVA de SECRET_KEY (HMAC con una etiqueta fija): sigue siendo secreta
# y distinta de ella, y un servidor que aún no la tiene en su .env arranca igual (ADR-0014).
EMAIL_TOKEN_SECRET_KEY = os.getenv("EMAIL_TOKEN_SECRET_KEY", "").strip() or (
    "derivada:" + hmac.new(
        SECRET_KEY.encode(), b"utb-tracker:tokens-de-correo", hashlib.sha256
    ).hexdigest()
)
VERIFICACION_EXPIRA_HORAS = int(os.getenv("VERIFICACION_EXPIRA_HORAS", "24"))
RECUPERACION_EXPIRA_MINUTOS = int(os.getenv("RECUPERACION_EXPIRA_MINUTOS", "30"))
CAMBIO_CORREO_EXPIRA_HORAS = int(os.getenv("CAMBIO_CORREO_EXPIRA_HORAS", "24"))

LOGIN_RATE_LIMIT = int(os.getenv("LOGIN_RATE_LIMIT", "5"))
LOGIN_RATE_WINDOW_SECONDS = int(os.getenv("LOGIN_RATE_WINDOW_SECONDS", "300"))
# Endpoints que envían correo: máximo N por ventana (por cuenta/correo y por IP).
CORREO_RATE_LIMIT = int(os.getenv("CORREO_RATE_LIMIT", "3"))
CORREO_RATE_WINDOW_SECONDS = int(os.getenv("CORREO_RATE_WINDOW_SECONDS", "900"))

# El correo real es opt-in deliberado.  En desarrollo y pruebas se mantiene
# siempre el notificador simulado aunque exista configuración SMTP parcial.
USE_REAL_MAIL = os.getenv("USE_REAL_MAIL", "false").strip().lower() in (
    "1", "true", "yes", "on"
)

# Base de los enlaces que van en los correos (dónde se abre /auth/verificar-correo).
# Sin la variable, en producción o con correo real se usa la dirección del servidor oficial
# (un enlace a 127.0.0.1 no le sirve a quien lo recibe en su correo).
SERVIDOR_OFICIAL = "https://129-80-171-141.nip.io"
URL_PUBLICA = os.getenv(
    "URL_PUBLICA",
    SERVIDOR_OFICIAL if ENVIRONMENT == "production" or USE_REAL_MAIL else "http://127.0.0.1:8000",
).strip().rstrip("/")
# Modo desarrollo del correo: carpeta donde se guardan los correos que NO se envían.
CORREOS_DIR = os.getenv("CORREOS_DIR", "logs/correos")

# ¿Las cuentas nuevas deben confirmar su correo antes de solicitar salones? Por defecto, solo si
# hay correo real: sin él el enlace nunca llegaría y la persona quedaría bloqueada, así que la
# cuenta nace verificada (como las que existían antes de ADR-0014). iniciar.ps1, Docker Compose
# y las pruebas la activan con el correo de desarrollo (logs/correos).
_verif_env = os.getenv("VERIFICACION_OBLIGATORIA", "").strip().lower()
VERIFICACION_OBLIGATORIA = (
    _verif_env in ("1", "true", "yes", "on") if _verif_env else USE_REAL_MAIL
)
SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM = os.getenv("SMTP_FROM", "")
FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
USE_REAL_PUSH = os.getenv("USE_REAL_PUSH", "false").strip().lower() in (
    "1", "true", "yes", "on"
)

# ---------------------------------------------------------------------------
# Advertencia de seguridad — claves por defecto inseguras (#5)
# Se emite al arrancar para que sea visible en los logs desde el inicio.
# ---------------------------------------------------------------------------
_INSECURE_DEFAULT = "change-me-in-production"
if SECRET_KEY == _INSECURE_DEFAULT:
    logger.warning(
        "⚠️  SECRET_KEY tiene el valor por defecto inseguro. "
        "Define la variable de entorno SECRET_KEY antes de desplegar en producción."
    )
if FORGET_PWD_SECRET_KEY.startswith(_INSECURE_DEFAULT):
    logger.warning(
        "⚠️  FORGET_PWD_SECRET_KEY tiene el valor por defecto inseguro. "
        "Define la variable de entorno FORGET_PWD_SECRET_KEY antes de desplegar en producción."
    )
if ENVIRONMENT == "production":
    if not URL_PUBLICA.startswith("https://"):
        raise RuntimeError("URL_PUBLICA debe ser https:// en producción (enlaces de los correos)")
    if SECRET_KEY == _INSECURE_DEFAULT:
        raise RuntimeError("SECRET_KEY debe configurarse antes de iniciar en producción")
    if FORGET_PWD_SECRET_KEY.startswith(_INSECURE_DEFAULT):
        raise RuntimeError(
            "FORGET_PWD_SECRET_KEY debe configurarse antes de iniciar en producción"
        )
    if DATABASE_URL.startswith("sqlite"):
        raise RuntimeError("Producción requiere DATABASE_URL de PostgreSQL")
    if not USE_REAL_MAIL:
        logger.warning(
            "USE_REAL_MAIL=false en producción: los correos NO se envían (quedan en %s). "
            "Ver docs/despliegue/worker.md", CORREOS_DIR,
        )
    if not VERIFICACION_OBLIGATORIA:
        logger.warning(
            "VERIFICACION_OBLIGATORIA=false: las cuentas nuevas no confirman su correo. "
            "Configura el correo real (docs/despliegue/worker.md) para activarla."
        )

# ---------------------------------------------------------------------------
# CORS origins — separados por coma en la variable de entorno CORS_ORIGINS.
# Por defecto incluye los puertos más comunes de desarrollo local (#2).
# ---------------------------------------------------------------------------
_cors_env = os.getenv("CORS_ORIGINS", "").strip()
if _cors_env:
    CORS_ORIGINS = [o.strip() for o in _cors_env.split(",") if o.strip()]
else:
    CORS_ORIGINS = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5000",
        "http://127.0.0.1:5000",
        "http://localhost:7000",
        "http://127.0.0.1:7000",
        "http://localhost:8080",   # Flutter web dev
        "http://127.0.0.1:8080",
        "http://localhost:8000",   # Uvicorn por defecto
        "http://127.0.0.1:8000",
    ]

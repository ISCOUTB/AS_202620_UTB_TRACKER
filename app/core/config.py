"""
Configuración centralizada del proyecto UTB Tracker.

Lee variables de entorno con compatibilidad hacia atrás para nombres
legacy (JWT_ALGORITHM, JWT_EXPIRE_MINUTES) y los nombres actuales.
"""
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

LOGIN_RATE_LIMIT = int(os.getenv("LOGIN_RATE_LIMIT", "5"))
LOGIN_RATE_WINDOW_SECONDS = int(os.getenv("LOGIN_RATE_WINDOW_SECONDS", "300"))

# El correo real es opt-in deliberado.  En desarrollo y pruebas se mantiene
# siempre el notificador simulado aunque exista configuración SMTP parcial.
USE_REAL_MAIL = os.getenv("USE_REAL_MAIL", "false").strip().lower() in (
    "1", "true", "yes", "on"
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
if FORGET_PWD_SECRET_KEY == _INSECURE_DEFAULT:
    logger.warning(
        "⚠️  FORGET_PWD_SECRET_KEY tiene el valor por defecto inseguro. "
        "Define la variable de entorno FORGET_PWD_SECRET_KEY antes de desplegar en producción."
    )
if ENVIRONMENT == "production":
    if SECRET_KEY == _INSECURE_DEFAULT:
        raise RuntimeError("SECRET_KEY debe configurarse antes de iniciar en producción")
    if FORGET_PWD_SECRET_KEY == _INSECURE_DEFAULT:
        raise RuntimeError(
            "FORGET_PWD_SECRET_KEY debe configurarse antes de iniciar en producción"
        )
    if DATABASE_URL.startswith("sqlite"):
        raise RuntimeError("Producción requiere DATABASE_URL de PostgreSQL")

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

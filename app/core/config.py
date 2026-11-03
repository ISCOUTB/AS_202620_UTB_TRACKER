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

SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
# Acepta JWT_ALGORITHM (legacy) y ALGORITHM (actual) para compatibilidad
ALGORITHM = os.getenv("JWT_ALGORITHM", os.getenv("ALGORITHM", "HS256"))
ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("JWT_EXPIRE_MINUTES", os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
)
FORGET_PWD_SECRET_KEY = os.getenv(
    "FORGET_PWD_SECRET_KEY", "change-me-in-production"
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

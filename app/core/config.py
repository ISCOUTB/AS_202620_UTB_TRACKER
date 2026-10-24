"""
Configuración centralizada del proyecto UTB Tracker.

Lee variables de entorno con compatibilidad hacia atrás para nombres
legacy (JWT_ALGORITHM, JWT_EXPIRE_MINUTES) y los nombres actuales.
"""
import os

from dotenv import load_dotenv

load_dotenv()

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
# CORS origins (separados por coma; por defecto orígenes locales seguros si no se define)
_cors_env = os.getenv("CORS_ORIGINS", "").strip()
if _cors_env:
    CORS_ORIGINS = [o.strip() for o in _cors_env.split(",") if o.strip()]
else:
    CORS_ORIGINS = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ]


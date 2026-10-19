"""
Configuración de base de datos y pool de conexiones (S8 / S11).

Resiliencia (S11 — req. 11.1):
- pool_size=10, max_overflow=20: maneja hasta 30 conexiones simultáneas bajo picos.
- pool_timeout=30: tiempo máximo de espera para obtener una conexión del pool.
- pool_recycle=1800: renueva conexiones cada 30 minutos para evitar conexiones muertas.
- pool_pre_ping=True: sondea la conexión antes de entregarla al request, descartando
  conexiones caídas por timeouts del firewall o reinicios del servidor Postgres.
- Compatibilidad condicional: SQLite en desarrollo local / PostgreSQL en CI y producción.
"""
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./utb_tracker.db")

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},
    )
else:
    # Configuración de alta resiliencia para PostgreSQL (S11 req. 11.1)
    engine = create_engine(
        DATABASE_URL,
        pool_size=10,
        max_overflow=20,
        pool_timeout=30,
        pool_recycle=1800,
        pool_pre_ping=True,
        connect_args={"connect_timeout": 5},
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

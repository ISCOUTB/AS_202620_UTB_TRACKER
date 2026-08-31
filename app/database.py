"""
Configuracion de la base de datos.

Para desarrollo y CI se usa SQLite (archivo local, sin dependencias
externas). En despliegue real se apunta a PostgreSQL cambiando la
variable de entorno DATABASE_URL - el codigo de la aplicacion no
cambia porque SQLAlchemy abstrae el motor.

Las migraciones con Alembic quedan pendientes para la siguiente
entrega; por ahora el esquema se crea con Base.metadata.create_all()
al arrancar, que alcanza para un corte vertical de demostracion.
"""
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./utbtracker.db")

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

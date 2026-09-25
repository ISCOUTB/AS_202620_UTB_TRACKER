"""
Configuracion de la base de datos.


Las migraciones con Alembic quedan pendientes para la siguiente
entrega; por ahora el esquema se crea con Base.metadata.create_all()
al arrancar, que alcanza para un corte vertical de demostracion.
"""
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()
DATABASE_URL = os.environ["DATABASE_URL"]

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

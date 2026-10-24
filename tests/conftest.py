"""Fixtures compartidos para pruebas contra PostgreSQL aislado.

Estrategia:
- Usa TEST_DATABASE_URL (utbtracker_test) — mismo motor que producción,
  BD completamente separada. NUNCA toca utbtracker (producción).
- Crea la BD de pruebas automáticamente si no existe.
- Cada test arranca con drop_all → create_all: aislamiento total,
  sin contaminación entre corridas ni entre tests.
"""
import os

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app
from app.models.auth_models import Usuario

load_dotenv()

TEST_DATABASE_URL = os.environ["TEST_DATABASE_URL"]


def _ensure_test_db_exists(test_url: str) -> None:
    """Crea la base de datos de pruebas si aún no existe.

    Se conecta a la BD de mantenimiento 'postgres' (siempre disponible)
    y emite CREATE DATABASE ... IF NOT EXISTS.
    """
    # Extraer nombre de la BD y construir URL de mantenimiento
    db_name = test_url.rsplit("/", 1)[-1]
    maintenance_url = test_url.rsplit("/", 1)[0] + "/postgres"

    engine = create_engine(maintenance_url, isolation_level="AUTOCOMMIT")
    with engine.connect() as conn:
        exists = conn.execute(
            text("SELECT 1 FROM pg_database WHERE datname = :name"),
            {"name": db_name},
        ).fetchone()
        if not exists:
            conn.execute(text(f'CREATE DATABASE "{db_name}"'))
    engine.dispose()


# Crear la BD de pruebas una sola vez al arrancar la sesión de pytest
_ensure_test_db_exists(TEST_DATABASE_URL)


@pytest.fixture
def client():
    engine = create_engine(TEST_DATABASE_URL)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    # Tablas limpias antes de cada test → aislamiento total
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    # Datos base reutilizables (sin IDs explícitos — la secuencia PK no se desfasa)
    db = TestingSessionLocal()
    db.add_all([
        Usuario(nombre="Usuario de prueba 1", email="user1@utb.edu.co", password="hashed_password", rol="usuario_utb"),
        Usuario(nombre="Usuario de prueba 2", email="user2@utb.edu.co", password="hashed_password", rol="usuario_utb"),
    ])
    db.commit()
    db.close()

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    engine.dispose()


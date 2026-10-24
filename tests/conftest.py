"""Fixtures compartidos para pruebas contra PostgreSQL aislado.

Estrategia:
- Usa TEST_DATABASE_URL — mismo motor que producción, BD separada.
  NUNCA toca DATABASE_URL (producción).
- En CI: el servicio Postgres del runner ya crea la BD; no hace falta
  crearla desde aquí.
- En local: el desarrollador crea la BD una sola vez (ver README).
- Cada test arranca con drop_all → create_all: aislamiento total,
  sin contaminación entre corridas ni entre tests.
"""
import os

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.main import app
from app.models.auth_models import Usuario

load_dotenv()

TEST_DATABASE_URL = (os.environ.get("TEST_DATABASE_URL") or "").strip()
if not TEST_DATABASE_URL:
    TEST_DATABASE_URL = (os.environ.get("DATABASE_URL") or "").strip()

if not TEST_DATABASE_URL:
    raise RuntimeError(
        "Debe configurar TEST_DATABASE_URL o DATABASE_URL en las variables de entorno."
    )


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

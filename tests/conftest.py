"""Fixtures compartidos para pruebas contra PostgreSQL aislado.

Estrategia:
- Usa TEST_DATABASE_URL — mismo motor que producción, BD separada.
  NUNCA toca DATABASE_URL (producción).
- En CI: el servicio Postgres del runner ya crea la BD; no hace falta
  crearla desde aquí.
- En local: el desarrollador crea la BD una sola vez (ver README).
- Cada test arranca con drop_all → create_all: aislamiento total,
  sin contaminación entre corridas ni entre tests.

Mejoras:
- Fixture auth_headers para tests que requieren autenticación JWT.
- Fixture admin_headers para tests que requieren rol admin.
- Soporte para SQLite en local si no hay TEST_DATABASE_URL.
"""
import os

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.core.hashing import hash_password
from app.main import app
from app.models.auth_models import Usuario

# Importar todos los modelos para que Base.metadata los registre
from app.models import recurso_models, salon_models  # noqa: F401
from app.messaging import models as messaging_models  # noqa: F401

load_dotenv()

TEST_DATABASE_URL = (os.environ.get("TEST_DATABASE_URL") or "").strip()
if not TEST_DATABASE_URL:
    TEST_DATABASE_URL = (os.environ.get("DATABASE_URL") or "").strip()

# Fallback a SQLite para ejecución local sin configuración
if not TEST_DATABASE_URL:
    TEST_DATABASE_URL = "sqlite:///./test_utb_tracker.db"


@pytest.fixture
def client():
    if TEST_DATABASE_URL.startswith("sqlite"):
        engine = create_engine(
            TEST_DATABASE_URL, connect_args={"check_same_thread": False}
        )
    else:
        engine = create_engine(TEST_DATABASE_URL)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    # Tablas limpias antes de cada test → aislamiento total
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    # Datos base reutilizables (sin IDs explícitos — la secuencia PK no se desfasa)
    db = TestingSessionLocal()
    db.add_all([
        Usuario(
            nombre="Usuario de prueba 1",
            email="user1@utb.edu.co",
            password=hash_password("TestPassword1"),
            rol="usuario_utb",
        ),
        Usuario(
            nombre="Usuario de prueba 2",
            email="user2@utb.edu.co",
            password=hash_password("TestPassword2"),
            rol="usuario_utb",
        ),
        Usuario(
            nombre="Admin prueba",
            email="admin@utb.edu.co",
            password=hash_password("AdminPassword1"),
            rol="administrador",
        ),
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


def _get_token(client, nombre: str, password: str) -> str:
    """Helper: hace login y devuelve el token JWT."""
    response = client.post(
        "/auth/login",
        json={"nombre": nombre, "password": password},
    )
    assert response.status_code == 200, f"Login falló: {response.json()}"
    return response.json()["access_token"]


@pytest.fixture
def auth_headers(client) -> dict:
    """Headers con token JWT de un usuario regular (usuario_utb)."""
    token = _get_token(client, "Usuario de prueba 1", "TestPassword1")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_headers(client) -> dict:
    """Headers con token JWT de un usuario administrador."""
    token = _get_token(client, "Admin prueba", "AdminPassword1")
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def db_session(client):
    """Provee una sesión de base de datos aislada para aserciones en pruebas."""
    override = app.dependency_overrides.get(get_db)
    if override:
        gen = override()
        db = next(gen)
        try:
            yield db
        finally:
            try:
                next(gen)
            except StopIteration:
                pass
    else:
        gen = get_db()
        db = next(gen)
        try:
            yield db
        finally:
            try:
                next(gen)
            except StopIteration:
                pass

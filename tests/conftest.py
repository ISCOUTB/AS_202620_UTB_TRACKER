"""Fixtures compartidos para ejecutar las pruebas contra PostgreSQL."""
import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.models import Usuario

TEST_DATABASE_URL = os.environ["DATABASE_URL"]


@pytest.fixture()
def client():
    engine = create_engine(TEST_DATABASE_URL)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    db.add_all([
        Usuario(id=1, nombre="Usuario de prueba 1", rol="usuario_utb"),
        Usuario(id=2, nombre="Usuario de prueba 2", rol="usuario_utb"),
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

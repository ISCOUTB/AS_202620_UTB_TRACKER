"""
Un correo = una cuenta. Se comprueba en las tres capas: la regla de la API (409), el cambio de
correo, y el índice único de la base (que frena a dos registros simultáneos).
"""
import pytest
from sqlalchemy.exc import IntegrityError

from app.models.auth_models import Usuario
from app.services import auth as auth_service

CLAVE = "ClaveSegura1"  # noqa: S105 (solo pruebas)


def _registrar(client, email, nombre):
    return client.post("/auth/register", json={"nombre": nombre, "email": email, "password": CLAVE})


def test_el_mismo_correo_no_se_registra_dos_veces(client):
    assert _registrar(client, "ana@utb.edu.co", "Ana Uno").status_code == 201
    r = _registrar(client, "ana@utb.edu.co", "Ana Dos")
    assert r.status_code == 409
    assert "ya hay una cuenta" in r.json()["detail"].lower()


@pytest.mark.parametrize("variante", ["ANA@utb.edu.co", "Ana@UTB.EDU.CO", "  ana@utb.edu.co  "])
def test_mayusculas_y_espacios_son_el_mismo_correo(client, variante):
    assert _registrar(client, "ana@utb.edu.co", "Ana Uno").status_code == 201
    assert _registrar(client, variante, "Otra Persona").status_code == 409


def test_el_correo_de_una_cuenta_existente_del_seed_tampoco_se_repite(client):
    assert _registrar(client, "USER1@utb.edu.co", "Intruso").status_code == 409


def test_cambiar_el_correo_a_uno_ya_usado_da_409(client, auth_headers):
    r = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                    json={"correo_nuevo": "User2@UTB.edu.co", "password": "TestPassword1"})
    assert r.status_code == 409


def test_la_base_rechaza_dos_filas_con_el_mismo_correo(db_session):
    db_session.add(Usuario(nombre="Uno", email="dup@utb.edu.co", password="x"))
    db_session.commit()
    db_session.add(Usuario(nombre="Dos", email="DUP@utb.edu.co", password="x"))
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()


def test_dos_registros_simultaneos_dan_409_y_no_500(client, monkeypatch):
    """La carrera: ambos pasan la comprobación previa y los frena el índice único."""
    assert _registrar(client, "ana@utb.edu.co", "Ana Uno").status_code == 201
    monkeypatch.setattr(auth_service, "buscar_por_correo", lambda db, correo: None)
    r = _registrar(client, "ana@utb.edu.co", "Ana Dos")
    assert r.status_code == 409, r.text


def test_el_importador_de_roles_no_crea_cuentas(client, admin_headers, db_session):
    antes = db_session.query(Usuario).count()
    r = client.post("/usuarios/asignaciones/importar", headers=admin_headers,
                    json={"texto": "nuevo@utb.edu.co,Auditor"})
    assert r.status_code == 200
    db_session.expire_all()
    assert db_session.query(Usuario).count() == antes

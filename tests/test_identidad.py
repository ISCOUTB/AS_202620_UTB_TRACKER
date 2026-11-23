"""
Identidad de las cuentas (ADR-0014, Fase 0): correo normalizado y único sin distinguir
mayúsculas, login por correo o por nombre, política de contraseña y mensajes en español.
"""
from app.service.politica import (
    MSG_CLAVE_CORTA,
    MSG_CLAVE_IGUAL_CORREO,
    MSG_CLAVE_IGUAL_NOMBRE,
    error_password,
)
from app.models.auth_models import Usuario


def _registrar(client, nombre="Ana Pérez", email="ana@utb.edu.co", password="ClaveSegura1"):  # noqa: S107
    return client.post(
        "/auth/register", json={"nombre": nombre, "email": email, "password": password}
    )


def _mensajes(r):
    return [e["msg"] for e in r.json()["detail"]]


def test_correo_se_guarda_normalizado(client):
    r = _registrar(client, email="  Ana@UTB.edu.CO ")
    assert r.status_code == 201
    assert r.json()["email"] == "ana@utb.edu.co"


def test_mismo_correo_con_mayusculas_es_la_misma_cuenta(client):
    assert _registrar(client).status_code == 201
    r = _registrar(client, nombre="Otra Persona", email="ANA@utb.edu.co")
    assert r.status_code == 409
    assert "correo" in r.json()["detail"]


def test_nombre_repetido_sin_distinguir_mayusculas(client):
    assert _registrar(client).status_code == 201
    r = _registrar(client, nombre="ana   pérez", email="otra@utb.edu.co")
    assert r.status_code == 409


def test_login_por_correo_y_por_nombre(client):
    _registrar(client)
    for ident in ("Ana Pérez", "ana@utb.edu.co", " ANA@UTB.EDU.CO "):
        r = client.post("/auth/login", json={"nombre": ident, "password": "ClaveSegura1"})
        assert r.status_code == 200, ident
        assert r.json()["user"]["email"] == "ana@utb.edu.co"


def test_error_de_login_no_revela_si_la_cuenta_existe(client):
    _registrar(client)
    existe = client.post("/auth/login", json={"nombre": "ana@utb.edu.co", "password": "Mala1234"})
    no_existe = client.post("/auth/login", json={"nombre": "nadie@utb.edu.co", "password": "Mala1234"})
    assert existe.status_code == no_existe.status_code == 401
    assert existe.json()["detail"] == no_existe.json()["detail"]


def test_politica_de_contrasena_en_espanol(client):
    corta = _registrar(client, password="1234567")
    assert corta.status_code == 422
    assert "al menos 8 caracteres" in " ".join(_mensajes(corta))

    igual_correo = _registrar(client, password="ana@utb.edu.co")
    assert MSG_CLAVE_IGUAL_CORREO in _mensajes(igual_correo)

    igual_nombre = _registrar(client, nombre="Juanito Perez", password="juanito perez")
    assert MSG_CLAVE_IGUAL_NOMBRE in _mensajes(igual_nombre)


def test_politica_unidad():
    assert error_password("corta") == MSG_CLAVE_CORTA
    assert error_password("ana12345", correo="Ana12345@utb.edu.co") == MSG_CLAVE_IGUAL_CORREO
    assert error_password("ClaveSegura1", correo="ana@utb.edu.co", nombre="Ana") is None


def test_correo_con_salto_de_linea_se_rechaza(client):
    # Evita inyección de cabeceras en el correo saliente.
    r = _registrar(client, email="ana@utb.edu.co\nBcc: otro@x.com")
    assert r.status_code == 422


def test_campo_faltante_en_espanol(client):
    r = client.post("/auth/register", json={"nombre": "Sin correo", "password": "ClaveSegura1"})
    assert r.status_code == 422
    assert "Este campo es obligatorio" in _mensajes(r)


def test_indice_unico_frena_correos_repetidos_en_la_base(client, db_session):
    from sqlalchemy.exc import IntegrityError
    import pytest

    db_session.add(Usuario(nombre="Uno", email="dup@utb.edu.co", password="x", rol="usuario_utb"))
    db_session.commit()
    db_session.add(Usuario(nombre="Dos", email="DUP@utb.edu.co", password="x", rol="usuario_utb"))
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()

"""
Solo correos institucionales en registros y cambios de correo nuevos (ADR-0019, Fase 1).

La regla vive en app/core/politica.py (`error_correo_nuevo`) con la lista de
app/core/config.py (`DOMINIOS_PERMITIDOS`, por defecto "utb.edu.co"). Las cuentas antiguas con
otro dominio siguen entrando y el perfil les avisa.
"""
import pytest

from app.core import config
from app.core.hashing import hash_password
from app.core.politica import (
    MSG_CORREO_INVALIDO,
    MSG_CORREO_NO_INSTITUCIONAL,
    error_correo_nuevo,
    normalizar_correo,
)
from app.models.auth_models import Usuario

CLAVE = "ClaveSegura1"  # noqa: S105 (solo pruebas)


def _registrar(client, email, nombre="Ana Pérez", **extra):
    return client.post("/auth/register",
                       json={"nombre": nombre, "email": email, "password": CLAVE, **extra})


def _mensajes(r):
    detalle = r.json()["detail"]
    return [e["msg"] for e in detalle] if isinstance(detalle, list) else [detalle]


# --------------------------------------------------------------------------
# Regla (unidad)
# --------------------------------------------------------------------------
def test_sin_configuracion_solo_utb_edu_co():
    # Lo que se usa en producción sin la variable: SOLO el dominio institucional.
    assert config.leer_dominios(None) == ("utb.edu.co",)
    assert config.leer_dominios("") == ("utb.edu.co",)
    assert config.leer_dominios(" , ") == ("utb.edu.co",)
    assert config.leer_dominios("utb.edu.co, @Example.COM ,utb.edu.co") == (
        "utb.edu.co", "example.com")


@pytest.mark.parametrize("correo", [
    "mmillan@utb.edu.co",
    "ana.perez@utb.edu.co",
    "ana_perez-salones@utb.edu.co",
    "t00012345@utb.edu.co",
])
def test_correos_institucionales_validos(monkeypatch, correo):
    monkeypatch.setattr(config, "DOMINIOS_PERMITIDOS", ("utb.edu.co",))
    assert error_correo_nuevo(correo) is None


@pytest.mark.parametrize("correo, mensaje", [
    ("persona@gmail.com", MSG_CORREO_NO_INSTITUCIONAL),
    ("usuario@utb.edu.co.malo.com", MSG_CORREO_NO_INSTITUCIONAL),
    ("usuario@estudiantes.utb.edu.co", MSG_CORREO_NO_INSTITUCIONAL),  # subdominio: no
    ("usuario@utbedu.co", MSG_CORREO_NO_INSTITUCIONAL),
    ("usuario@utb.edu.co@otro.com", MSG_CORREO_INVALIDO),
    ("@utb.edu.co", MSG_CORREO_INVALIDO),
    ("usu ario@utb.edu.co", MSG_CORREO_INVALIDO),
    (".ana@utb.edu.co", MSG_CORREO_INVALIDO),
    ("ana.@utb.edu.co", MSG_CORREO_INVALIDO),
    ("ana..perez@utb.edu.co", MSG_CORREO_INVALIDO),
    ("ana!@utb.edu.co", MSG_CORREO_INVALIDO),
    ("añá@utb.edu.co", MSG_CORREO_INVALIDO),
    ("ana%40x@utb.edu.co", MSG_CORREO_INVALIDO),
    ("a" * 65 + "@utb.edu.co", MSG_CORREO_INVALIDO),
    ("ana@utb.edu.co\nbcc:x@utb.edu.co", MSG_CORREO_INVALIDO),
])
def test_correos_tramposos_se_rechazan(monkeypatch, correo, mensaje):
    monkeypatch.setattr(config, "DOMINIOS_PERMITIDOS", ("utb.edu.co",))
    assert error_correo_nuevo(normalizar_correo(correo)) == mensaje


def test_mayusculas_y_espacios_se_aceptan_ya_normalizados(monkeypatch):
    monkeypatch.setattr(config, "DOMINIOS_PERMITIDOS", ("utb.edu.co",))
    correo = normalizar_correo("usuario@UTB.EDU.CO ")
    assert correo == "usuario@utb.edu.co"
    assert error_correo_nuevo(correo) is None


def test_mensaje_en_espanol():
    assert MSG_CORREO_NO_INSTITUCIONAL == (
        "Usa tu correo institucional de la UTB (termina en @utb.edu.co)")


# --------------------------------------------------------------------------
# Registro
# --------------------------------------------------------------------------
def test_registro_con_gmail_rechazado_sin_configuracion_extra(client, monkeypatch):
    monkeypatch.setattr(config, "DOMINIOS_PERMITIDOS", config.leer_dominios(None))
    r = _registrar(client, "persona@gmail.com")
    assert r.status_code == 422
    assert MSG_CORREO_NO_INSTITUCIONAL in _mensajes(r)


@pytest.mark.parametrize("correo", ["usuario@utb.edu.co.malo.com", "usuario@utb.edu.co@otro.com"])
def test_registro_tramposo_rechazado(client, correo):
    assert _registrar(client, correo).status_code == 422


def test_registro_institucional_normalizado(client):
    r = _registrar(client, "  MMillan@UTB.EDU.CO ")
    assert r.status_code == 201, r.text
    assert r.json()["email"] == "mmillan@utb.edu.co"


def test_desarrollo_puede_ampliar_dominios(client, monkeypatch):
    monkeypatch.setattr(config, "DOMINIOS_PERMITIDOS", config.leer_dominios("utb.edu.co,example.com"))
    assert _registrar(client, "prueba@example.com").status_code == 201
    # La ampliación no abre otros dominios.
    assert _registrar(client, "otra@gmail.com", nombre="Otra").status_code == 422


# --------------------------------------------------------------------------
# Cuentas antiguas con correo no institucional
# --------------------------------------------------------------------------
def _cuenta_antigua(db_session, correo="antigua@gmail.com"):
    db_session.add(Usuario(nombre="Cuenta Antigua", email=correo, rol="usuario_utb",
                           password=hash_password(CLAVE), email_verificado=True))
    db_session.commit()


def test_cuenta_antigua_no_institucional_sigue_entrando_y_ve_aviso(client, db_session):
    _cuenta_antigua(db_session)
    r = client.post("/auth/login", json={"nombre": "antigua@gmail.com", "password": CLAVE})
    assert r.status_code == 200
    me = client.get("/auth/me", headers={"Authorization": f"Bearer {r.json()['access_token']}"})
    assert me.status_code == 200
    assert me.json()["correo_institucional"] is False


def test_cuenta_institucional_sin_aviso(client, auth_headers):
    assert client.get("/auth/me", headers=auth_headers).json()["correo_institucional"] is True


def test_cuenta_antigua_puede_pedir_recuperacion(client, db_session):
    from app.messaging.models import MensajeOutbox

    _cuenta_antigua(db_session)
    r = client.post("/auth/forgot-password", json={"email": "antigua@gmail.com"})
    assert r.status_code == 202
    db_session.expire_all()
    assert db_session.query(MensajeOutbox).count() == 1


def test_recuperacion_no_revela_si_existe(client, db_session):
    _cuenta_antigua(db_session)
    existe = client.post("/auth/forgot-password", json={"email": "antigua@gmail.com"})
    no_existe = client.post("/auth/forgot-password", json={"email": "nadie@gmail.com"})
    assert existe.status_code == no_existe.status_code == 202
    assert existe.json() == no_existe.json()
    # Un correo mal formado sí es 422, pero eso no depende de que exista una cuenta.
    assert client.post("/auth/forgot-password",
                       json={"email": "x@utb.edu.co@otro.com"}).status_code == 422


# --------------------------------------------------------------------------
# Cambio de correo
# --------------------------------------------------------------------------
def test_cambio_de_correo_a_no_institucional_rechazado(client, auth_headers):
    r = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                    json={"correo_nuevo": "yo@gmail.com", "password": "TestPassword1"})
    assert r.status_code == 422
    assert MSG_CORREO_NO_INSTITUCIONAL in _mensajes(r)


def test_cuenta_antigua_puede_pasarse_a_institucional(client, db_session):
    _cuenta_antigua(db_session)
    token = client.post("/auth/login", json={"nombre": "antigua@gmail.com", "password": CLAVE}
                        ).json()["access_token"]
    r = client.post("/auth/me/cambiar-correo", headers={"Authorization": f"Bearer {token}"},
                    json={"correo_nuevo": "antigua@utb.edu.co", "password": CLAVE})
    assert r.status_code == 200, r.text
    assert r.json()["email"] == "antigua@utb.edu.co"

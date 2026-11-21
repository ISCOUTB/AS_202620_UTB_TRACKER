"""
Servicio de correo y recuperación de contraseña (ADR-0014 / ADR-0015). Desde ADR-0024 no hay
verificación de correo: el registro no envía nada.

Los correos se leen como los leería una persona en desarrollo: el worker los procesa con el
ProveedorDesarrollo, que los guarda en una carpeta (en producción irían por SMTP).
"""
import json
import re
from datetime import datetime, timedelta, timezone
from email import message_from_bytes, policy
from pathlib import Path

import jwt
import pytest

from app.core import config
from app.core.security import PROPOSITO_RECUPERAR, crear_token_proposito
from app.messaging.models import MensajeOutbox
from app.messaging.worker import NotificadorSimulado, procesar_pendientes
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario
from app.services import correo
from app.services.correo import ProveedorDesarrollo

CLAVE = "ClaveSegura1"


@pytest.fixture
def buzon(tmp_path):
    return ProveedorDesarrollo(str(tmp_path / "correos"))


def _entregar(db, buzon) -> int:
    return procesar_pendientes(db, NotificadorSimulado(), proveedor_correo=buzon)


def _correos(buzon, plantilla=None):
    archivos = sorted(Path(buzon.carpeta).glob("*.eml")) if buzon.carpeta.exists() else []
    msgs = [message_from_bytes(a.read_bytes(), policy=policy.default) for a in archivos]
    return [m for m in msgs if plantilla is None or m["X-UTB-Plantilla"] == plantilla]


def _texto(msg) -> str:
    return msg.get_body(preferencelist=("plain",)).get_content()


def _token_de(msg) -> str:
    return re.search(r"token=([\w\-.]+)", _texto(msg)).group(1)


def _registrar(client, nombre="Nueva Persona", email="nueva@utb.edu.co"):
    r = client.post("/auth/register", json={"nombre": nombre, "email": email, "password": CLAVE})
    assert r.status_code == 201, r.text
    return r.json()


def _login(client, ident="nueva@utb.edu.co", clave=CLAVE):
    r = client.post("/auth/login", json={"nombre": ident, "password": clave})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}, r.json()


def _acciones(db, accion):
    return db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == accion).all()


# --------------------------------------------------------------------------
# Registro y verificación
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Recuperación de contraseña
# --------------------------------------------------------------------------
def test_recuperacion_no_revela_si_el_correo_existe(client, db_session, buzon):
    existe = client.post("/auth/forgot-password", json={"email": "USER1@utb.edu.co"})
    no_existe = client.post("/auth/forgot-password", json={"email": "nadie@utb.edu.co"})
    assert existe.status_code == no_existe.status_code == 202
    assert existe.json() == no_existe.json()
    _entregar(db_session, buzon)
    assert [m["To"] for m in _correos(buzon, "recuperacion")] == ["user1@utb.edu.co"]
    assert _acciones(db_session, "auth.recuperacion_solicitada")


def test_recuperacion_completa_y_de_un_solo_uso(client, db_session, buzon):
    client.post("/auth/forgot-password", json={"email": "user1@utb.edu.co"})
    _entregar(db_session, buzon)
    [msg] = _correos(buzon, "recuperacion")
    token = _token_de(msg)
    assert token in _texto(msg)  # también va como código para la app

    pagina = client.get("/auth/restablecer", params={"token": token})
    assert pagina.status_code == 200
    assert "nueva contraseña" in pagina.text

    corta = client.post("/auth/reset-password", json={"token": token, "new_password": "corta"})
    assert corta.status_code == 422
    igual = client.post("/auth/reset-password", json={"token": token, "new_password": "user1@utb.edu.co"})
    assert igual.status_code == 422

    ok = client.post("/auth/reset-password", json={"token": token, "new_password": "NuevaClave77"})
    assert ok.status_code == 200
    de_nuevo = client.post("/auth/reset-password", json={"token": token, "new_password": "OtraClave88"})
    assert de_nuevo.status_code == 400

    _login(client, "Usuario de prueba 1", "NuevaClave77")
    _entregar(db_session, buzon)
    assert len(_correos(buzon, "cambio_password")) == 1
    assert _acciones(db_session, "auth.recuperar_password")


def test_recuperacion_con_limite_de_frecuencia(client):
    codigos = [client.post("/auth/forgot-password", json={"email": "user2@utb.edu.co"}).status_code
               for _ in range(config.CORREO_RATE_LIMIT + 1)]
    assert codigos[-1] == 429


# --------------------------------------------------------------------------
# Sesión, límites y alertas
# --------------------------------------------------------------------------
def test_limite_de_login_se_guarda_en_la_base(client, db_session):
    for _ in range(config.LOGIN_RATE_LIMIT):
        client.post("/auth/login", json={"nombre": "Usuario de prueba 2", "password": "Mala12345"})
    r = client.post("/auth/login", json={"nombre": "Usuario de prueba 2", "password": "TestPassword2"})
    assert r.status_code == 429
    from app.models.seguridad_models import IntentoLimitado
    assert db_session.query(IntentoLimitado).count() >= config.LOGIN_RATE_LIMIT


def test_alerta_si_entra_tras_varios_fallos(client, db_session, buzon):
    for _ in range(3):
        client.post("/auth/login", json={"nombre": "user2@utb.edu.co", "password": "Mala12345"})
    _login(client, "user2@utb.edu.co", "TestPassword2")
    _entregar(db_session, buzon)
    [alerta] = _correos(buzon, "inicio_sesion_sospechoso")
    assert "3 intentos" in _texto(alerta)


def test_token_de_sesion_viejo_con_correo_sigue_valiendo(client):
    from app.core.security import create_access_token, create_refresh_token
    viejo = create_access_token({"sub": "user1@utb.edu.co"})
    r = client.get("/auth/me", headers={"Authorization": f"Bearer {viejo}"})
    assert r.status_code == 200
    assert r.json()["email"] == "user1@utb.edu.co"
    refresco = client.post("/auth/refresh", json={"refresh_token": create_refresh_token({"sub": "user1@utb.edu.co"})})
    assert refresco.status_code == 200
    # El nuevo par ya identifica por id
    payload = jwt.decode(refresco.json()["access_token"], options={"verify_signature": False})
    assert payload["sub"].isdigit()


# --------------------------------------------------------------------------
# Servicio de correo: seguridad y entrega
# --------------------------------------------------------------------------
def test_plantilla_escapa_html(buzon):
    correo.enviar("ana@utb.edu.co", "bienvenida", {"nombre": "<script>alert(1)</script>"}, buzon)
    [msg] = _correos(buzon)
    html = msg.get_body(preferencelist=("html",)).get_content()
    assert "<script>" not in html
    assert "&lt;script&gt;" in html


def test_no_permite_inyeccion_de_cabeceras(buzon):
    with pytest.raises(ValueError):
        correo.enviar("ana@utb.edu.co\nBcc: espia@x.com", "bienvenida", {"nombre": "A"}, buzon)
    with pytest.raises(ValueError):
        correo.enviar("ana@utb.edu.co", "recuperacion", {"nombre": "A", "enlace": "javascript:x", "codigo": "c", "minutos": 30}, buzon)


def test_worker_reintenta_si_el_proveedor_falla(client, db_session, buzon):
    class Caido:
        def __init__(self):
            self.intentos = 0

        def entregar(self, mensaje):
            self.intentos += 1
            raise ConnectionError("SMTP caído")

    client.post("/auth/forgot-password", json={"email": "user1@utb.edu.co"})
    caido = Caido()
    procesar_pendientes(db_session, NotificadorSimulado(), proveedor_correo=caido)
    msg = db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO).one()
    assert msg.estado == "pendiente"
    assert msg.intentos == 1
    assert "SMTP caído" in msg.ultimo_error
    # Al recuperarse el proveedor, el siguiente ciclo (ya pasado el backoff) lo entrega.
    procesar_pendientes(db_session, NotificadorSimulado(),
                        ahora=datetime.now(timezone.utc) + timedelta(minutes=5), proveedor_correo=buzon)
    db_session.refresh(msg)
    assert msg.estado == "enviado"
    assert len(_correos(buzon, "recuperacion")) == 1


def test_el_log_del_worker_no_incluye_el_token(client, db_session, buzon, caplog, monkeypatch):
    monkeypatch.setattr(config, "ENVIRONMENT", "production")
    client.post("/auth/forgot-password", json={"email": "user1@utb.edu.co"})
    with caplog.at_level("INFO"):
        _entregar(db_session, buzon)
    token = _token_de(_correos(buzon, "recuperacion")[0])
    assert token not in caplog.text


def test_payload_del_outbox_identifica_plantilla_y_categoria(client, db_session):
    client.post("/auth/forgot-password", json={"email": "user1@utb.edu.co"})
    msg = db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO).one()
    p = json.loads(msg.payload)
    assert p["plantilla"] == "recuperacion"
    assert p["categoria"] == "seguridad"


def test_produccion_arranca_solo_con_las_claves_anteriores(tmp_path):
    """Un servidor que aún no tiene en su .env las variables nuevas no se cae al desplegar."""
    import os
    import subprocess
    import sys

    env = {k: v for k, v in os.environ.items() if k not in (
        "URL_PUBLICA", "USE_REAL_MAIL")}
    env.update(ENVIRONMENT="production", SECRET_KEY="s" * 40, FORGET_PWD_SECRET_KEY="f" * 40,
               DATABASE_URL="postgresql+psycopg://u@localhost/x")
    codigo = ("from app.core import config as c; "
              "print(c.URL_PUBLICA, hasattr(c, 'VERIFICACION_OBLIGATORIA'))")
    r = subprocess.run([sys.executable, "-c", codigo], cwd=tmp_path, env={
        **env, "PYTHONPATH": str(Path(__file__).resolve().parent.parent)},
        capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    assert r.stdout.split() == ["https://129-80-171-141.nip.io", "False"]


# --------------------------------------------------------------------------
# Sin verificación de correo (ADR-0024)
# --------------------------------------------------------------------------
def test_registro_no_envia_correo_ni_trae_campo_de_verificacion(client, db_session):
    cuenta = _registrar(client)
    assert "email_verificado" not in cuenta
    assert db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO).count() == 0


def test_cuenta_nueva_solicita_salones_de_inmediato(client, db_session):
    _registrar(client)
    headers, _ = _login(client)
    r = client.post("/prestamos-salon", headers=headers, json={
        "salon_id": 1, "fecha_inicio": "2030-01-07T10:00:00", "fecha_fin": "2030-01-07T11:00:00",
        "motivo": "Estudio",
    })
    assert r.status_code != 403, r.text  # ya no se exige correo verificado


@pytest.mark.parametrize("ruta", ["/auth/verificar-correo", "/auth/reenviar-verificacion"])
def test_los_endpoints_de_verificacion_ya_no_existen(client, ruta):
    assert client.get(ruta).status_code in (404, 405)
    assert client.post(ruta).status_code in (404, 405)

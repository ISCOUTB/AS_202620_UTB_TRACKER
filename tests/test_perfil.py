"""
Fase 2 (ADR-0016): perfil personalizable, cambio de correo y contraseña, sesiones,
desactivación y preferencias en el servidor respetadas por el worker.
"""
import json
import re
from email import message_from_bytes, policy
from pathlib import Path

import pytest

from app.messaging.models import MensajeOutbox
from app.messaging.worker import NotificadorSimulado, procesar_pendientes
from app.models.auditoria_models import RegistroAuditoria
from app.services.correo import ProveedorDesarrollo, TIPO_EVENTO

CLAVE = "TestPassword1"


@pytest.fixture
def buzon(tmp_path):
    return ProveedorDesarrollo(str(tmp_path / "correos"))


def _sesion(client, ident="user1@utb.edu.co", clave=CLAVE):
    r = client.post("/auth/login", json={"nombre": ident, "password": clave})
    assert r.status_code == 200, r.text
    j = r.json()
    return {"Authorization": f"Bearer {j['access_token']}"}, j["refresh_token"]


def _plantillas(buzon):
    if not buzon.carpeta.exists():
        return []
    return [p.name.split("_")[1] for p in sorted(Path(buzon.carpeta).glob("*.eml"))]


def _acciones(db, accion):
    return db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == accion).all()


def _entregar(db, buzon):
    procesar_pendientes(db, NotificadorSimulado(), proveedor_correo=buzon)


def test_me_trae_perfil_y_preferencias_por_defecto(client, auth_headers):
    r = client.get("/auth/me", headers=auth_headers)
    assert r.status_code == 200
    j = r.json()
    assert j["email_verificado"] is True
    assert j["preferencias"]["tamano_texto"] == "normal"
    assert j["preferencias"]["notificaciones"]["correo"]["salones"] is True
    assert j["telefono"] is None


def test_patch_me_edita_y_audita_sin_guardar_valores_personales(client, auth_headers, db_session):
    r = client.patch("/auth/me", headers=auth_headers, json={
        "nombre_mostrar": "  Ana   María ", "telefono": "+57 300 123 4567",
        "dependencia": "Laboratorios", "color_avatar": "#3ddc97",
        "preferencias": {"tamano_texto": "grande", "pantalla_inicio": "salones"},
    })
    assert r.status_code == 200, r.text
    j = r.json()
    assert j["nombre_mostrar"] == "Ana María"
    assert j["color_avatar"] == "#3DDC97"
    assert j["preferencias"]["tamano_texto"] == "grande"
    [reg] = _acciones(db_session, "usuario.perfil")
    assert set(json.loads(reg.detalle)["campos"]) >= {"telefono", "preferencias"}
    assert "300" not in reg.detalle  # el teléfono no queda en la auditoría

    borrar = client.patch("/auth/me", headers=auth_headers, json={"telefono": ""})
    assert borrar.json()["telefono"] is None


@pytest.mark.parametrize("cuerpo", [
    {"color_avatar": "rojo"},
    {"telefono": "llámame"},
    {"preferencias": {"tamano_texto": "gigante"}},
    {"rol": "administrador"},  # no se puede escalar privilegios por aquí
])
def test_patch_me_valida(client, auth_headers, cuerpo):
    assert client.patch("/auth/me", headers=auth_headers, json=cuerpo).status_code == 422


def test_perfil_exige_sesion(client):
    assert client.patch("/auth/me", json={"telefono": "3001234567"}).status_code == 401
    assert client.post("/auth/me/cerrar-sesiones").status_code == 401


def test_cambio_de_correo_solo_al_abrir_el_enlace_y_avisa_al_anterior(client, db_session, buzon):
    headers, refresh = _sesion(client)
    mala = client.post("/auth/me/cambiar-correo", headers=headers,
                       json={"correo_nuevo": "nuevo@utb.edu.co", "password": "Mala12345"})
    assert mala.status_code == 403
    en_uso = client.post("/auth/me/cambiar-correo", headers=headers,
                         json={"correo_nuevo": "USER2@utb.edu.co", "password": CLAVE})
    assert en_uso.status_code == 409

    r = client.post("/auth/me/cambiar-correo", headers=headers,
                    json={"correo_nuevo": "Nuevo@UTB.edu.co", "password": CLAVE})
    assert r.status_code == 202
    # Todavía no cambió: se sigue entrando con el anterior.
    assert client.get("/auth/me", headers=headers).json()["email"] == "user1@utb.edu.co"
    _entregar(db_session, buzon)
    assert sorted(_plantillas(buzon)) == ["cambio", "cambio"]  # cambio_correo_nuevo y _aviso
    archivos = {p.name: p for p in Path(buzon.carpeta).glob("*.eml")}
    nuevo = next(p for n, p in archivos.items() if "nuevo@utb.edu.co" in n)
    aviso = next(p for n, p in archivos.items() if "user1@utb.edu.co" in n)
    texto_aviso = message_from_bytes(aviso.read_bytes(), policy=policy.default).get_body(
        preferencelist=("plain",)).get_content()
    assert "nu***@utb.edu.co" in texto_aviso
    assert "nuevo@utb.edu.co" not in texto_aviso
    texto_nuevo = message_from_bytes(nuevo.read_bytes(), policy=policy.default).get_body(
        preferencelist=("plain",)).get_content()
    token = re.search(r"token=([\w\-.]+)", texto_nuevo).group(1)

    pagina = client.get("/auth/verificar-correo", params={"token": token})
    assert pagina.status_code == 200
    assert "Correo actualizado" in pagina.text
    # La sesión abierta ANTES del cambio sigue valiendo (sub = id).
    me = client.get("/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["email"] == "nuevo@utb.edu.co"
    assert client.post("/auth/refresh", json={"refresh_token": refresh}).status_code == 200
    _sesion(client, "nuevo@utb.edu.co")
    assert _acciones(db_session, "usuario.cambio_correo")
    # El enlace es de un solo uso.
    assert client.get("/auth/verificar-correo", params={"token": token}).status_code == 400


def test_cambiar_password_cierra_las_demas_sesiones(client, db_session, buzon):
    otro_dispositivo, refresh_viejo = _sesion(client)
    este, _ = _sesion(client)

    assert client.post("/auth/me/cambiar-password", headers=este, json={
        "password_actual": "Mala12345", "password_nueva": "NuevaClave77"}).status_code == 403
    assert client.post("/auth/me/cambiar-password", headers=este, json={
        "password_actual": CLAVE, "password_nueva": "user1@utb.edu.co"}).status_code == 422

    r = client.post("/auth/me/cambiar-password", headers=este, json={
        "password_actual": CLAVE, "password_nueva": "NuevaClave77"})
    assert r.status_code == 200, r.text
    nuevo = {"Authorization": f"Bearer {r.json()['access_token']}"}

    assert client.get("/auth/me", headers=otro_dispositivo).status_code == 401
    assert client.get("/auth/me", headers=este).status_code == 401
    assert client.post("/auth/refresh", json={"refresh_token": refresh_viejo}).status_code == 401
    assert client.get("/auth/me", headers=nuevo).status_code == 200
    _sesion(client, "user1@utb.edu.co", "NuevaClave77")
    _entregar(db_session, buzon)
    assert "cambio" in _plantillas(buzon)
    assert _acciones(db_session, "usuario.cambiar_password")


def test_cerrar_sesiones_en_todos_los_dispositivos(client, db_session):
    otro, refresh_otro = _sesion(client)
    este, _ = _sesion(client)
    r = client.post("/auth/me/cerrar-sesiones", headers=este)
    assert r.status_code == 200
    assert client.get("/auth/me", headers=otro).status_code == 401
    assert client.post("/auth/refresh", json={"refresh_token": refresh_otro}).status_code == 401
    nuevo = {"Authorization": f"Bearer {r.json()['access_token']}"}
    assert client.get("/auth/me", headers=nuevo).status_code == 200
    assert _acciones(db_session, "usuario.cerrar_sesiones")


def test_desactivar_mi_cuenta(client, db_session):
    headers, _ = _sesion(client)
    assert client.post("/auth/me/desactivar", headers=headers,
                       json={"password": "Mala12345"}).status_code == 403
    assert client.post("/auth/me/desactivar", headers=headers,
                       json={"password": CLAVE}).status_code == 200
    r = client.post("/auth/login", json={"nombre": "user1@utb.edu.co", "password": CLAVE})
    assert r.status_code == 403
    assert r.json()["detail"] == "Cuenta desactivada"
    assert _acciones(db_session, "usuario.desactivar_propia")


def test_password_actual_tiene_limite_de_intentos(client):
    headers, _ = _sesion(client)
    codigos = [client.post("/auth/me/desactivar", headers=headers,
                           json={"password": "Mala12345"}).status_code for _ in range(6)]
    assert codigos[:5] == [403] * 5
    assert codigos[5] == 429


def test_worker_respeta_preferencias_salvo_seguridad(client, db_session, buzon):
    headers, _ = _sesion(client)
    client.patch("/auth/me", headers=headers, json={"preferencias": {
        "notificaciones": {"correo": {"cuenta": False, "salones": False}}}})
    user_id = client.get("/auth/me", headers=headers).json()["id"]

    from app.services import correo
    correo.encolar(db_session, "user1@utb.edu.co", "bienvenida", {"nombre": "U"}, usuario_id=user_id)
    db_session.commit()
    client.post("/auth/me/cambiar-password", headers=headers,
                json={"password_actual": CLAVE, "password_nueva": "NuevaClave77"})
    _entregar(db_session, buzon)

    assert _plantillas(buzon) == ["cambio"]  # solo el de seguridad
    omitido = db_session.query(MensajeOutbox).filter(MensajeOutbox.tipo == TIPO_EVENTO,
                                                     MensajeOutbox.payload.contains("bienvenida")).one()
    assert omitido.estado == "enviado"
    assert omitido.ultimo_error == "omitido por preferencia del usuario"


def test_worker_respeta_preferencia_de_avisos_de_salones(client, db_session):
    headers, _ = _sesion(client)
    user_id = client.get("/auth/me", headers=headers).json()["id"]
    client.patch("/auth/me", headers=headers, json={"preferencias": {
        "notificaciones": {"correo": {"salones": False}, "push": {"salones": False}}}})

    from app.messaging.publisher import publicar_evento
    publicar_evento(db_session, "prestamo_salon.aprobado", {"usuario_id": user_id, "prestamo_id": 1})
    db_session.commit()
    notificador = NotificadorSimulado()
    procesar_pendientes(db_session, notificador)
    assert notificador._envios == 0
    msg = db_session.query(MensajeOutbox).filter_by(tipo="prestamo_salon.aprobado").one()
    assert msg.ultimo_error == "omitido por preferencia del usuario"

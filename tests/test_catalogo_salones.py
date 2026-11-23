"""
Catálogo de salones UTB (ADR-0021): regla del código, permisos (solo el Administrador crea,
renombra y desactiva), crear varios por rango con vista previa, reconciliación, orden natural,
filtros por edificio y piso, y el script idempotente con su archivo de datos.
"""
import json

import pytest

from app.models.auditoria_models import RegistroAuditoria
from app.models.salon_models import PrestamoSalon, Salon
from app.service import catalogo
from tests.test_roles import _auditor, _h, _solicitud


def _crear(client, headers, **campos):
    datos = {"capacidad": 40, "ubicacion": "cualquiera", **campos}
    return client.post("/salones", json=datos, headers=headers)


# ---------------------------------------------------------------- regla del código (un lugar)

@pytest.mark.parametrize("nombre,edificio,piso", [
    ("A1-101", "A1", 1), ("a2-505", None, None), (" A3-201 ", "a3", 2), ("A5-299", "A5", 2),
])
def test_codigos_validos(nombre, edificio, piso):
    assert catalogo.errores_codigo(nombre, edificio, piso) == []


@pytest.mark.parametrize("nombre,edificio,piso,parte", [
    ("A1-1011", None, None, "forma A1-101"),
    ("A12-101", None, None, "forma A1-101"),
    ("A1101", None, None, "forma A1-101"),
    ("A1-100", None, None, "00"),
    ("A2-505", "A3", 5, "edificio debe ser A2"),
    ("A2-505", "A2", 4, "piso debe ser 5"),
])
def test_codigos_invalidos(nombre, edificio, piso, parte):
    errores = catalogo.errores_codigo(nombre, edificio, piso)
    assert errores and any(parte in e for e in errores)


def test_orden_natural():
    nombres = ["A2-201", "Auditorio", "A1-201", "A1-102", "A1-101", "A10-1"]
    assert sorted(nombres, key=catalogo.clave_orden)[:4] == ["A1-101", "A1-102", "A1-201", "A2-201"]


# ---------------------------------------------------------------- crear (solo Administrador)

def test_admin_crea_con_codigo_y_se_completan_edificio_piso_ubicacion(client, admin_headers):
    r = _crear(client, admin_headers, nombre="a2-503")
    assert r.status_code == 201, r.text
    d = r.json()
    assert (d["nombre"], d["edificio"], d["piso"], d["ubicacion"]) == (
        "A2-503", "A2", 5, "Edificio A2, piso 5")
    assert d["capacidad_estimada"] is False  # la capacidad la escribió el administrador


def test_codigo_con_edificio_o_piso_que_no_coinciden_es_422(client, admin_headers):
    r = _crear(client, admin_headers, nombre="A2-503", edificio="A1", piso=5)
    assert r.status_code == 422
    assert "edificio debe ser A2" in r.json()["detail"]
    assert _crear(client, admin_headers, nombre="A2-5031").status_code == 422


def test_espacio_especial_sin_codigo_se_acepta(client, admin_headers):
    r = _crear(client, admin_headers, nombre="Auditorio Napoleón de la Rosa",
               ubicacion="Campus Tecnológico", tipo="auditorio", capacidad=300)
    assert r.status_code == 201, r.text
    assert r.json()["ubicacion"] == "Campus Tecnológico"  # sin código, la ubicación es libre


def test_auditor_no_crea_ni_desactiva_ni_renombra_pero_si_edita_lo_demas(client, db_session,
                                                                        admin_headers):
    _auditor(db_session)
    h_aud = _h(db_session, "auditor@utb.edu.co")
    assert _crear(client, h_aud, nombre="A1-101").status_code == 403
    salon = _crear(client, admin_headers, nombre="A1-101").json()
    assert client.delete(f"/salones/{salon['id']}", headers=h_aud).status_code == 403
    r = client.put(f"/salones/{salon['id']}", json={"nombre": "A1-102"}, headers=h_aud)
    assert r.status_code == 403 and "administrador" in r.json()["detail"]
    r = client.put(f"/salones/{salon['id']}", json={"piso": 2}, headers=h_aud)
    assert r.status_code == 403
    # Lo que no es del catálogo sí lo edita el auditor (y la capacidad deja de ser estimada).
    r = client.put(f"/salones/{salon['id']}", json={"descripcion": "Con cortinas"}, headers=h_aud)
    assert r.status_code == 200, r.text


def test_estudiante_no_crea(client, auth_headers):
    assert _crear(client, auth_headers, nombre="A1-101").status_code == 403


def test_admin_renombra_con_validacion(client, admin_headers):
    salon = _crear(client, admin_headers, nombre="A1-101").json()
    _crear(client, admin_headers, nombre="A1-103")
    url = f"/salones/{salon['id']}"
    assert client.put(url, json={"nombre": "A1-201"}, headers=admin_headers).status_code == 422
    assert client.put(url, json={"nombre": "A1-103"}, headers=admin_headers).status_code == 409
    r = client.put(url, json={"nombre": "a1-104"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["nombre"] == "A1-104"


def test_desactivar_no_borra_y_conserva_historial(client, db_session, admin_headers):
    salon = _crear(client, admin_headers, nombre="A1-101").json()
    salon_db = db_session.get(Salon, salon["id"])
    from app.models.auth_models import Usuario
    est = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    _solicitud(db_session, salon_db, est, estado="finalizado")
    assert client.delete(f"/salones/{salon['id']}", headers=admin_headers).status_code == 200
    db_session.expire_all()
    assert db_session.get(Salon, salon["id"]).activo is False
    assert db_session.query(PrestamoSalon).filter_by(salon_id=salon["id"]).count() == 1


# ---------------------------------------------------------------- crear varios por rango

def test_rango_vista_previa_no_escribe_y_luego_crea_solo_los_que_faltan(client, db_session,
                                                                       admin_headers):
    _crear(client, admin_headers, nombre="A2-502")
    rango = {"edificio": 2, "piso": 5, "desde": 1, "hasta": 5}
    r = client.post("/salones/catalogo/rango/vista-previa", json=rango, headers=admin_headers)
    assert r.status_code == 200
    assert r.json()["nuevos"] == ["A2-501", "A2-503", "A2-504", "A2-505"]
    assert r.json()["existentes"] == ["A2-502"]
    assert db_session.query(Salon).count() == 1  # la vista previa no escribió nada

    r = client.post("/salones/catalogo/rango", json=rango, headers=admin_headers)
    assert r.status_code == 201
    assert r.json()["creados"] == ["A2-501", "A2-503", "A2-504", "A2-505"]
    nuevo = db_session.query(Salon).filter_by(nombre="A2-504").one()
    assert (nuevo.edificio, nuevo.piso, nuevo.capacidad, nuevo.capacidad_estimada) == (
        "A2", 5, 40, True)
    registro = db_session.query(RegistroAuditoria).filter_by(accion="salon.crear_lote").one()
    assert registro.actor_id is not None and "A2-505" in registro.detalle
    # Repetir no duplica.
    r = client.post("/salones/catalogo/rango", json=rango, headers=admin_headers)
    assert r.json()["creados"] == []


def test_rango_invalido_y_permisos(client, db_session, admin_headers, auth_headers):
    malo = {"edificio": 1, "piso": 1, "desde": 5, "hasta": 2}
    assert client.post("/salones/catalogo/rango/vista-previa", json=malo,
                       headers=admin_headers).status_code == 422
    _auditor(db_session)
    ok = {"edificio": 1, "piso": 1, "desde": 1, "hasta": 2}
    for h in (auth_headers, _h(db_session, "auditor@utb.edu.co")):
        assert client.post("/salones/catalogo/rango", json=ok, headers=h).status_code == 403


# ---------------------------------------------------------------- reconciliación

def test_fuera_del_catalogo_propone_y_no_borra(client, db_session, admin_headers):
    db_session.add_all([
        Salon(nombre="ALC-201", ubicacion="Alcatraz", capacidad=12),
        Salon(nombre="A1-101", ubicacion="Aulas 1", edificio="Aulas 1", piso=1, capacidad=40),
        Salon(nombre="A9-901", ubicacion="?", edificio="A9", piso=9, capacidad=40),
        Salon(nombre="A1-102", ubicacion="ok", edificio="A1", piso=1, capacidad=40),
    ])
    db_session.commit()
    r = client.get("/salones/catalogo/fuera", headers=admin_headers)
    assert r.status_code == 200
    por_nombre = {f["nombre"]: f for f in r.json()}
    assert set(por_nombre) == {"ALC-201", "A1-101", "A9-901"}  # A1-102 está bien
    assert "Corregir edificio a A1" in por_nombre["A1-101"]["propuesta"]
    assert "no está en el catálogo" in por_nombre["A9-901"]["problema"]
    assert db_session.query(Salon).count() == 4


# ---------------------------------------------------------------- filtros y orden

def test_filtros_por_edificio_y_piso_y_orden_natural(client, admin_headers):
    for n in ("A2-201", "A1-201", "A1-102", "A1-101"):
        _crear(client, admin_headers, nombre=n)
    todos = client.get("/salones", headers=admin_headers).json()
    assert [s["nombre"] for s in todos] == ["A1-101", "A1-102", "A1-201", "A2-201"]
    r = client.get("/salones", params={"edificio": "A1", "piso": 2}, headers=admin_headers)
    assert [s["nombre"] for s in r.json()] == ["A1-201"]


# ---------------------------------------------------------------- archivo de datos y script

def test_archivo_del_catalogo_es_valido_y_marca_su_fuente():
    datos = catalogo.cargar_archivo()
    codigos = datos["codigos"]
    assert len(codigos) == len(set(codigos)) == 59
    assert all(catalogo.errores_codigo(c, None, None) == [] for c in codigos)
    assert {"A1-406", "A1-407", "A2-505", "A5-204"} <= set(codigos)
    crudo = json.loads(catalogo.ARCHIVO_CATALOGO.read_text(encoding="utf-8"))
    assert "PROVISIONAL" in " ".join(crudo["_comentario"])


def test_aplicar_catalogo_es_idempotente_simula_y_no_toca_existentes(db_session):
    db_session.add(Salon(nombre="A1-101", ubicacion="hecho a mano", capacidad=33))
    db_session.commit()
    datos = catalogo.cargar_archivo()

    simulado = catalogo.aplicar_catalogo(db_session, datos, simular=True)
    assert len(simulado["creados"]) == 58 and simulado["omitidos"] == ["A1-101"]
    assert db_session.query(Salon).count() == 1

    real = catalogo.aplicar_catalogo(db_session, datos, simular=False)
    assert len(real["creados"]) == 58
    assert db_session.query(Salon).count() == 59
    a_mano = db_session.query(Salon).filter_by(nombre="A1-101").one()
    assert (a_mano.ubicacion, a_mano.capacidad) == ("hecho a mano", 33)
    lab = db_session.query(Salon).filter_by(nombre="A1-406").one()
    assert lab.tipo == "laboratorio_computo" and lab.capacidad_estimada is True

    otra = catalogo.aplicar_catalogo(db_session, datos, simular=False)
    assert otra["creados"] == [] and len(otra["omitidos"]) == 59

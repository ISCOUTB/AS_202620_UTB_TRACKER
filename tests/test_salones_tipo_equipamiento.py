"""
Fase 4 (ADR-0017): tipo y descripción del salón, y equipamiento CALCULADO desde los recursos.
"""
import json

import pytest
from sqlalchemy import event

from app.models.auditoria_models import RegistroAuditoria
from app.models.recurso_models import Recurso
from app.models.salon_models import Salon


def _salon(client, headers, nombre, **extra):
    r = client.post("/salones", headers=headers, json={
        "nombre": nombre, "ubicacion": "Edificio A1", "capacidad": extra.pop("capacidad", 40),
        **extra,
    })
    assert r.status_code == 201, r.text
    return r.json()


def _recursos(db, salon_id, categoria, n, estado="disponible", activo=True, prefijo=None):
    for i in range(n):
        db.add(Recurso(categoria=categoria, salon_id=salon_id, estado=estado, activo=activo,
                       serial=f"{prefijo or categoria}-{salon_id}-{estado}-{activo}-{i}"))
    db.commit()


def test_tipo_por_defecto_y_descripcion_recortada(client, admin_headers):
    s = _salon(client, admin_headers, "A1-101", descripcion="   Aula   con  ventanas  ")
    assert s["tipo"] == "aula"
    assert s["descripcion"] == "Aula con ventanas"
    assert s["equipamiento"] == [] and s["tipo_sugerido"] is None
    vacia = _salon(client, admin_headers, "A1-102", descripcion="   ")
    assert vacia["descripcion"] is None


def test_tipo_invalido_y_descripcion_larga_dan_422(client, admin_headers):
    r = client.post("/salones", headers=admin_headers, json={
        "nombre": "X", "ubicacion": "Y", "capacidad": 10, "tipo": "piscina"})
    assert r.status_code == 422
    r = client.post("/salones", headers=admin_headers, json={
        "nombre": "X", "ubicacion": "Y", "capacidad": 10, "descripcion": "a" * 501})
    assert r.status_code == 422
    assert client.get("/salones", headers=admin_headers, params={"tipo": "piscina"}).status_code == 422


def test_equipamiento_solo_con_recursos_activos_y_operativos(client, admin_headers, db_session):
    s = _salon(client, admin_headers, "LAB-1")
    _recursos(db_session, s["id"], "computador", 18)
    _recursos(db_session, s["id"], "computador", 1, estado="dañado")
    _recursos(db_session, s["id"], "computador", 1, estado="mantenimiento")
    _recursos(db_session, s["id"], "computador", 3, activo=False)  # dados de baja: no cuentan
    _recursos(db_session, s["id"], "video_beam", 1, estado="prestado")  # prestado sigue operativo

    r = client.get(f"/salones/{s['id']}", headers=admin_headers).json()
    assert r["equipamiento"] == [
        {"categoria": "computador", "total": 20, "operativos": 18},
        {"categoria": "video_beam", "total": 1, "operativos": 1},
    ]
    # Sugerencia: 8 o más computadores -> laboratorio. No cambia el tipo guardado.
    assert r["tipo_sugerido"] == "laboratorio_computo"
    assert r["tipo"] == "aula"


def test_la_sugerencia_desaparece_al_aceptarla_y_el_cambio_queda_auditado(client, admin_headers, db_session):
    s = _salon(client, admin_headers, "LAB-2")
    _recursos(db_session, s["id"], "computador", 10)
    r = client.put(f"/salones/{s['id']}", headers=admin_headers, json={"tipo": "laboratorio_computo"})
    assert r.status_code == 200
    assert r.json()["tipo"] == "laboratorio_computo" and r.json()["tipo_sugerido"] is None
    reg = (db_session.query(RegistroAuditoria)
           .filter(RegistroAuditoria.accion == "salon.actualizar").one())
    assert json.loads(reg.detalle)["tipo"] == {"de": "aula", "a": "laboratorio_computo"}


def test_filtros_por_tipo_por_equipo_y_busqueda_en_descripcion(client, admin_headers, db_session):
    a = _salon(client, admin_headers, "A1-201", descripcion="Tiene tablero inteligente")
    b = _salon(client, admin_headers, "AUD-1", tipo="auditorio", capacidad=200)
    c = _salon(client, admin_headers, "A1-202")
    _recursos(db_session, a["id"], "video_beam", 1)
    _recursos(db_session, c["id"], "video_beam", 1, estado="dañado")  # no operativo
    _recursos(db_session, b["id"], "audio", 2)

    def nombres(**params):
        r = client.get("/salones", headers=admin_headers, params=params)
        assert r.status_code == 200, r.text
        return sorted(x["nombre"] for x in r.json())

    assert nombres(tipo="auditorio") == ["AUD-1"]
    assert nombres(con_equipo="video_beam") == ["A1-201"]
    assert nombres(con_equipo="audio", tipo="auditorio") == ["AUD-1"]
    assert nombres(busqueda="tablero") == ["A1-201"]


def test_ocupacion_trae_tipo_descripcion_y_equipamiento(client, admin_headers, db_session):
    s = _salon(client, admin_headers, "SA-1", tipo="sala_audiovisual", descripcion="Con cortinas")
    _recursos(db_session, s["id"], "tv", 1)
    datos = client.get("/salones/ocupacion", headers=admin_headers).json()
    salon = next(o["salon"] for o in datos if o["salon"]["nombre"] == "SA-1")
    assert salon["tipo"] == "sala_audiovisual"
    assert salon["descripcion"] == "Con cortinas"
    assert salon["equipamiento"] == [{"categoria": "tv", "total": 1, "operativos": 1}]
    una = client.get(f"/salones/{s['id']}/ocupacion", headers=admin_headers).json()
    assert una["salon"]["equipamiento"][0]["categoria"] == "tv"


def test_crear_y_cambiar_tipo_exige_auxiliar(client, auth_headers):
    r = client.post("/salones", headers=auth_headers, json={
        "nombre": "Z", "ubicacion": "Y", "capacidad": 10, "tipo": "auditorio"})
    assert r.status_code == 403


@pytest.mark.parametrize("cantidad", [2, 12])
def test_equipamiento_no_hace_una_consulta_por_salon(client, admin_headers, db_session, cantidad):
    """Cuenta las consultas de equipamiento: debe ser UNA aunque haya muchos salones."""
    for i in range(cantidad):
        db_session.add(Salon(nombre=f"Q-{i}", ubicacion="X", capacidad=30))
    db_session.commit()
    for s in db_session.query(Salon).all():
        _recursos(db_session, s.id, "video_beam", 2)

    engine = db_session.get_bind()
    sentencias: list[str] = []

    def contar(conn, cursor, sql, *args):
        if "FROM recursos" in sql:
            sentencias.append(sql)

    event.listen(engine, "before_cursor_execute", contar)
    try:
        for ruta in ("/salones", "/salones/ocupacion"):
            sentencias.clear()
            r = client.get(ruta, headers=admin_headers)
            assert r.status_code == 200
            assert len(sentencias) == 1, (ruta, len(sentencias))
    finally:
        event.remove(engine, "before_cursor_execute", contar)

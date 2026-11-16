"""
Fase 5 (ADR-0022): HABILITACIÓN (manual, con motivo) separada de OCUPACIÓN (calculada),
salones deshabilitados que no se solicitan ni se aprueban, solicitudes afectadas señaladas y
avisadas, historial y auditoría, lote por edificio/piso, equipos (operativo/dañado/
mantenimiento, nunca "prestado"), plantillas con vista previa, exportación CSV, sin N+1 y
respuestas compatibles con las APK instaladas.
"""
import json
from datetime import date, datetime, time, timedelta, timezone

import pytest
from sqlalchemy import event

from app.messaging.models import MensajeOutbox
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario
from app.models.recurso_models import Recurso
from app.models.salon_models import HistorialSalon, Horario, PrestamoSalon, ReporteSalon, Salon
from app.services import correo
from app.services.estado_salon import ahora_campus
from tests.test_roles import _auditor, _h

MANANA = datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0) + timedelta(days=1)


def _salon(db, nombre="A1-101", edificio="A1", piso=1) -> Salon:
    s = Salon(nombre=nombre, ubicacion=f"Edificio {edificio}, piso {piso}", edificio=edificio,
              piso=piso, capacidad=40)
    db.add(s)
    db.commit()
    return s


def _estudiante(db) -> Usuario:
    return db.query(Usuario).filter_by(email="user1@utb.edu.co").one()


def _solicitud(db, salon, estado="pendiente", desde=MANANA, horas=1) -> PrestamoSalon:
    p = PrestamoSalon(salon_id=salon.id, usuario_id=_estudiante(db).id, estado=estado,
                      fecha_inicio=desde, fecha_fin=desde + timedelta(hours=horas))
    db.add(p)
    db.commit()
    return p


def _clase_ahora(db, salon):
    hoy = ahora_campus()
    db.add(Horario(salon_id=salon.id, dia_semana=hoy.isoweekday(), hora_inicio=time(0, 0),
                   hora_fin=time(23, 59, 59), profesor="Ana Pérez", materia="Cálculo"))
    db.commit()


def _deshabilitar(client, h, salon_id, **extra):
    datos = {"habilitado": False, "motivo": "mantenimiento", **extra}
    return client.patch(f"/salones/{salon_id}/habilitacion", json=datos, headers=h)


# ---------------------------------------------------------------- habilitación vs ocupación

def test_ocupacion_calculada_y_habilitacion_manual_son_distintas(client, db_session, admin_headers):
    salon = _salon(db_session)
    _clase_ahora(db_session, salon)
    d = client.get(f"/salones/{salon.id}", headers=admin_headers).json()
    assert (d["habilitado"], d["ocupado_ahora"], d["estado"]) == (True, True, "ocupado")
    # La columna guardada NO se llena con "ocupado": se calcula en cada respuesta.
    db_session.expire_all()
    assert db_session.get(Salon, salon.id).estado == "disponible"

    assert _deshabilitar(client, admin_headers, salon.id, nota="Lámpara").status_code == 200
    d = client.get(f"/salones/{salon.id}", headers=admin_headers).json()
    assert (d["habilitado"], d["ocupado_ahora"], d["estado"]) == (False, False, "mantenimiento")
    assert d["motivo_deshabilitado"] == "mantenimiento"
    assert "Lámpara" in d["aviso_deshabilitado"]

    _deshabilitar(client, admin_headers, salon.id, motivo="danio")
    assert client.get(f"/salones/{salon.id}", headers=admin_headers).json()["estado"] == "fuera_servicio"

    r = client.patch(f"/salones/{salon.id}/habilitacion", json={"habilitado": True},
                     headers=admin_headers)
    d = r.json()["salon"]
    assert (d["habilitado"], d["motivo_deshabilitado"], d["estado"]) == (True, None, "ocupado")


@pytest.mark.parametrize("extra,parte", [
    ({"motivo": None}, "motivo"),
    ({"motivo": "otro"}, "nota"),
    ({"reapertura_estimada": "2000-01-01"}, "pasado"),
    ({"motivo": "vacaciones"}, None),
])
def test_motivo_obligatorio_y_datos_validos(client, db_session, admin_headers, extra, parte):
    salon = _salon(db_session)
    r = _deshabilitar(client, admin_headers, salon.id, **extra)
    assert r.status_code == 422
    if parte:
        assert parte in r.json()["detail"]
    db_session.expire_all()
    assert db_session.get(Salon, salon.id).habilitado is True


def test_estudiante_no_cambia_habilitacion_y_auditor_si(client, db_session, auth_headers):
    salon = _salon(db_session)
    assert _deshabilitar(client, auth_headers, salon.id).status_code == 403
    _auditor(db_session)
    r = _deshabilitar(client, _h(db_session, "auditor@utb.edu.co"), salon.id,
                      reapertura_estimada=str(date.today() + timedelta(days=7)))
    assert r.status_code == 200, r.text


# ---------------------------------------------------------------- deshabilitado no se solicita

def test_salon_deshabilitado_no_se_solicita_ni_se_aprueba(client, db_session, auth_headers,
                                                         admin_headers):
    salon = _salon(db_session)
    pendiente = _solicitud(db_session, salon)
    _deshabilitar(client, admin_headers, salon.id)

    r = client.post("/prestamos-salon", json={
        "salon_id": salon.id, "fecha_inicio": (MANANA + timedelta(days=1)).isoformat(),
        "fecha_fin": (MANANA + timedelta(days=1, hours=1)).isoformat(),
    }, headers=auth_headers)
    assert r.status_code == 409 and "no se puede solicitar" in r.json()["detail"]
    r = client.post(f"/prestamos-salon/{pendiente.id}/aprobar", json={}, headers=admin_headers)
    assert r.status_code == 409
    # Sin franjas para pedir y no aparece como disponible.
    assert client.get(f"/salones/{salon.id}/disponibilidad", params={"dia_semana": 1},
                      headers=auth_headers).json() == []
    libres = client.get("/salones", params={"estado": "disponible"}, headers=auth_headers).json()
    assert salon.id not in [s["id"] for s in libres]
    # Rechazar sí se puede (es lo que el auditor hará con las afectadas).
    r = client.post(f"/prestamos-salon/{pendiente.id}/rechazar",
                    json={"respuesta": "Salón en mantenimiento"}, headers=admin_headers)
    assert r.status_code == 200, r.text


def test_solicitudes_afectadas_se_senalan_y_se_avisa_al_estudiante(client, db_session,
                                                                  admin_headers, auth_headers):
    salon = _salon(db_session)
    p1 = _solicitud(db_session, salon, "pendiente")
    p2 = _solicitud(db_session, salon, "aprobado", desde=MANANA + timedelta(hours=3))
    _solicitud(db_session, salon, "finalizado", desde=MANANA - timedelta(days=3))
    _solicitud(db_session, salon, "pendiente", desde=MANANA - timedelta(days=3))  # ya pasó

    r = _deshabilitar(client, admin_headers, salon.id, motivo="evento", nota="Grado")
    assert {a["id"] for a in r.json()["solicitudes_afectadas"]} == {p1.id, p2.id}
    # Nadie se cancela solo: lo decide el auditor.
    db_session.expire_all()
    assert db_session.get(PrestamoSalon, p1.id).estado == "pendiente"

    bandeja = client.get("/prestamos-salon/gestion", headers=admin_headers).json()
    assert "Evento" in next(x for x in bandeja if x["id"] == p1.id)["aviso_salon"]
    mias = client.get("/prestamos-salon/mias", params={"estado": "aprobado"},
                      headers=auth_headers).json()
    assert mias[0]["aviso_salon"]

    avisos = [json.loads(m.payload) for m in
              db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO)]
    avisos = [a for a in avisos if a["plantilla"] == "salon_deshabilitado"]
    assert len(avisos) == 2
    assert avisos[0]["categoria"] == "salones"  # respeta las preferencias del estudiante
    assert avisos[0]["destino"] == "user1@utb.edu.co"

    # Repetir el mismo cambio no vuelve a avisar.
    _deshabilitar(client, admin_headers, salon.id, motivo="evento", nota="Grado")
    total = sum(1 for m in db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO)
                if json.loads(m.payload)["plantilla"] == "salon_deshabilitado")
    assert total == 2


def test_historial_y_auditoria(client, db_session, admin_headers):
    salon = _salon(db_session)
    _deshabilitar(client, admin_headers, salon.id, nota="Pintura")
    client.patch(f"/salones/{salon.id}/habilitacion", json={"habilitado": True},
                 headers=admin_headers)
    h = client.get(f"/salones/{salon.id}/historial", headers=admin_headers).json()
    assert [x["accion"] for x in h] == ["habilitado", "deshabilitado"]
    assert "Pintura" in h[1]["descripcion"] and h[0]["actor_nombre"] == "Admin prueba"
    regs = db_session.query(RegistroAuditoria).filter_by(accion="salon.habilitacion").all()
    assert len(regs) == 2 and all(r.actor_id for r in regs)


def test_cliente_viejo_que_manda_estado_se_traduce_a_habilitacion(client, db_session,
                                                                  admin_headers):
    salon = _salon(db_session)
    r = client.put(f"/salones/{salon.id}", json={"estado": "mantenimiento"}, headers=admin_headers)
    assert r.status_code == 200 and r.json()["estado"] == "mantenimiento"
    db_session.expire_all()
    s = db_session.get(Salon, salon.id)
    assert (s.habilitado, s.motivo_deshabilitado, s.estado) == (False, "mantenimiento", "mantenimiento")
    assert db_session.query(HistorialSalon).filter_by(salon_id=salon.id).count() == 1
    r = client.put(f"/salones/{salon.id}", json={"estado": "disponible"}, headers=admin_headers)
    assert r.json()["habilitado"] is True
    # "ocupado" ya no se guarda a mano.
    client.put(f"/salones/{salon.id}", json={"estado": "ocupado"}, headers=admin_headers)
    db_session.expire_all()
    assert db_session.get(Salon, salon.id).estado == "disponible"


def test_crear_con_estado_viejo_nace_deshabilitado(client, admin_headers):
    r = client.post("/salones", json={"nombre": "A1-201", "ubicacion": "x", "capacidad": 30,
                                      "estado": "fuera_servicio"}, headers=admin_headers)
    assert r.status_code == 201
    assert (r.json()["habilitado"], r.json()["estado"]) == (False, "fuera_servicio")


# ---------------------------------------------------------------- lote

def test_lote_por_piso_con_vista_previa_y_todo_o_nada(client, db_session, admin_headers):
    a, b = _salon(db_session, "A1-101"), _salon(db_session, "A1-102")
    _salon(db_session, "A1-201", piso=2)
    _solicitud(db_session, a)
    lote = {"edificio": "a1", "piso": 1, "habilitado": False, "motivo": "evento", "nota": "Feria"}
    r = client.post("/salones/habilitacion/lote/vista-previa", json=lote, headers=admin_headers)
    assert r.json() == {"salones": ["A1-101", "A1-102"], "sin_cambio": [], "solicitudes_afectadas": 1}
    db_session.expire_all()
    assert db_session.get(Salon, a.id).habilitado is True  # la vista previa no escribe

    malo = {**lote, "motivo": "otro", "nota": ""}
    assert client.post("/salones/habilitacion/lote", json=malo,
                       headers=admin_headers).status_code == 422
    db_session.expire_all()
    assert db_session.get(Salon, b.id).habilitado is True

    assert client.post("/salones/habilitacion/lote", json=lote,
                       headers=admin_headers).status_code == 200
    db_session.expire_all()
    assert [s.habilitado for s in db_session.query(Salon).order_by(Salon.nombre)] == [False, False, True]


def test_resumen_por_piso_cuenta_libres_ocupados_y_deshabilitados(client, db_session,
                                                                  admin_headers):
    a = _salon(db_session, "A1-101")
    b = _salon(db_session, "A1-102")
    _salon(db_session, "A1-103")
    _clase_ahora(db_session, a)
    _deshabilitar(client, admin_headers, b.id)
    r = client.get("/salones/ocupacion/resumen", headers=admin_headers).json()
    assert r == [{"edificio": "A1", "piso": 1, "total": 3, "libres": 1, "ocupados": 1,
                  "deshabilitados": 1}]


# ---------------------------------------------------------------- equipos

def _equipo(db, salon, categoria="video_beam", serial="VB-1", estado="disponible") -> Recurso:
    r = Recurso(categoria=categoria, salon_id=salon.id, serial=serial, estado=estado)
    db.add(r)
    db.commit()
    return r


def test_estado_de_equipo_admin_y_auditor_si_estudiante_no(client, db_session, admin_headers,
                                                           auth_headers):
    salon = _salon(db_session)
    vb = _equipo(db_session, salon)
    url = f"/recursos/{vb.id}/estado"
    assert client.patch(url, json={"estado": "dañado"}, headers=auth_headers).status_code == 403
    _auditor(db_session)
    r = client.patch(url, json={"estado": "dañado", "nota": "No enciende"},
                     headers=_h(db_session, "auditor@utb.edu.co"))
    assert r.status_code == 200, r.text
    assert r.json()["recurso"]["estado"] == "dañado"
    r = client.patch(url, json={"estado": "operativo"}, headers=admin_headers)
    assert r.json()["recurso"]["estado"] == "disponible"
    assert client.patch(url, json={"estado": "prestado"}, headers=admin_headers).status_code == 422
    h = client.get(f"/salones/{salon.id}/historial", headers=admin_headers).json()
    assert "Dañado → Operativo" in h[0]["descripcion"] and "No enciende" in h[1]["descripcion"]
    assert db_session.query(RegistroAuditoria).filter_by(accion="recurso.estado").count() == 2


def test_danado_baja_operativos_no_total_y_sugiere_reporte_sin_abrirlo(client, db_session,
                                                                       admin_headers):
    salon = _salon(db_session)
    vb = _equipo(db_session, salon)
    _equipo(db_session, salon, serial="VB-2")
    r = client.patch(f"/recursos/{vb.id}/estado", json={"estado": "dañado"}, headers=admin_headers)
    assert r.json()["sugerir_reporte"] is True
    assert db_session.query(ReporteSalon).count() == 0  # nada automático
    eq = client.get(f"/salones/{salon.id}", headers=admin_headers).json()["equipamiento"]
    assert eq == [{"categoria": "video_beam", "total": 2, "operativos": 1}]
    sin = client.get("/salones", params={"con_equipo": "video_beam"}, headers=admin_headers).json()
    assert [s["id"] for s in sin] == [salon.id]  # todavía queda uno operativo


def test_vincular_reporte_de_equipo_abierto(client, db_session, admin_headers):
    salon, otro = _salon(db_session), _salon(db_session, "A1-102")
    vb = _equipo(db_session, salon)
    uid = _estudiante(db_session).id
    rep = ReporteSalon(salon_id=salon.id, usuario_id=uid, tipo="equipo", descripcion="VB no prende")
    ajeno = ReporteSalon(salon_id=otro.id, usuario_id=uid, tipo="equipo", descripcion="otro")
    limpieza = ReporteSalon(salon_id=salon.id, usuario_id=uid, tipo="limpieza", descripcion="sucio")
    db_session.add_all([rep, ajeno, limpieza])
    db_session.commit()
    url = f"/recursos/{vb.id}/estado"
    r = client.patch(url, json={"estado": "dañado"}, headers=admin_headers)
    assert [x["id"] for x in r.json()["reportes_equipo_abiertos"]] == [rep.id]
    for malo in (ajeno.id, limpieza.id):
        assert client.patch(url, json={"estado": "dañado", "reporte_salon_id": malo},
                            headers=admin_headers).status_code == 422
    r = client.patch(url, json={"estado": "dañado", "reporte_salon_id": rep.id},
                     headers=admin_headers)
    assert r.json()["sugerir_reporte"] is False
    db_session.expire_all()
    assert db_session.get(ReporteSalon, rep.id).recurso_id == vb.id


def test_agregar_y_retirar_equipo_queda_en_historial(client, db_session, admin_headers):
    salon = _salon(db_session)
    r = client.post("/recursos", json={"categoria": "tv", "salon_id": salon.id, "serial": "TV-1"},
                    headers=admin_headers)
    client.delete(f"/recursos/{r.json()['id']}", headers=admin_headers)
    acciones = [x["accion"] for x in
                client.get(f"/salones/{salon.id}/historial", headers=admin_headers).json()]
    assert acciones == ["equipo.retirado", "equipo.agregado"]
    db_session.expire_all()
    assert db_session.get(Recurso, r.json()["id"]).activo is False  # retirar no borra


# ---------------------------------------------------------------- plantillas

def test_plantilla_vista_previa_no_escribe_y_aplicar_solo_lo_que_falta(client, db_session,
                                                                       admin_headers, auth_headers):
    a, b, c = _salon(db_session, "A1-101"), _salon(db_session, "A1-102"), _salon(db_session, "A1-103")
    _equipo(db_session, a, "video_beam", "A1-101-VIDEO_BEAM-01")
    datos = {"plantilla": "aula_estandar", "salon_ids": [a.id, b.id]}
    assert client.post("/recursos/plantillas/vista-previa", json=datos,
                       headers=auth_headers).status_code == 403
    r = client.post("/recursos/plantillas/vista-previa", json=datos, headers=admin_headers)
    assert r.json() == [
        {"salon_id": a.id, "salon_nombre": "A1-101", "agregar": {"aire_ac": 1, "computador": 1}},
        {"salon_id": b.id, "salon_nombre": "A1-102",
         "agregar": {"video_beam": 1, "aire_ac": 1, "computador": 1}},
    ]
    assert db_session.query(Recurso).count() == 1

    client.post("/recursos/plantillas/aplicar", json=datos, headers=admin_headers)
    assert db_session.query(Recurso).count() == 6
    assert db_session.query(Recurso).filter_by(salon_id=c.id).count() == 0  # no elegido
    seriales = {s for (s,) in db_session.query(Recurso.serial)}
    assert "A1-101-VIDEO_BEAM-01" in seriales and "A1-102-VIDEO_BEAM-01" in seriales
    # Aplicar de nuevo no duplica.
    r = client.post("/recursos/plantillas/aplicar", json=datos, headers=admin_headers)
    assert all(p["agregar"] == {} for p in r.json())
    assert db_session.query(Recurso).count() == 6

    lab = {"plantilla": "laboratorio", "salon_ids": [c.id], "computadores": 20}
    client.post("/recursos/plantillas/aplicar", json=lab, headers=admin_headers)
    assert db_session.query(Recurso).filter_by(salon_id=c.id, categoria="computador").count() == 20
    assert db_session.query(RegistroAuditoria).filter_by(accion="recurso.plantilla").count() == 2


# ---------------------------------------------------------------- exportar y compatibilidad

def test_exportar_csv_sin_formulas(client, db_session, admin_headers, auth_headers):
    _salon(db_session)
    db_session.add(Salon(nombre="=HYPERLINK(1)", ubicacion="x", capacidad=1))
    db_session.commit()
    assert client.get("/salones/exportar.csv", headers=auth_headers).status_code == 403
    r = client.get("/salones/exportar.csv", headers=admin_headers)
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/csv")
    lineas = r.text.lstrip("﻿").splitlines()
    assert lineas[0].startswith("codigo,edificio,piso")
    assert lineas[1].startswith("A1-101,A1,1") and lineas[2].startswith("'=HYPERLINK")


def test_respuesta_compatible_con_apk_vieja(client, db_session, auth_headers):
    """Todos los campos de antes siguen y `estado` usa los mismos cuatro valores."""
    _salon(db_session)
    d = client.get("/salones", headers=auth_headers).json()[0]
    for campo in ("id", "nombre", "ubicacion", "edificio", "piso", "capacidad", "estado",
                  "activo", "tipo", "descripcion", "equipamiento", "tipo_sugerido"):
        assert campo in d
    assert d["estado"] in ("disponible", "ocupado", "mantenimiento", "fuera_servicio")


# ---------------------------------------------------------------- sin N+1

def _consultas(db_session, accion) -> int:
    contador = {"n": 0}
    motor = db_session.get_bind()

    def contar(*_):
        contador["n"] += 1

    event.listen(motor, "before_cursor_execute", contar)
    try:
        accion()
    finally:
        event.remove(motor, "before_cursor_execute", contar)
    return contador["n"]


def _poblar(db, n, desde=0):
    for i in range(desde, desde + n):
        s = _salon(db, f"A2-{200 + i + 1}", "A2", 2)
        _clase_ahora(db, s)
        _solicitud(db, s)
        _equipo(db, s, serial=f"S-{i}")


@pytest.mark.parametrize("ruta", ["/salones/ocupacion", "/salones", "/salones/ocupacion/resumen",
                                  "/recursos"])
def test_listados_sin_n_mas_1(client, db_session, admin_headers, ruta):
    _poblar(db_session, 2)
    pocas = _consultas(db_session, lambda: client.get(ruta, headers=admin_headers))
    _poblar(db_session, 8, desde=2)
    muchas = _consultas(db_session, lambda: client.get(ruta, headers=admin_headers))
    assert muchas == pocas, f"{ruta}: {pocas} consultas con 2 salones y {muchas} con 10"

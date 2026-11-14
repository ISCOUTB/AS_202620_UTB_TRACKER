"""
Pruebas de la bitácora de auditoría: qué se registra, quién la puede ver y que no se puede alterar.
"""
import json

import pytest

from app.models.auditoria_models import RegistroAuditoria

LUNES_10_30 = "2026-10-26T10:30:00"


def _login(client, nombre, password):
    r = client.post("/auth/login", json={"nombre": nombre, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _auditoria(client, admin_headers, **filtros):
    r = client.get("/auditoria", params=filtros, headers=admin_headers)
    assert r.status_code == 200, r.text
    return r.json()


def _salon_con_clase(client, admin_headers):
    salon = client.post("/salones", json={
        "nombre": "A-301", "ubicacion": "Edificio A", "capacidad": 40,
    }, headers=admin_headers).json()
    client.post("/horarios", json={
        "salon_id": salon["id"], "dia_semana": 1,
        "hora_inicio": "10:00:00", "hora_fin": "12:00:00",
        "profesor": "Ana Pérez", "materia": "Cálculo II",
    }, headers=admin_headers)
    return salon["id"]


def test_solo_el_administrador_ve_la_bitacora(client, auth_headers, admin_headers):
    assert client.get("/auditoria", headers=auth_headers).status_code == 403
    assert client.get("/auditoria", headers=admin_headers).status_code == 200
    assert client.get("/auditoria").status_code == 401


def test_el_auxiliar_no_ve_la_bitacora(client, admin_headers):
    usuarios = client.get("/auth/users", headers=admin_headers).json()
    uno = next(u for u in usuarios if u["nombre"] == "Usuario de prueba 1")
    client.patch(f"/auth/user/{uno['id']}/role", json={"rol": "auxiliar"}, headers=admin_headers)

    auxiliar = _login(client, "Usuario de prueba 1", "TestPassword1")

    assert client.get("/auditoria", headers=auxiliar).status_code == 403
    assert client.get("/auditoria/exportar", headers=auxiliar).status_code == 403


def test_login_correcto_y_fallido_quedan_registrados(client, admin_headers):
    client.post("/auth/login", json={"nombre": "Usuario de prueba 2", "password": "mala-clave"})
    client.post("/auth/login", json={"nombre": "Usuario de prueba 2", "password": "TestPassword2"})

    fallidos = _auditoria(client, admin_headers, accion="auth.login_fallido")
    correctos = _auditoria(client, admin_headers, accion="auth.login")

    assert len(fallidos) == 1
    assert json.loads(fallidos[0]["detalle"]) == {"nombre_intentado": "Usuario de prueba 2"}
    assert "mala-clave" not in json.dumps(fallidos)
    assert [r["actor_nombre"] for r in correctos if r["accion"] == "auth.login"].count(
        "Usuario de prueba 2") == 1


def test_confirmar_presencia_deja_quien_cuando_y_que(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    client.put(f"/salones/{salon_id}/presencia", params={"momento": LUNES_10_30},
               json={"profesor_presente": True, "nota": "Llegó puntual"}, headers=admin_headers)

    registros = _auditoria(client, admin_headers, accion="salon.presencia")
    assert len(registros) == 1
    r = registros[0]
    assert r["actor_nombre"] == "Admin prueba"
    assert r["entidad"] == "salon" and r["entidad_id"] == salon_id
    detalle = json.loads(r["detalle"])
    assert detalle["profesor_presente"] is True
    assert detalle["profesor"] == "Ana Pérez"
    assert detalle["nota"] == "Llegó puntual"


def test_una_accion_rechazada_no_deja_registro(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)

    # Domingo: no hay clase en curso, la acción falla con 409.
    r = client.put(f"/salones/{salon_id}/presencia", params={"momento": "2026-10-25T10:30:00"},
                   json={"profesor_presente": True}, headers=admin_headers)

    assert r.status_code == 409
    assert _auditoria(client, admin_headers, accion="salon.presencia") == []


def test_reportes_registran_creacion_y_cambio_de_estado(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    reporte = client.post(f"/salones/{salon_id}/reportes",
                          json={"tipo": "equipo", "descripcion": "No enciende"},
                          headers=auth_headers).json()
    client.patch(f"/salones/{salon_id}/reportes/{reporte['id']}",
                 json={"estado": "resuelto"}, headers=admin_headers)

    registros = _auditoria(client, admin_headers, accion="salon.reporte")

    assert sorted(r["accion"] for r in registros) == ["salon.reporte.crear", "salon.reporte.estado"]
    estado = next(r for r in registros if r["accion"] == "salon.reporte.estado")
    assert json.loads(estado["detalle"]) == {"salon_id": salon_id, "de": "abierto", "a": "resuelto"}
    assert estado["actor_nombre"] == "Admin prueba"


def test_solicitudes_de_salon_quedan_registradas_con_su_decision(client, admin_headers, auth_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    solicitud = client.post("/prestamos-salon", json={
        "salon_id": salon_id,
        "fecha_inicio": "2026-10-26T19:00:00", "fecha_fin": "2026-10-26T21:00:00",
    }, headers=auth_headers).json()
    client.patch(f"/prestamos-salon/{solicitud['id']}", json={"estado": "aprobado"},
                 headers=admin_headers)

    registros = _auditoria(client, admin_headers, entidad="prestamo_salon")

    acciones = {r["accion"]: r for r in registros}
    assert set(acciones) == {"salon.solicitud.crear", "salon.solicitud.estado"}
    assert acciones["salon.solicitud.crear"]["actor_nombre"] == "Usuario de prueba 1"
    assert json.loads(acciones["salon.solicitud.estado"]["detalle"])["a"] == "aprobado"


def test_el_cambio_de_rol_registra_quien_lo_hizo(client, admin_headers):
    usuarios = client.get("/auth/users", headers=admin_headers).json()
    objetivo = next(u for u in usuarios if u["nombre"] == "Usuario de prueba 2")

    client.patch(f"/auth/user/{objetivo['id']}/role", json={"rol": "auxiliar"}, headers=admin_headers)

    r = _auditoria(client, admin_headers, accion="usuario.rol")[0]
    assert r["actor_nombre"] == "Admin prueba"
    assert r["entidad_id"] == objetivo["id"]
    assert json.loads(r["detalle"]) == {"de": "usuario_utb", "a": "auxiliar"}


def test_crud_de_salones_y_horarios_se_audita(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    client.put(f"/salones/{salon_id}", json={"capacidad": 55}, headers=admin_headers)

    acciones = {r["accion"] for r in _auditoria(client, admin_headers)}

    assert {"salon.crear", "salon.actualizar", "horario.crear"} <= acciones
    cambio = _auditoria(client, admin_headers, accion="salon.actualizar")[0]
    assert json.loads(cambio["detalle"]) == {"capacidad": {"de": 40, "a": 55}}


def test_filtros_por_prefijo_actor_y_paginacion(client, admin_headers):
    salon_id = _salon_con_clase(client, admin_headers)
    client.put(f"/salones/{salon_id}", json={"capacidad": 55}, headers=admin_headers)

    todo_salon = _auditoria(client, admin_headers, accion="salon")
    solo_horario = _auditoria(client, admin_headers, accion="horario")
    pagina = _auditoria(client, admin_headers, limit=1)

    assert {r["accion"] for r in todo_salon} == {"salon.crear", "salon.actualizar"}
    assert {r["accion"] for r in solo_horario} == {"horario.crear"}
    assert len(pagina) == 1
    ids = [r["id"] for r in _auditoria(client, admin_headers)]
    assert ids == sorted(ids, reverse=True)  # lo más reciente primero


def test_exportar_csv_trae_encabezado_y_filas(client, admin_headers):
    _salon_con_clase(client, admin_headers)

    r = client.get("/auditoria/exportar", params={"accion": "salon"}, headers=admin_headers)

    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/csv")
    lineas = r.text.strip().splitlines()
    assert lineas[0].startswith("id,ocurrio_en,actor_id,actor_nombre,accion")
    assert any("salon.crear" in linea for linea in lineas[1:])


def test_la_bitacora_no_se_puede_modificar_ni_borrar(client, admin_headers, db_session):
    _salon_con_clase(client, admin_headers)
    registro = db_session.query(RegistroAuditoria).first()

    registro.accion = "adulterado"
    with pytest.raises(PermissionError):
        db_session.flush()
    db_session.rollback()

    registro = db_session.query(RegistroAuditoria).first()
    db_session.delete(registro)
    with pytest.raises(PermissionError):
        db_session.flush()
    db_session.rollback()

    # No hay forma de escribirla ni borrarla por la API.
    assert client.post("/auditoria", json={}, headers=admin_headers).status_code == 405
    assert client.delete("/auditoria/1", headers=admin_headers).status_code == 404

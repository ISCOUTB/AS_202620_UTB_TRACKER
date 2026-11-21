"""
Reglas de roles y del flujo de solicitudes de salón (ADR-0018).

Complementa a test_matriz_permisos.py (quién entra a cada endpoint) con las reglas de
negocio: registro como Estudiante, último administrador, invalidación de sesiones, dueño de
la solicitud, bandeja del auditor, respuesta con motivo y aviso al estudiante.
"""
import json
from datetime import datetime, timedelta, time

from sqlalchemy.orm import sessionmaker

from app.core import permisos
from app.core.hashing import hash_password
from app.messaging.models import MensajeOutbox
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario
from app.models.salon_models import Horario, PrestamoSalon, Salon
from app.services import correo
from app.services.auth import emitir_tokens


def _h(db, email: str) -> dict:
    db.expire_all()
    user = db.query(Usuario).filter_by(email=email).one()
    return {"Authorization": f"Bearer {emitir_tokens(user)['access_token']}"}


def _crear(db, nombre, email, rol, verificado=True) -> Usuario:
    u = Usuario(nombre=nombre, email=email, password=hash_password("ClaveSegura1"), rol=rol,
                email_verificado=verificado)
    db.add(u)
    db.commit()
    return u


def _auditor(db) -> Usuario:
    return _crear(db, "Auditor Uno", "auditor@utb.edu.co", "auxiliar")


def _salon(db, nombre="A1-101") -> Salon:
    s = Salon(nombre=nombre, ubicacion="Aulas 1", edificio="A1", piso=1, capacidad=30)
    db.add(s)
    db.commit()
    return s


def _solicitud(db, salon, usuario, estado="pendiente", dia=7, desde=10, hasta=11):
    p = PrestamoSalon(salon_id=salon.id, usuario_id=usuario.id, estado=estado,
                      fecha_inicio=datetime(2030, 1, dia, desde), fecha_fin=datetime(2030, 1, dia, hasta))
    db.add(p)
    db.commit()
    return p


def _acciones(db, accion):
    return db.query(RegistroAuditoria).filter_by(accion=accion).all()


# ---------------------------------------------------------------- /auth/me y registro
def test_me_devuelve_etiqueta_y_permisos_de_cada_rol(client, db_session):
    _auditor(db_session)
    for email, rol, etiqueta in (("user1@utb.edu.co", "usuario_utb", "Estudiante"),
                                 ("auditor@utb.edu.co", "auxiliar", "Auditor"),
                                 ("admin@utb.edu.co", "administrador", "Administrador")):
        me = client.get("/auth/me", headers=_h(db_session, email)).json()
        assert me["rol"] == rol  # el valor guardado NO cambia (APK instaladas)
        assert me["rol_etiqueta"] == etiqueta
        assert me["permisos"] == permisos.lista_permisos(rol)
    estudiante = client.get("/auth/me", headers=_h(db_session, "user1@utb.edu.co")).json()
    assert "salones.solicitar" in estudiante["permisos"]
    assert "solicitudes.gestionar" not in estudiante["permisos"]
    auditor = client.get("/auth/me", headers=_h(db_session, "auditor@utb.edu.co")).json()
    assert "solicitudes.gestionar" in auditor["permisos"]
    assert "usuarios.gestionar" not in auditor["permisos"]
    assert "auditoria.ver" not in auditor["permisos"]


def test_registro_publico_crea_estudiante_aunque_pida_otro_rol(client):
    r = client.post("/auth/register", json={
        "nombre": "Intruso", "email": "intruso@utb.edu.co", "password": "ClaveSegura1",
        "rol": "administrador"})
    assert r.status_code == 201
    assert r.json()["rol"] == "usuario_utb"
    assert r.json()["rol_etiqueta"] == "Estudiante"


def test_perfil_no_permite_cambiar_el_rol(client, db_session):
    h = _h(db_session, "user1@utb.edu.co")
    client.patch("/auth/me", headers=h, json={"rol": "administrador", "telefono": "3001234567"})
    assert client.get("/auth/me", headers=h).json()["rol"] == "usuario_utb"


# ---------------------------------------------------------------- gestión de usuarios
def test_solo_el_administrador_cambia_roles(client, db_session):
    _auditor(db_session)
    estudiante = db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one()
    cuerpo = {"rol": "administrador"}
    for email in ("user1@utb.edu.co", "auditor@utb.edu.co"):
        r = client.patch(f"/usuarios/{estudiante.id}/rol", headers=_h(db_session, email), json=cuerpo)
        assert r.status_code == 403
        r = client.patch(f"/auth/user/{estudiante.id}/role", headers=_h(db_session, email), json=cuerpo)
        assert r.status_code == 403
    r = client.patch(f"/usuarios/{estudiante.id}/rol", headers=_h(db_session, "admin@utb.edu.co"),
                     json={"rol": "auxiliar"})
    assert r.status_code == 200
    assert r.json()["rol_etiqueta"] == "Auditor"


def test_cambio_de_rol_invalida_las_sesiones_y_queda_auditado(client, db_session):
    vieja = _h(db_session, "user1@utb.edu.co")
    assert client.get("/auth/me", headers=vieja).status_code == 200
    objetivo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    admin = db_session.query(Usuario).filter_by(email="admin@utb.edu.co").one()
    r = client.patch(f"/usuarios/{objetivo.id}/rol", headers=_h(db_session, "admin@utb.edu.co"),
                     json={"rol": "auxiliar"})
    assert r.status_code == 200
    # El token anterior ya no vale: el nuevo rol aplica de inmediato.
    assert client.get("/auth/me", headers=vieja).status_code == 401
    nuevo = client.get("/auth/me", headers=_h(db_session, "user1@utb.edu.co")).json()
    assert nuevo["rol"] == "auxiliar"
    reg = _acciones(db_session, "usuario.rol")[-1]
    assert reg.actor_id == admin.id
    assert reg.entidad_id == objetivo.id
    assert json.loads(reg.detalle)["a"] == "auxiliar"


def test_no_se_degrada_ni_desactiva_al_ultimo_administrador_ni_a_uno_mismo(client, db_session):
    admin = db_session.query(Usuario).filter_by(email="admin@utb.edu.co").one()
    h = _h(db_session, "admin@utb.edu.co")
    # Sobre sí mismo: 409 (nuevo y legado).
    assert client.patch(f"/usuarios/{admin.id}/rol", headers=h, json={"rol": "usuario_utb"}).status_code == 409
    assert client.patch(f"/usuarios/{admin.id}/estado", headers=h, json={"activo": False}).status_code == 409
    assert client.patch(f"/auth/user/{admin.id}/role", headers=h, json={"rol": "usuario_utb"}).status_code == 409
    # Desactivarse desde su perfil siendo el último administrador: 409.
    r = client.post("/auth/me/desactivar", headers=h, json={"password": "AdminPassword1"})
    assert r.status_code == 409
    assert "último administrador" in r.json()["detail"]
    # Con un segundo administrador, el primero sí puede ser degradado por el segundo.
    otro = _crear(db_session, "Admin Dos", "admin2@utb.edu.co", "administrador")
    h2 = _h(db_session, "admin2@utb.edu.co")
    assert client.patch(f"/usuarios/{admin.id}/rol", headers=h2, json={"rol": "auxiliar"}).status_code == 200
    # Y ahora el segundo es el último: nadie puede quitarlo (el primero ya no es admin).
    db_session.expire_all()
    assert client.patch(f"/usuarios/{otro.id}/estado", headers=h2, json={"activo": False}).status_code == 409


def test_desactivar_y_reactivar_usuario(client, db_session):
    estudiante = db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one()
    h_est = _h(db_session, "user2@utb.edu.co")
    h = _h(db_session, "admin@utb.edu.co")
    r = client.patch(f"/usuarios/{estudiante.id}/estado", headers=h, json={"activo": False})
    assert r.status_code == 200
    assert r.json()["activo"] is False
    assert client.get("/auth/me", headers=h_est).status_code == 401
    assert client.post("/auth/login", json={"nombre": "user2@utb.edu.co",
                                            "password": "TestPassword2"}).status_code == 403
    assert client.patch(f"/usuarios/{estudiante.id}/estado", headers=h,
                        json={"activo": True}).status_code == 200
    acciones = [r.accion for r in db_session.query(RegistroAuditoria)
                .filter(RegistroAuditoria.entidad_id == estudiante.id,
                        RegistroAuditoria.accion.in_(["usuario.desactivar", "usuario.activar"]))
                .order_by(RegistroAuditoria.id)]
    assert acciones == ["usuario.desactivar", "usuario.activar"]


def test_lista_de_usuarios_con_filtros_y_ultima_actividad(client, db_session):
    _auditor(db_session)
    client.post("/auth/login", json={"nombre": "user1@utb.edu.co", "password": "TestPassword1"})
    h = _h(db_session, "admin@utb.edu.co")
    todos = client.get("/usuarios", headers=h)
    assert todos.status_code == 200
    assert todos.headers["X-Total-Count"] == "4"
    por_correo = {u["email"]: u for u in todos.json()}
    assert por_correo["user1@utb.edu.co"]["ultima_actividad"] is not None  # su login
    assert por_correo["user2@utb.edu.co"]["ultima_actividad"] is None
    auditores = client.get("/usuarios", headers=h, params={"rol": "auxiliar"}).json()
    assert [u["rol_etiqueta"] for u in auditores] == ["Auditor"]
    assert [u["email"] for u in client.get("/usuarios", headers=h,
                                           params={"busqueda": "prueba 2"}).json()] == ["user2@utb.edu.co"]


def test_ver_otro_usuario_solo_si_es_uno_mismo_o_auditor(client, db_session):
    _auditor(db_session)
    otro = db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one()
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    h = _h(db_session, "user1@utb.edu.co")
    assert client.get(f"/auth/user/{yo.id}", headers=h).status_code == 200
    assert client.get(f"/auth/user/{otro.id}", headers=h).status_code == 403
    assert client.get(f"/auth/user/{otro.id}", headers=_h(db_session, "auditor@utb.edu.co")).status_code == 200


# ---------------------------------------------------------------- solicitudes de salón
def test_estudiante_solo_ve_y_cancela_sus_solicitudes_y_el_auditor_ve_todas(client, db_session):
    _auditor(db_session)
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    otro = db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one()
    mia = _solicitud(db_session, salon, yo)
    ajena = _solicitud(db_session, salon, otro, dia=8)
    h = _h(db_session, "user1@utb.edu.co")
    assert [s["id"] for s in client.get("/prestamos-salon/mias", headers=h).json()] == [mia.id]
    assert [s["id"] for s in client.get("/prestamos-salon", headers=h).json()] == [mia.id]
    assert client.get(f"/prestamos-salon/{ajena.id}", headers=h).status_code == 403
    assert client.delete(f"/prestamos-salon/{ajena.id}", headers=h).status_code == 403
    assert client.delete(f"/prestamos-salon/{mia.id}", headers=h).json()["estado"] == "cancelado"
    assert client.get("/prestamos-salon/gestion", headers=h).status_code == 403
    h_aud = _h(db_session, "auditor@utb.edu.co")
    bandeja = client.get("/prestamos-salon/gestion", headers=h_aud, params={"estado": "todas"})
    assert {s["id"] for s in bandeja.json()} == {mia.id, ajena.id}
    assert {s["usuario_nombre"] for s in bandeja.json()} == {yo.nombre, otro.nombre}


def test_rechazar_exige_motivo_y_avisa_al_estudiante(client, db_session):
    auditor = _auditor(db_session)
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    p = _solicitud(db_session, salon, yo)
    h = _h(db_session, "auditor@utb.edu.co")
    assert client.post(f"/prestamos-salon/{p.id}/rechazar", headers=h, json={"respuesta": " "}).status_code == 422
    r = client.post(f"/prestamos-salon/{p.id}/rechazar", headers=h,
                    json={"respuesta": "El salón está en mantenimiento ese día"})
    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["estado"] == "rechazado"
    assert cuerpo["respuesta"] == "El salón está en mantenimiento ese día"
    assert cuerpo["atendido_por_nombre"] == auditor.nombre
    assert cuerpo["atendido_en"] is not None
    # El estudiante lo ve en Mis solicitudes…
    mias = client.get("/prestamos-salon/mias", headers=_h(db_session, "user1@utb.edu.co")).json()
    assert mias[0]["respuesta"] == "El salón está en mantenimiento ese día"
    # …y le llega el correo por el outbox (categoría "salones": respeta sus preferencias).
    msg = db_session.query(MensajeOutbox).filter_by(tipo=correo.TIPO_EVENTO).all()
    payloads = [json.loads(m.payload) for m in msg]
    aviso = [x for x in payloads if x["plantilla"] == "solicitud_salon_respuesta"]
    assert len(aviso) == 1
    assert aviso[0]["destino"] == "user1@utb.edu.co"
    assert aviso[0]["categoria"] == "salones"
    assert aviso[0]["datos"]["estado"] == "rechazado"
    reg = _acciones(db_session, "salon.solicitud.estado")[-1]
    assert reg.actor_id == auditor.id
    assert json.loads(reg.detalle)["respuesta"] == "El salón está en mantenimiento ese día"


def test_la_bandeja_muestra_el_conflicto_y_no_deja_aprobarlo(client, db_session):
    _auditor(db_session)
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    otro = db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one()
    aprobada = _solicitud(db_session, salon, otro, estado="aprobado")
    choca = _solicitud(db_session, salon, yo)                     # misma franja
    libre = _solicitud(db_session, salon, yo, dia=9)
    # 2030-01-10 es jueves (isoweekday 4): una clase fija a esa hora.
    db_session.add(Horario(salon_id=salon.id, dia_semana=4, hora_inicio=time(9), hora_fin=time(12),
                           materia="Cálculo"))
    db_session.commit()
    con_clase = _solicitud(db_session, salon, yo, dia=10)
    h = _h(db_session, "auditor@utb.edu.co")
    bandeja = {s["id"]: s for s in client.get("/prestamos-salon/gestion", headers=h).json()}
    assert set(bandeja) == {choca.id, libre.id, con_clase.id}  # por defecto, solo pendientes
    assert f"#{aprobada.id}" in bandeja[choca.id]["conflicto"]
    assert "Cálculo" in bandeja[con_clase.id]["conflicto"]
    assert bandeja[libre.id]["conflicto"] is None
    assert client.post(f"/prestamos-salon/{choca.id}/aprobar", headers=h).status_code == 409
    ok = client.post(f"/prestamos-salon/{libre.id}/aprobar", headers=h, json={"respuesta": "Listo"})
    assert ok.status_code == 200
    assert ok.json()["estado"] == "aprobado"


def test_la_bandeja_no_hace_una_consulta_por_solicitud(client, db_session):
    from sqlalchemy import event

    from app.core.database import get_db
    from app.main import app

    _auditor(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    h = _h(db_session, "auditor@utb.edu.co")
    motor = next(app.dependency_overrides[get_db]()).get_bind()

    def consultas() -> int:
        cuenta = []
        oyente = lambda *a, **k: cuenta.append(1)  # noqa: E731
        event.listen(motor, "before_cursor_execute", oyente)
        try:
            assert client.get("/prestamos-salon/gestion", headers=h).status_code == 200
        finally:
            event.remove(motor, "before_cursor_execute", oyente)
        return len(cuenta)

    for i in range(2):
        _solicitud(db_session, _salon(db_session, f"S-{i}"), yo, dia=11 + i)
    pocas = consultas()
    for i in range(2, 12):
        _solicitud(db_session, _salon(db_session, f"S-{i}"), yo, dia=11 + i % 15)
    assert consultas() == pocas


def test_el_estudiante_no_aprueba_ni_ve_estadisticas_ni_bitacora(client, db_session):
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    p = _solicitud(db_session, salon, yo)
    h = _h(db_session, "user1@utb.edu.co")
    assert client.post(f"/prestamos-salon/{p.id}/aprobar", headers=h).status_code == 403
    assert client.patch(f"/prestamos-salon/{p.id}", headers=h, json={"estado": "aprobado"}).status_code == 403
    for ruta in ("/stats/admin", "/auditoria", "/usuarios", "/salones/ocupacion", "/stats/resumen"):
        assert client.get(ruta, headers=h).status_code == 403, ruta


def test_estadisticas_del_administrador_con_datos_reales(client, db_session):
    _auditor(db_session)
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    _solicitud(db_session, salon, yo)
    _solicitud(db_session, salon, yo, estado="aprobado", dia=8)
    assert client.get("/stats/admin", headers=_h(db_session, "auditor@utb.edu.co")).status_code == 403
    r = client.get("/stats/admin", headers=_h(db_session, "admin@utb.edu.co"))
    assert r.status_code == 200
    datos = r.json()
    roles = {x["rol"]: x["total"] for x in datos["usuarios_activos_por_rol"]}
    assert roles == {"usuario_utb": 2, "auxiliar": 1, "administrador": 1}
    assert datos["solicitudes_por_estado"] == {"pendiente": 1, "aprobado": 1}
    assert datos["salones_mas_solicitados"] == [{"salon": "A1-101", "total": 2}]


def test_patch_legado_sigue_funcionando_sin_respuesta(client, db_session):
    """La APK instalada aprueba con PATCH {estado} sin `respuesta`: debe seguir valiendo."""
    _auditor(db_session)
    salon = _salon(db_session)
    yo = db_session.query(Usuario).filter_by(email="user1@utb.edu.co").one()
    p = _solicitud(db_session, salon, yo)
    r = client.patch(f"/prestamos-salon/{p.id}", headers=_h(db_session, "auditor@utb.edu.co"),
                     json={"estado": "rechazado"})
    assert r.status_code == 200
    assert r.json()["estado"] == "rechazado"
    assert r.json()["respuesta"] is None


def test_fecha_franja_del_correo_en_hora_de_colombia():
    from app.services.prestamos_salon import _franja
    p = PrestamoSalon(fecha_inicio=datetime(2030, 1, 7, 15), fecha_fin=datetime(2030, 1, 7, 16)
                      + timedelta(minutes=30))
    assert _franja(p) == "lun 07/01 10:00–11:30"


# ---------------------------------------------------------------- administrador real
def test_crear_admin_promueve_por_consola_sin_clave_en_argumentos(client, db_session, monkeypatch):
    """scripts/crear_admin.py: promueve una cuenta existente y cierra sus sesiones."""
    import sys

    from scripts import crear_admin

    vieja = _h(db_session, "user2@utb.edu.co")
    fabrica = sessionmaker(bind=db_session.get_bind())  # la misma base de la prueba
    monkeypatch.setattr(crear_admin, "SessionLocal", fabrica)
    monkeypatch.setattr(sys, "argv", ["crear_admin.py", "User2@UTB.edu.co"])
    assert crear_admin.main() == 0
    db_session.expire_all()
    assert db_session.query(Usuario).filter_by(email="user2@utb.edu.co").one().rol == "administrador"
    assert client.get("/auth/me", headers=vieja).status_code == 401
    reg = _acciones(db_session, "usuario.rol")[-1]
    assert json.loads(reg.detalle)["origen"] == "consola"


def test_crear_admin_crea_la_cuenta_pidiendo_la_clave(client, db_session, monkeypatch):
    import sys

    from scripts import crear_admin

    fabrica = sessionmaker(bind=db_session.get_bind())  # la misma base de la prueba
    claves = iter(["corta", "ClaveReal123", "ClaveReal123"])
    monkeypatch.setattr(crear_admin, "SessionLocal", fabrica)
    monkeypatch.setattr(crear_admin.getpass, "getpass", lambda *_: next(claves))
    monkeypatch.setattr("builtins.input", lambda *_: "Equipo UTB")
    monkeypatch.setattr(sys, "argv", ["crear_admin.py", "equipo@utb.edu.co", "--crear"])
    assert crear_admin.main() == 0
    r = client.post("/auth/login", json={"nombre": "equipo@utb.edu.co", "password": "ClaveReal123"})
    assert r.status_code == 200
    assert r.json()["user"]["rol"] == "administrador"

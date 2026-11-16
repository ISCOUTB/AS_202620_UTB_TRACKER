"""
Rol automático por correo institucional VERIFICADO (ADR-0019, Fase 2).

El rol sale de la lista `asignaciones_rol` (correo exacto -> rol) que mantiene el
administrador, nunca del formato del correo ni de lo que envíe el cliente.
"""
import json

from app.core.hashing import hash_password
from app.core.security import PROPOSITO_VERIFICAR, crear_token_proposito
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import AsignacionRol, Usuario
from app.services import asignaciones

CLAVE = "ClaveSegura1"  # noqa: S105 (solo pruebas)


def _registrar(client, email, nombre="Nueva Persona", **extra):
    r = client.post("/auth/register",
                    json={"nombre": nombre, "email": email, "password": CLAVE, **extra})
    assert r.status_code == 201, r.text
    return r.json()


def _verificar(client, usuario_id):
    r = client.get("/auth/verificar-correo",
                   params={"token": crear_token_proposito(usuario_id, PROPOSITO_VERIFICAR)})
    assert r.status_code == 200, r.text


def _login(client, ident, clave=CLAVE):
    r = client.post("/auth/login", json={"nombre": ident, "password": clave})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _me(client, headers):
    r = client.get("/auth/me", headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def _asignar(client, admin_headers, correo, rol="auxiliar", cargo="Auxiliar de planta"):
    return client.post("/usuarios/asignaciones", headers=admin_headers,
                       json={"correo": correo, "rol": rol, "cargo": cargo})


def _acciones(db, accion):
    db.expire_all()
    return db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == accion).all()


# --------------------------------------------------------------------------
# Resolución
# --------------------------------------------------------------------------
def test_registro_sin_asignacion_es_estudiante(client):
    user = _registrar(client, "ana@utb.edu.co")
    assert user["rol"] == "usuario_utb"
    _verificar(client, user["id"])
    perfil = _me(client, _login(client, "ana@utb.edu.co"))
    assert perfil["rol"] == "usuario_utb"
    assert perfil["rol_origen"] == "base"
    assert "administrador" in perfil["rol_origen_texto"]


def test_rol_en_el_cuerpo_del_registro_se_ignora(client):
    user = _registrar(client, "hacker@utb.edu.co", rol="administrador")
    assert user["rol"] == "usuario_utb"


def test_cuenta_sin_verificar_es_base_aunque_tenga_asignacion(client, admin_headers):
    assert _asignar(client, admin_headers, "pedro@utb.edu.co").status_code == 201
    user = _registrar(client, "pedro@utb.edu.co")
    assert user["rol"] == "usuario_utb"
    # Entra sin verificar: sigue siendo base.
    assert _me(client, _login(client, "pedro@utb.edu.co"))["rol"] == "usuario_utb"


def test_rol_asignado_tras_verificar(client, admin_headers, db_session):
    _asignar(client, admin_headers, "pedro@utb.edu.co", cargo="Auxiliar de planta")
    user = _registrar(client, "pedro@utb.edu.co")
    viejo = _login(client, "pedro@utb.edu.co")
    _verificar(client, user["id"])
    # La sesión abierta antes de verificar se cerró: el rol nuevo aplica ya.
    assert client.get("/auth/me", headers=viejo).status_code == 401
    perfil = _me(client, _login(client, "pedro@utb.edu.co"))
    assert perfil["rol"] == "auxiliar"
    assert perfil["rol_etiqueta"] == "Auditor"
    assert perfil["rol_origen"] == "correo"
    assert perfil["rol_origen_texto"] == "Asignado por tu correo institucional"
    assert perfil["cargo"] == "Auxiliar de planta"
    assert "solicitudes.gestionar" in perfil["permisos"]
    assert _acciones(db_session, "usuario.rol_automatico")


def test_cuenta_nacida_verificada_sin_correo_real_no_sube(client, admin_headers, db_session,
                                                          monkeypatch):
    """Sin correo real las cuentas nacen 'verificadas' sin haberlo comprobado: no suben de rol
    (si no, cualquiera se registraría con el correo de un administrador)."""
    from app.core import config

    monkeypatch.setattr(config, "VERIFICACION_OBLIGATORIA", False)
    _asignar(client, admin_headers, "jefe@utb.edu.co", rol="administrador")
    user = _registrar(client, "jefe@utb.edu.co")
    assert user["email_verificado"] is True
    assert _me(client, _login(client, "jefe@utb.edu.co"))["rol"] == "usuario_utb"


def test_no_se_deduce_del_formato_del_correo(client):
    # "inicial+apellido" parece personal, pero sin fila en la lista es estudiante.
    user = _registrar(client, "mmillan@utb.edu.co")
    _verificar(client, user["id"])
    assert _me(client, _login(client, "mmillan@utb.edu.co"))["rol"] == "usuario_utb"


# --------------------------------------------------------------------------
# Rol manual y cambios de la tabla
# --------------------------------------------------------------------------
def test_rol_manual_no_se_pisa(client, admin_headers, db_session):
    user = _registrar(client, "laura@utb.edu.co")
    _verificar(client, user["id"])
    r = client.patch(f"/usuarios/{user['id']}/rol", headers=admin_headers, json={"rol": "auxiliar"})
    assert r.status_code == 200 and r.json()["rol_manual"] is True
    # Una asignación posterior con otro rol NO cambia el rol manual.
    assert _asignar(client, admin_headers, "laura@utb.edu.co", rol="administrador").status_code == 201
    perfil = _me(client, _login(client, "laura@utb.edu.co"))
    assert perfil["rol"] == "auxiliar"
    assert perfil["rol_origen"] == "manual"
    assert perfil["rol_origen_texto"] == "Asignado por un administrador"
    # Volver a automático: manda la lista.
    r = client.post(f"/usuarios/{user['id']}/rol/automatico", headers=admin_headers)
    assert r.status_code == 200, r.text
    assert r.json()["rol"] == "administrador" and r.json()["rol_manual"] is False


def test_cambio_de_tabla_recalcula_audita_e_invalida_sesiones(client, admin_headers, db_session):
    user = _registrar(client, "sofia@utb.edu.co")
    _verificar(client, user["id"])
    sesion = _login(client, "sofia@utb.edu.co")
    r = _asignar(client, admin_headers, "sofia@utb.edu.co")
    assert r.status_code == 201
    asignacion_id = r.json()["id"]
    assert client.get("/auth/me", headers=sesion).status_code == 401  # sesión cerrada
    sesion = _login(client, "sofia@utb.edu.co")
    assert _me(client, sesion)["rol"] == "auxiliar"

    r = client.patch(f"/usuarios/asignaciones/{asignacion_id}", headers=admin_headers,
                     json={"cargo": "Coordinación de salones"})
    assert r.status_code == 200 and r.json()["cargo"] == "Coordinación de salones"

    assert client.delete(f"/usuarios/asignaciones/{asignacion_id}",
                         headers=admin_headers).status_code == 204
    assert client.get("/auth/me", headers=sesion).status_code == 401
    assert _me(client, _login(client, "sofia@utb.edu.co"))["rol"] == "usuario_utb"

    for accion in ("asignacion_rol.crear", "asignacion_rol.editar", "asignacion_rol.eliminar"):
        registros = _acciones(db_session, accion)
        assert registros, accion
        # Quién lo hizo, y el correo oculto (no se copia completo a la bitácora).
        assert registros[0].actor_id is not None
        assert "sofia@utb.edu.co" not in str(registros[0].detalle)


def test_si_cambia_el_correo_se_recalcula_con_el_nuevo(client, admin_headers, db_session):
    from app.core.security import PROPOSITO_CAMBIAR_CORREO

    _asignar(client, admin_headers, "maria.vieja@utb.edu.co")
    user = _registrar(client, "maria.vieja@utb.edu.co")
    _verificar(client, user["id"])
    assert _me(client, _login(client, "maria.vieja@utb.edu.co"))["rol"] == "auxiliar"
    token = crear_token_proposito(user["id"], PROPOSITO_CAMBIAR_CORREO,
                                  correo="maria.nueva@utb.edu.co", anterior="maria.vieja@utb.edu.co")
    assert client.get("/auth/verificar-correo", params={"token": token}).status_code == 200
    # El correo nuevo no tiene asignación: vuelve al rol base.
    assert _me(client, _login(client, "maria.nueva@utb.edu.co"))["rol"] == "usuario_utb"


def test_migracion_no_degrada_a_quien_ya_tenia_rol_alto(client, db_session):
    """Un rol alto existente (sin fila en la lista) sigue igual al entrar."""
    db_session.add(Usuario(nombre="Auditor Antiguo", email="antiguo@utb.edu.co", rol="auxiliar",
                           password=hash_password(CLAVE), email_verificado=True))
    db_session.commit()
    perfil = _me(client, _login(client, "antiguo@utb.edu.co"))
    assert perfil["rol"] == "auxiliar" and perfil["rol_origen"] == "manual"


def test_no_se_degrada_al_ultimo_administrador(client, db_session):
    """El único administrador obtuvo su rol por la lista: quitar o cambiar su fila da 409."""
    admin = db_session.query(Usuario).filter(Usuario.rol == "administrador").one()
    admin.rol_manual = False
    admin.email_verificado_en = admin.fecha_registro
    db_session.add(AsignacionRol(correo=admin.email, rol="administrador"))
    db_session.commit()
    headers = _login(client, "admin@utb.edu.co", "AdminPassword1")
    asignacion_id = client.get("/usuarios/asignaciones", headers=headers).json()[0]["id"]

    r = client.delete(f"/usuarios/asignaciones/{asignacion_id}", headers=headers)
    assert r.status_code == 409
    assert "último administrador" in r.json()["detail"]
    r = client.patch(f"/usuarios/asignaciones/{asignacion_id}", headers=headers,
                     json={"rol": "auxiliar"})
    assert r.status_code == 409
    r = client.post("/usuarios/asignaciones/importar", headers=headers,
                    json={"texto": f"{admin.email},Estudiante"})
    assert r.status_code == 409
    db_session.expire_all()
    assert db_session.get(AsignacionRol, asignacion_id).rol == "administrador"
    assert _me(client, headers)["rol"] == "administrador"


def test_asignacion_solo_con_correo_institucional_y_rol_valido(client, admin_headers):
    assert _asignar(client, admin_headers, "x@gmail.com").status_code == 422
    assert _asignar(client, admin_headers, "*@utb.edu.co").status_code == 422  # sin comodines
    assert _asignar(client, admin_headers, "ok@utb.edu.co", rol="superadmin").status_code == 422
    assert _asignar(client, admin_headers, "ok@utb.edu.co", rol="Auditor").status_code == 201
    assert _asignar(client, admin_headers, "OK@utb.edu.co").status_code == 409  # ya existe


def test_busqueda_de_asignaciones(client, admin_headers):
    _asignar(client, admin_headers, "uno@utb.edu.co", cargo="Laboratorios")
    _asignar(client, admin_headers, "dos@utb.edu.co", cargo="Planta")
    r = client.get("/usuarios/asignaciones", headers=admin_headers, params={"busqueda": "labor"})
    assert [a["correo"] for a in r.json()] == ["uno@utb.edu.co"]
    assert r.headers["X-Total-Count"] == "1"


def test_solo_el_administrador_gestiona_la_lista(client, auth_headers):
    assert client.get("/usuarios/asignaciones", headers=auth_headers).status_code == 403
    assert _asignar(client, auth_headers, "yo@utb.edu.co", rol="administrador").status_code == 403


# --------------------------------------------------------------------------
# Importación
# --------------------------------------------------------------------------
def test_importacion_con_errores_no_aplica_nada(client, admin_headers, db_session):
    texto = "\n".join([
        "correo;rol;cargo",
        "ana@utb.edu.co;Auditor;Auxiliar de planta",
        "malo@gmail.com;Auditor",
        "luis@utb.edu.co;jefe",
        "ana@utb.edu.co;Administrador",
        "solo-un-campo@utb.edu.co",
    ])
    r = client.post("/usuarios/asignaciones/importar", headers=admin_headers, json={"texto": texto})
    assert r.status_code == 200, r.text
    datos = r.json()
    assert datos["aplicado"] is False
    assert [e["linea"] for e in datos["errores"]] == [3, 4, 5, 6]
    assert "institucional" in datos["errores"][0]["error"]
    assert "Rol no válido" in datos["errores"][1]["error"]
    assert "repetido" in datos["errores"][2]["error"]
    db_session.expire_all()
    assert db_session.query(AsignacionRol).count() == 0


def test_importacion_valida_crea_actualiza_y_audita(client, admin_headers, db_session):
    _asignar(client, admin_headers, "luis@utb.edu.co", rol="auxiliar", cargo="Planta")
    texto = "ana@utb.edu.co,Auditor,Auxiliar de planta\nluis@utb.edu.co,administrador\n\n"
    simulado = client.post("/usuarios/asignaciones/importar", headers=admin_headers,
                           json={"texto": texto, "simular": True}).json()
    assert simulado["aplicado"] is False and simulado["creadas"] == 1
    assert simulado["actualizadas"] == 1
    db_session.expire_all()
    assert db_session.query(AsignacionRol).count() == 1  # la simulación no guardó

    r = client.post("/usuarios/asignaciones/importar", headers=admin_headers, json={"texto": texto})
    assert r.json()["aplicado"] is True
    db_session.expire_all()
    assert asignaciones.buscar(db_session, "luis@utb.edu.co").rol == "administrador"
    assert asignaciones.buscar(db_session, "luis@utb.edu.co").cargo is None
    registro = _acciones(db_session, "asignacion_rol.importar")[0]
    assert json.loads(registro.detalle) == {"creadas": 1, "actualizadas": 1, "sin_cambios": 0}


def test_analizar_lista_unidad():
    filas, errores = asignaciones.analizar_lista(
        '# comentario\n"ana@utb.edu.co","Auditor","Planta, edificio A"\n')
    assert errores == []
    assert filas[0]["cargo"] == "Planta, edificio A"
    assert asignaciones.analizar_lista("")[1][0]["error"] == "La lista está vacía"


# --------------------------------------------------------------------------
# Carga inicial por consola (archivo local ignorado por git)
# --------------------------------------------------------------------------
def test_script_carga_la_lista_desde_un_archivo_local(client, db_session, monkeypatch, tmp_path):
    import sys

    from sqlalchemy.orm import sessionmaker

    from scripts import cargar_asignaciones

    archivo = tmp_path / "asignaciones.csv"
    monkeypatch.setattr(cargar_asignaciones, "SessionLocal",
                        sessionmaker(bind=db_session.get_bind()))
    archivo.write_text("correo;rol;cargo\nmalo@gmail.com;Auditor\n", encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["cargar_asignaciones.py", str(archivo), "--aplicar"])
    assert cargar_asignaciones.main() == 1  # con errores no guarda nada
    db_session.expire_all()
    assert db_session.query(AsignacionRol).count() == 0

    archivo.write_text("correo;rol;cargo\nana@utb.edu.co;Auditor;Planta\n", encoding="utf-8")
    assert cargar_asignaciones.main() == 0
    db_session.expire_all()
    assert asignaciones.buscar(db_session, "ana@utb.edu.co").rol == "auxiliar"
    registro = _acciones(db_session, "asignacion_rol.importar")[-1]
    assert json.loads(registro.detalle)["origen"] == "consola"
    assert "ana@" not in registro.detalle

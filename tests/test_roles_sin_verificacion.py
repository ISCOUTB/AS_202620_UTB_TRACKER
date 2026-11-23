"""
Roles sin verificación de correo (ADR-0024, reemplaza la regla automática de ADR-0019).

Registrarse NUNCA da un rol con permisos: toda cuenta nueva es Estudiante y solo un administrador
sube el rol a una cuenta que ya existe (pantalla Usuarios o carga masiva).
"""
import json

import pytest

from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import Usuario
from app.services import asignaciones

CLAVE = "ClaveSegura1"  # noqa: S105 (solo pruebas)


def _registrar(client, email, nombre="Nueva Persona", **extra):
    r = client.post("/auth/register",
                    json={"nombre": nombre, "email": email, "password": CLAVE, **extra})
    assert r.status_code == 201, r.text
    return r.json()


def _login(client, ident, clave=CLAVE):
    r = client.post("/auth/login", json={"nombre": ident, "password": clave})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _me(client, headers):
    r = client.get("/auth/me", headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def _importar(client, headers, texto, simular=False):
    return client.post("/usuarios/asignaciones/importar", headers=headers,
                       json={"texto": texto, "simular": simular})


def _acciones(db, accion):
    db.expire_all()
    return db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == accion).all()


def _usuario(db, correo):
    db.expire_all()
    return db.query(Usuario).filter(Usuario.email == correo).one()


# --------------------------------------------------------------------------
# Dominio permitido en el registro
# --------------------------------------------------------------------------
@pytest.mark.parametrize("correo", [
    "ana@utb.edu.co", "  Ana@UTB.EDU.CO ", "ana.perez-tareas@utb.edu.co",
])
def test_registro_acepta_el_dominio_institucional(client, correo):
    assert _registrar(client, correo)["email"] == correo.strip().lower()


@pytest.mark.parametrize("correo", [
    "ana@gmail.com",
    "ana@utb.edu.co.otro.com",      # el dominio real es otro.com
    "ana@evil-utb.edu.co",          # parecido, pero distinto
    "ana@x.utb.edu.co",             # subdominio no previsto
    "ana@utb.edu.com",
    "ana@utb.edu.co@evil.com",      # dos arrobas
    "ana@UTB.edu.co.evil.com",      # mayúsculas raras + dominio extra
])
def test_registro_rechaza_otros_dominios(client, correo):
    r = client.post("/auth/register", json={"nombre": "Ana", "email": correo, "password": CLAVE})
    assert r.status_code == 422, r.text


def test_mensaje_de_dominio_es_claro(client):
    r = client.post("/auth/register",
                    json={"nombre": "Ana", "email": "ana@gmail.com", "password": CLAVE})
    assert "correo institucional" in json.dumps(r.json(), ensure_ascii=False)


def test_cambiar_correo_sigue_la_misma_regla_y_es_inmediato(client, auth_headers):
    malo = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                       json={"correo_nuevo": "yo@gmail.com", "password": "TestPassword1"})
    assert malo.status_code == 422
    clave_mala = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                             json={"correo_nuevo": "nuevo@utb.edu.co", "password": "x"})
    assert clave_mala.status_code == 403
    ok = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                     json={"correo_nuevo": "Nuevo@UTB.edu.co", "password": "TestPassword1"})
    assert ok.status_code == 200, ok.text
    assert ok.json()["email"] == "nuevo@utb.edu.co"
    assert _me(client, auth_headers)["email"] == "nuevo@utb.edu.co"


# --------------------------------------------------------------------------
# Anti-suplantación: ningún correo da un rol
# --------------------------------------------------------------------------
def test_registro_siempre_es_estudiante(client):
    user = _registrar(client, "ana@utb.edu.co")
    assert user["rol"] == "usuario_utb"
    perfil = _me(client, _login(client, "ana@utb.edu.co"))
    assert perfil["rol"] == "usuario_utb"
    assert perfil["rol_origen"] == "base"


def test_rol_en_el_cuerpo_del_registro_se_ignora(client):
    assert _registrar(client, "hacker@utb.edu.co", rol="administrador")["rol"] == "usuario_utb"


def test_registrarse_con_el_correo_cargado_para_otra_persona_no_hereda_el_rol(client, admin_headers):
    """Una carga masiva para un correo SIN cuenta no deja nada esperando."""
    r = _importar(client, admin_headers, "jefe@utb.edu.co,Administrador,Jefe")
    assert r.json()["sin_cuenta"] == 1 and r.json()["actualizadas"] == 0
    assert _registrar(client, "jefe@utb.edu.co", nombre="Impostor")["rol"] == "usuario_utb"
    permisos = _me(client, _login(client, "jefe@utb.edu.co"))["permisos"]
    assert "usuarios.gestionar" not in permisos


def test_cambiar_el_correo_no_cambia_el_rol(client, auth_headers, admin_headers):
    _importar(client, admin_headers, "nuevo.rol@utb.edu.co,Administrador")  # sin cuenta
    r = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                    json={"correo_nuevo": "nuevo.rol@utb.edu.co", "password": "TestPassword1"})
    assert r.status_code == 200
    assert r.json()["rol"] == "usuario_utb"


def test_login_no_recalcula_el_rol(client, db_session):
    _registrar(client, "ana@utb.edu.co")
    user = _usuario(db_session, "ana@utb.edu.co")
    user.rol = "auxiliar"
    db_session.commit()
    assert _me(client, _login(client, "ana@utb.edu.co"))["rol"] == "auxiliar"
    assert asignaciones.rol_resuelto(db_session, user) == "auxiliar"


# --------------------------------------------------------------------------
# Carga masiva: solo cuentas existentes
# --------------------------------------------------------------------------
def test_importacion_con_errores_no_aplica_nada(client, admin_headers, db_session):
    _registrar(client, "ana@utb.edu.co")
    texto = "\n".join([
        "correo;rol;cargo",
        "ana@utb.edu.co;Auditor;Auxiliar de planta",
        "malo@gmail.com;Auditor",
        "luis@utb.edu.co;jefe",
        "ana@utb.edu.co;Administrador",
        "solo-un-campo@utb.edu.co",
    ])
    r = _importar(client, admin_headers, texto)
    assert r.status_code == 200, r.text
    datos = r.json()
    assert datos["aplicado"] is False
    assert [e["linea"] for e in datos["errores"]] == [3, 4, 5, 6]
    assert "institucional" in datos["errores"][0]["error"]
    assert "Rol no válido" in datos["errores"][1]["error"]
    assert "repetido" in datos["errores"][2]["error"]
    assert _usuario(db_session, "ana@utb.edu.co").rol == "usuario_utb"


def test_importacion_aplica_solo_a_cuentas_existentes_y_audita(client, admin_headers, db_session):
    _registrar(client, "ana@utb.edu.co")
    texto = "ana@utb.edu.co,Auditor,Auxiliar de planta\nfantasma@utb.edu.co,Administrador\n"
    vista = _importar(client, admin_headers, texto, simular=True).json()
    assert vista["aplicado"] is False and vista["actualizadas"] == 1
    assert vista["sin_cuenta"] == 1 and vista["correos_sin_cuenta"] == ["fantasma@utb.edu.co"]
    ana = _usuario(db_session, "ana@utb.edu.co")
    assert ana.rol == "usuario_utb"  # la vista previa no guardó nada

    sesion_antes = ana.sesion_version or 0
    r = _importar(client, admin_headers, texto)
    assert r.json()["aplicado"] is True
    ana = _usuario(db_session, "ana@utb.edu.co")
    assert ana.rol == "auxiliar" and ana.dependencia == "Auxiliar de planta"
    assert ana.sesion_version == sesion_antes + 1  # se cierran sus sesiones
    assert db_session.query(Usuario).filter(Usuario.email == "fantasma@utb.edu.co").count() == 0
    cambio = _acciones(db_session, "usuario.rol")[-1]
    assert json.loads(cambio.detalle)["via"] == "importacion"
    resumen = _acciones(db_session, "asignacion_rol.importar")[0]
    assert json.loads(resumen.detalle) == {"actualizadas": 1, "sin_cambios": 0, "sin_cuenta": 1}
    assert "fantasma@" not in resumen.detalle


def test_importacion_no_cambia_el_propio_rol(client, admin_headers):
    r = _importar(client, admin_headers, "admin@utb.edu.co,Estudiante")
    assert r.json()["aplicado"] is False
    assert "propio rol" in r.json()["errores"][0]["error"]
    assert _me(client, admin_headers)["rol"] == "administrador"


def test_importacion_no_deja_el_sistema_sin_administrador(client, admin_headers, db_session):
    otro = _usuario(db_session, "user2@utb.edu.co")
    otro.rol = "administrador"
    db_session.commit()
    # Dos administradores: bajar al otro está permitido (queda el que importa).
    assert _importar(client, admin_headers, "user2@utb.edu.co,Estudiante").json()["aplicado"] is True
    # Con uno solo, desactivado, no quedaría nadie: se pide primero otro administrador.
    unico = _usuario(db_session, "admin@utb.edu.co")
    otro = _usuario(db_session, "user1@utb.edu.co")
    otro.rol = "administrador"
    otro.activo = False
    db_session.commit()
    r = _importar(client, admin_headers, "user1@utb.edu.co,Estudiante")
    assert r.json()["aplicado"] is True  # el inactivo no cuenta como administrador activo
    assert unico.activo


def test_solo_el_administrador_importa(client, auth_headers):
    assert _importar(client, auth_headers, "yo@utb.edu.co,Administrador").status_code == 403


def test_endpoints_viejos_de_la_lista_ya_no_existen(client, admin_headers):
    assert client.get("/usuarios/asignaciones", headers=admin_headers).status_code in (404, 405)
    assert client.post("/usuarios/1/rol/automatico", headers=admin_headers).status_code in (404, 405)


def test_analizar_lista_unidad():
    filas, errores = asignaciones.analizar_lista(
        '# comentario\n"ana@utb.edu.co","Auditor","Planta, edificio A"\n')
    assert errores == []
    assert filas[0]["cargo"] == "Planta, edificio A"
    assert asignaciones.analizar_lista("")[1][0]["error"] == "La lista está vacía"


# --------------------------------------------------------------------------
# Carga por consola (archivo local ignorado por git)
# --------------------------------------------------------------------------
def test_script_carga_roles_a_cuentas_existentes(client, db_session, monkeypatch, tmp_path):
    import sys

    from sqlalchemy.orm import sessionmaker

    from scripts import cargar_asignaciones

    _registrar(client, "ana@utb.edu.co")
    archivo = tmp_path / "asignaciones.csv"
    monkeypatch.setattr(cargar_asignaciones, "SessionLocal",
                        sessionmaker(bind=db_session.get_bind()))
    archivo.write_text("correo;rol;cargo\nmalo@gmail.com;Auditor\n", encoding="utf-8")
    monkeypatch.setattr(sys, "argv", ["cargar_asignaciones.py", str(archivo), "--aplicar"])
    assert cargar_asignaciones.main() == 1  # con errores no guarda nada

    archivo.write_text("correo;rol;cargo\nana@utb.edu.co;Auditor;Planta\n", encoding="utf-8")
    assert cargar_asignaciones.main() == 0
    assert _usuario(db_session, "ana@utb.edu.co").rol == "auxiliar"
    registro = _acciones(db_session, "asignacion_rol.importar")[-1]
    assert json.loads(registro.detalle)["origen"] == "consola"
    assert "ana@" not in registro.detalle


@pytest.mark.parametrize("correo", ["ana+2@utb.edu.co", "user1+tareas@utb.edu.co", "+x@utb.edu.co"])
def test_los_alias_con_mas_no_crean_otra_cuenta_del_mismo_buzon(client, correo):
    r = client.post("/auth/register", json={"nombre": "Alias", "email": correo, "password": CLAVE})
    assert r.status_code == 422
    assert "alias" in json.dumps(r.json(), ensure_ascii=False).lower()


def test_cambiar_correo_tampoco_acepta_alias(client, auth_headers):
    r = client.post("/auth/me/cambiar-correo", headers=auth_headers,
                    json={"correo_nuevo": "user1+otro@utb.edu.co", "password": "TestPassword1"})
    assert r.status_code == 422

"""
Matriz de permisos (ADR-0018): docs/seguridad/matriz-permisos.md es la especificación y esta
prueba la hace cumplir.

1. Cada endpoint de la app tiene una fila en la matriz y el permiso que exige el código es el
   de la fila (si se agrega un endpoint sin fila, falla).
2. Para cada endpoint × (Estudiante, Auditor, Administrador, sin sesión) la respuesta es
   401/403 cuando no debe entrar y NO es 401/403 cuando sí (404/409/422 cuentan como "entró":
   pasó el control de acceso y falló después por los datos de prueba).
"""
import re
from pathlib import Path

import pytest
from fastapi.routing import APIRoute

from app.core import permisos
from app.core.hashing import hash_password
from app.main import app
from app.models.auth_models import Usuario
from app.services.auth import emitir_tokens

MATRIZ = Path(__file__).resolve().parent.parent / "docs" / "seguridad" / "matriz-permisos.md"
ROLES = ("usuario_utb", "auxiliar", "administrador")
_FILA = re.compile(r"^\|\s*(GET|POST|PUT|PATCH|DELETE)\s*\|\s*`([^`]+)`\s*\|[^|]*\|\s*([^|]+?)\s*\|")


def _leer_matriz() -> dict[tuple[str, str], str]:
    filas = {}
    for linea in MATRIZ.read_text(encoding="utf-8").splitlines():
        m = _FILA.match(linea)
        if m:
            filas[(m.group(1), m.group(2))] = m.group(3).strip()
    return filas


def _rutas() -> list[tuple[str, str, APIRoute]]:
    return [(metodo, r.path, r) for r in app.routes if isinstance(r, APIRoute)
            for metodo in sorted(r.methods)]


def _exigido_por_el_codigo(ruta: APIRoute) -> str:
    """Lee las dependencias reales del endpoint: 'público', 'sesión' o el permiso."""
    encontrados: list[str] = []

    def recorrer(dep):
        for sub in dep.dependencies:
            permiso = getattr(sub.call, "permiso", None)
            if permiso is not None:
                encontrados.append(permiso.value)
            elif getattr(sub.call, "__name__", "") in ("get_current_user", "require_verified"):
                encontrados.append("sesión")
            recorrer(sub)

    recorrer(ruta.dependant)
    con_permiso = [e for e in encontrados if e != "sesión"]
    if con_permiso:
        return con_permiso[0]
    return "sesión" if encontrados else "público"


def _nivel(texto: str) -> str:
    """'propio o usuarios.ver' se controla en el servicio: para el código es 'sesión'."""
    return "sesión" if texto.startswith("propio o ") else texto


def test_cada_endpoint_tiene_fila_y_coincide_con_el_codigo():
    matriz = _leer_matriz()
    faltan = [f"{m} {p}" for m, p, _ in _rutas() if (m, p) not in matriz]
    assert not faltan, f"Endpoints sin fila en matriz-permisos.md: {faltan}"
    sobran = [f"{m} {p}" for (m, p) in matriz if (m, p) not in {(a, b) for a, b, _ in _rutas()}]
    assert not sobran, f"Filas de la matriz sin endpoint: {sobran}"
    distintos = [
        f"{m} {p}: matriz={_nivel(matriz[(m, p)])!r} código={_exigido_por_el_codigo(r)!r}"
        for m, p, r in _rutas() if _nivel(matriz[(m, p)]) != _exigido_por_el_codigo(r)
    ]
    assert not distintos, "La matriz no coincide con el código:\n" + "\n".join(distintos)


def test_cada_permiso_de_la_matriz_existe():
    validos = {p.value for p in permisos.Permiso} | {"público", "sesión"}
    usados = {_nivel(v) for v in _leer_matriz().values()}
    assert usados <= validos, usados - validos


def _debe_entrar(nivel: str, rol: str | None) -> bool:
    if nivel == "público":
        return True
    if rol is None:
        return False
    if nivel == "sesión":
        return True
    if nivel.startswith("propio o "):
        # La prueba consulta a OTRO usuario: solo entra quien tiene el permiso.
        return permisos.tiene(rol, permisos.Permiso(nivel.removeprefix("propio o ")))
    return permisos.tiene(rol, permisos.Permiso(nivel))


@pytest.fixture(scope="module")
def entorno():
    """UNA base para toda la matriz (rápido): un usuario verificado por rol.

    Las contraseñas no se usan (los tokens se emiten directo), así que no se cifran por caso.
    """
    from fastapi.testclient import TestClient
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    from app.core.database import Base, get_db
    from tests.conftest import TEST_DATABASE_URL

    extra = {"check_same_thread": False} if TEST_DATABASE_URL.startswith("sqlite") else {}
    engine = create_engine(TEST_DATABASE_URL, connect_args=extra)
    Sesion = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = Sesion()
    clave = hash_password("ClaveDePrueba1")
    ids = {}
    for rol in ROLES:
        u = Usuario(nombre=f"Matriz {rol}", email=f"matriz.{rol}@utb.edu.co", password=clave,
                    rol=rol, email_verificado=True)
        db.add(u)
        db.flush()
        ids[rol] = u.id
    db.commit()

    def override_get_db():
        sesion = Sesion()
        try:
            yield sesion
        finally:
            sesion.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as cliente:
        yield cliente, db, ids
    app.dependency_overrides.clear()
    db.close()
    engine.dispose()


def _cabeceras(db, usuario_id: int | None) -> dict:
    """Token NUEVO en cada petición: algunas rutas (cerrar sesiones) invalidan las anteriores."""
    if usuario_id is None:
        return {}
    db.expire_all()
    user = db.get(Usuario, usuario_id)
    user.activo = True
    db.commit()
    return {"Authorization": f"Bearer {emitir_tokens(user)['access_token']}"}


def _url(path: str) -> str:
    # Ids que no existen: el control de acceso va antes de buscar el registro.
    return re.sub(r"\{[^}]+\}", "987654", path)


CASOS = [(m, p, rol) for m, p, _ in _rutas() for rol in (*ROLES, None)]


@pytest.mark.parametrize(("metodo", "ruta", "rol"), CASOS,
                         ids=[f"{m} {p} {r or 'sin-sesion'}" for m, p, r in CASOS])
def test_acceso_por_rol(entorno, metodo, ruta, rol):
    client, db, ids = entorno
    nivel = _leer_matriz()[(metodo, ruta)]
    cabeceras = _cabeceras(db, ids[rol] if rol else None)
    r = client.request(metodo, _url(ruta), headers=cabeceras, json=None)
    if _debe_entrar(nivel, rol):
        assert r.status_code not in (401, 403), f"{rol} debía entrar: {r.status_code} {r.text}"
    else:
        esperado = 401 if rol is None else 403
        assert r.status_code == esperado, f"{rol} no debía entrar: {r.status_code} {r.text}"

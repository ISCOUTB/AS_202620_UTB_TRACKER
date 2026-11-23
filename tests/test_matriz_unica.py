"""
Una sola fuente de verdad para roles y permisos (ADR-0025).

`app/middleware/matriz_permisos.json` es el único lugar donde se edita. Estas pruebas aseguran que:
el código y el archivo cuadran, la tabla de la documentación dice lo mismo, la app recibe la
matriz del servidor y no guarda una copia propia.
"""
import json
import re
from pathlib import Path

from app.middleware import permisos

RAIZ = Path(__file__).resolve().parent.parent
DOC = RAIZ / "docs" / "seguridad" / "matriz-permisos.md"
JSON = RAIZ / "app" / "middleware" / "matriz_permisos.json"


def _datos():
    return json.loads(JSON.read_text(encoding="utf-8"))


def test_el_archivo_cuadra_con_el_codigo():
    roles = {r["valor"] for r in _datos()["roles"]}
    assert roles == set(permisos.ROLES_VALIDOS)
    en_archivo = {p for r in _datos()["roles"] for p in r["permisos"]}
    # Todo permiso del código lo tiene algún rol (si no, nadie podría usarlo) y viceversa.
    assert en_archivo == {p.value for p in permisos.Permiso}


def test_la_tabla_de_la_documentacion_dice_lo_mismo_que_el_archivo():
    lineas = DOC.read_text(encoding="utf-8").splitlines()
    inicio = next(i for i, l in enumerate(lineas) if l.startswith("## Permisos por rol"))
    cabecera = [c.strip() for c in lineas[inicio + 2].strip("|").split("|")]
    etiquetas = cabecera[1:]
    por_etiqueta = {permisos.ETIQUETAS[v]: v for v in permisos.ROLES_VALIDOS}
    assert set(etiquetas) == set(por_etiqueta), "la tabla debe tener una columna por rol"
    en_doc: dict[str, set[str]] = {por_etiqueta[e]: set() for e in etiquetas}
    for linea in lineas[inicio + 4:]:
        if not linea.startswith("|"):
            break
        celdas = [c.strip() for c in linea.strip("|").split("|")]
        permiso = re.match(r"`([^`]+)`", celdas[0]).group(1)
        for etiqueta, marca in zip(etiquetas, celdas[1:]):
            if marca == "✅":
                en_doc[por_etiqueta[etiqueta]].add(permiso)
    for rol in permisos.ROLES_VALIDOS:
        assert en_doc[rol] == {p.value for p in permisos.PERMISOS_POR_ROL[rol]}, rol


def test_get_roles_devuelve_la_matriz_y_pide_sesion(client, auth_headers):
    assert client.get("/auth/roles").status_code == 401
    r = client.get("/auth/roles", headers=auth_headers)
    assert r.status_code == 200
    assert r.json() == permisos.catalogo()
    assert {x["valor"] for x in r.json()} == set(permisos.ROLES_VALIDOS)


def test_me_trae_los_permisos_del_archivo(client, auth_headers, admin_headers):
    for headers, rol in ((auth_headers, "usuario_utb"), (admin_headers, "administrador")):
        perfil = client.get("/auth/me", headers=headers).json()
        assert perfil["permisos"] == permisos.lista_permisos(rol)


def test_la_app_no_tiene_su_propia_tabla_de_permisos():
    """Ningún archivo de la app puede reconstruir la matriz: solo preguntan puede(permiso)."""
    prohibido = ("Permisos.deRol", "_operacion", "_administracion", "factory Permisos.deRol")
    for dart in (RAIZ / "frontend" / "lib").rglob("*.dart"):
        texto = dart.read_text(encoding="utf-8")
        for palabra in prohibido:
            assert palabra not in texto, f"{dart.name} tiene una copia de la matriz ({palabra})"


def test_un_rol_desconocido_no_tiene_permisos():
    assert permisos.permisos_de("inventado") == frozenset()
    assert permisos.permisos_de(None) == frozenset()

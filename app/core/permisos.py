"""
Modelo de roles y permisos de UTB Tracker (ADR-0018). FUENTE ÚNICA: los routers piden un
permiso con `require_permiso(...)` y la app recibe la lista en `GET /auth/me`; ninguna otra
parte del código compara textos de rol.

Qué permisos tiene cada rol NO está aquí: vive en `matriz_permisos.json` (ADR-0025), el único
lugar donde se edita. Este módulo define los nombres de los permisos y carga/valida el archivo.

Los valores GUARDADOS del rol no cambian (APK instaladas los leen): solo se agregan
etiquetas para mostrar.

    valor guardado   etiqueta
    usuario_utb      Estudiante
    auxiliar         Auditor        (administra salones; NO es la bitácora de auditoría)
    administrador    Administrador  (el equipo: todo + usuarios, bitácora, estadísticas)
"""
import json
from enum import Enum
from pathlib import Path


class Rol(str, Enum):
    ESTUDIANTE = "usuario_utb"
    AUDITOR = "auxiliar"
    ADMINISTRADOR = "administrador"


ROLES_VALIDOS = tuple(r.value for r in Rol)


class Permiso(str, Enum):
    # Todos los roles
    SALONES_VER = "salones.ver"                    # salones, tipo, equipamiento, disponibilidad
    SALONES_SOLICITAR = "salones.solicitar"        # pedir un salón
    SOLICITUDES_PROPIAS = "solicitudes.propias"    # ver y cancelar MIS solicitudes
    REPORTES_CREAR = "reportes.crear"              # reportar un problema de un salón o equipo
    EQUIPOS_VER = "equipos.ver"                    # consultar equipos (fijos en cada salón)
    HORARIOS_VER = "horarios.ver"
    # Auditor y administrador
    SOLICITUDES_GESTIONAR = "solicitudes.gestionar"  # bandeja: aprobar / rechazar cualquiera
    SALONES_ADMINISTRAR = "salones.administrar"      # ocupación, presencia, habilitación (ADR-0022)
    REPORTES_GESTIONAR = "reportes.gestionar"        # ver todos los reportes y atenderlos
    EQUIPOS_GESTIONAR = "equipos.gestionar"          # inventario y mantenimiento
    HORARIOS_GESTIONAR = "horarios.gestionar"
    USUARIOS_VER = "usuarios.ver"                    # nombre de quien pide o reporta
    # Solo administrador
    SALONES_CREAR_CATALOGO = "salones.crear_catalogo"  # crear, renombrar, desactivar (ADR-0021)
    USUARIOS_GESTIONAR = "usuarios.gestionar"        # lista, roles, activar/desactivar
    AUDITORIA_VER = "auditoria.ver"                  # bitácora de cambios (ADR-0010)
    ESTADISTICAS_VER = "estadisticas.ver"
    MODO_PRUEBA = "modo_prueba"                      # ver la app como otro rol (solo interfaz)


def _cargar_matriz() -> dict[str, dict]:
    """Lee app/core/matriz_permisos.json (FUENTE ÚNICA, ADR-0025) y la valida: cada rol del
    enum existe, y cada permiso del archivo existe en `Permiso` (y al revés, uno nuevo en el
    código debe figurar en algún rol o se nota en la prueba). Falla al arrancar si no cuadra."""
    datos = json.loads(MATRIZ_JSON.read_text(encoding="utf-8"))
    roles = {r["valor"]: r for r in datos["roles"]}
    if set(roles) != set(ROLES_VALIDOS):
        raise RuntimeError(f"matriz_permisos.json: roles {sorted(roles)} != {sorted(ROLES_VALIDOS)}")
    validos = {p.value for p in Permiso}
    for rol in roles.values():
        desconocidos = set(rol["permisos"]) - validos
        if desconocidos:
            raise RuntimeError(f"matriz_permisos.json: permisos desconocidos {sorted(desconocidos)}")
    return roles


MATRIZ_JSON = Path(__file__).with_name("matriz_permisos.json")
_MATRIZ = _cargar_matriz()

PERMISOS_POR_ROL: dict[str, frozenset[Permiso]] = {
    valor: frozenset(Permiso(p) for p in rol["permisos"]) for valor, rol in _MATRIZ.items()
}
ETIQUETAS = {valor: rol["etiqueta"] for valor, rol in _MATRIZ.items()}
DESCRIPCIONES = {valor: rol["descripcion"] for valor, rol in _MATRIZ.items()}


def catalogo() -> list[dict]:
    """Roles con etiqueta, descripción y permisos: lo que recibe la app en GET /auth/roles."""
    return [{"valor": valor, "etiqueta": ETIQUETAS[valor], "descripcion": DESCRIPCIONES[valor],
             "permisos": sorted(p.value for p in PERMISOS_POR_ROL[valor])}
            for valor in ROLES_VALIDOS]


def normalizar_rol(rol: str | None) -> str:
    return (rol or "").strip().lower()


def permisos_de(rol: str | None) -> frozenset[Permiso]:
    """Un rol desconocido no tiene permisos (falla cerrado)."""
    return PERMISOS_POR_ROL.get(normalizar_rol(rol), frozenset())


def tiene(rol: str | None, permiso: Permiso) -> bool:
    return permiso in permisos_de(rol)


def lista_permisos(rol: str | None) -> list[str]:
    """Ordenada, para la respuesta de /auth/me."""
    return sorted(p.value for p in permisos_de(rol))


def etiqueta(rol: str | None) -> str:
    return ETIQUETAS.get(normalizar_rol(rol), "Sin rol")

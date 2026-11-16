"""
Modelo de roles y permisos de UTB Tracker (ADR-0018). FUENTE ÚNICA: los routers piden un
permiso con `require_permiso(...)` y la app recibe la lista en `GET /auth/me`; ninguna otra
parte del código compara textos de rol.

Los valores GUARDADOS del rol no cambian (APK instaladas los leen): solo se agregan
etiquetas para mostrar.

    valor guardado   etiqueta
    usuario_utb      Estudiante
    auxiliar         Auditor        (administra salones; NO es la bitácora de auditoría)
    administrador    Administrador  (el equipo: todo + usuarios, bitácora, estadísticas)
"""
from enum import Enum


class Rol(str, Enum):
    ESTUDIANTE = "usuario_utb"
    AUDITOR = "auxiliar"
    ADMINISTRADOR = "administrador"


ROLES_VALIDOS = tuple(r.value for r in Rol)

ETIQUETAS = {
    Rol.ESTUDIANTE.value: "Estudiante",
    Rol.AUDITOR.value: "Auditor",
    Rol.ADMINISTRADOR.value: "Administrador",
}


class Permiso(str, Enum):
    # Todos los roles
    SALONES_VER = "salones.ver"                    # salones, tipo, equipamiento, disponibilidad
    SALONES_SOLICITAR = "salones.solicitar"        # pedir un salón (además exige correo verificado)
    SOLICITUDES_PROPIAS = "solicitudes.propias"    # ver y cancelar MIS solicitudes
    REPORTES_CREAR = "reportes.crear"              # reportar un problema de un salón o equipo
    EQUIPOS_VER = "equipos.ver"                    # consultar equipos (fijos en cada salón)
    HORARIOS_VER = "horarios.ver"
    # Auditor y administrador
    SOLICITUDES_GESTIONAR = "solicitudes.gestionar"  # bandeja: aprobar / rechazar cualquiera
    SALONES_ADMINISTRAR = "salones.administrar"      # ocupación, presencia, crear/editar salones
    REPORTES_GESTIONAR = "reportes.gestionar"        # ver todos los reportes y atenderlos
    EQUIPOS_GESTIONAR = "equipos.gestionar"          # inventario y mantenimiento
    HORARIOS_GESTIONAR = "horarios.gestionar"
    USUARIOS_VER = "usuarios.ver"                    # nombre de quien pide o reporta
    # Solo administrador
    USUARIOS_GESTIONAR = "usuarios.gestionar"        # lista, roles, activar/desactivar
    AUDITORIA_VER = "auditoria.ver"                  # bitácora de cambios (ADR-0010)
    ESTADISTICAS_VER = "estadisticas.ver"
    MODO_PRUEBA = "modo_prueba"                      # ver la app como otro rol (solo interfaz)


_TODOS = {
    Permiso.SALONES_VER, Permiso.SALONES_SOLICITAR, Permiso.SOLICITUDES_PROPIAS,
    Permiso.REPORTES_CREAR, Permiso.EQUIPOS_VER, Permiso.HORARIOS_VER,
}
_OPERACION = {
    Permiso.SOLICITUDES_GESTIONAR, Permiso.SALONES_ADMINISTRAR, Permiso.REPORTES_GESTIONAR,
    Permiso.EQUIPOS_GESTIONAR, Permiso.HORARIOS_GESTIONAR, Permiso.USUARIOS_VER,
}
_ADMINISTRACION = {
    Permiso.USUARIOS_GESTIONAR, Permiso.AUDITORIA_VER, Permiso.ESTADISTICAS_VER,
    Permiso.MODO_PRUEBA,
}

PERMISOS_POR_ROL: dict[str, frozenset[Permiso]] = {
    Rol.ESTUDIANTE.value: frozenset(_TODOS),
    Rol.AUDITOR.value: frozenset(_TODOS | _OPERACION),
    Rol.ADMINISTRADOR.value: frozenset(_TODOS | _OPERACION | _ADMINISTRACION),
}


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

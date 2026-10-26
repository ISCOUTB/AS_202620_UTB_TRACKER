"""
Enumeraciones centralizadas del dominio UTB Tracker.

Define los valores válidos para estados, categorías y roles,
eliminando el uso de strings arbitrarios en modelos y schemas.
"""
from enum import Enum


class EstadoRecurso(str, Enum):
    DISPONIBLE = "disponible"
    PRESTADO = "prestado"
    DANADO = "dañado"
    MANTENIMIENTO = "mantenimiento"


class CategoriaRecurso(str, Enum):
    VIDEO_BEAM = "video_beam"
    COMPUTADOR = "computador"
    AIRE_AC = "aire_ac"
    TV = "tv"
    AUDIO = "audio"
    OTRO = "otro"


class EstadoSalon(str, Enum):
    DISPONIBLE = "disponible"
    OCUPADO = "ocupado"
    MANTENIMIENTO = "mantenimiento"
    FUERA_SERVICIO = "fuera_servicio"


class EstadoPrestamo(str, Enum):
    ACTIVO = "activo"
    DEVUELTO = "devuelto"
    VENCIDO = "vencido"
    CANCELADO = "cancelado"


class EstadoPrestamoSalon(str, Enum):
    PENDIENTE = "pendiente"
    APROBADO = "aprobado"
    RECHAZADO = "rechazado"
    EN_USO = "en_uso"
    FINALIZADO = "finalizado"
    CANCELADO = "cancelado"


class RolUsuario(str, Enum):
    USUARIO_UTB = "usuario_utb"
    ADMINISTRADOR = "administrador"
    AUXILIAR = "auxiliar"


class TipoReporteSalon(str, Enum):
    LIMPIEZA = "limpieza"
    EQUIPO = "equipo"
    INFRAESTRUCTURA = "infraestructura"
    SEGURIDAD = "seguridad"
    OTRO = "otro"


class EstadoReporteSalon(str, Enum):
    ABIERTO = "abierto"
    RESUELTO = "resuelto"


class DiaSemana(int, Enum):
    LUNES = 1
    MARTES = 2
    MIERCOLES = 3
    JUEVES = 4
    VIERNES = 5
    SABADO = 6
    DOMINGO = 7

"""Respuesta de GET /stats/admin (ADR-0018)."""
from pydantic import BaseModel


class UsuariosPorRol(BaseModel):
    rol: str
    etiqueta: str
    total: int


class SalonSolicitado(BaseModel):
    salon: str
    total: int


class EstadisticasAdmin(BaseModel):
    dias: int
    usuarios_activos_por_rol: list[UsuariosPorRol]
    usuarios_inactivos: int
    solicitudes_por_estado: dict[str, int]
    salones_mas_solicitados: list[SalonSolicitado]
    salones_por_tipo: dict[str, int]
    reportes_salon_por_estado: dict[str, int]
    reportes_salon_por_tipo: dict[str, int]

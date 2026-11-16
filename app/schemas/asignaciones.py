"""Esquemas de la lista de asignación de roles por correo (ADR-0019, solo administrador)."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core import permisos


class AsignacionCrear(BaseModel):
    correo: str = Field(..., min_length=5, max_length=254, description="Correo institucional exacto")
    rol: str = Field(..., description="usuario_utb | auxiliar | administrador (o su etiqueta)")
    cargo: Optional[str] = Field(None, max_length=120, description="p. ej. Auxiliar de planta")


class AsignacionEditar(BaseModel):
    model_config = ConfigDict(extra="forbid")

    rol: Optional[str] = None
    cargo: Optional[str] = Field(None, max_length=120)


class AsignacionRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    correo: str
    rol: str
    rol_etiqueta: str = ""
    cargo: Optional[str] = None
    creado_por_id: Optional[int] = None
    creado_en: Optional[datetime] = None
    actualizado_en: Optional[datetime] = None

    @model_validator(mode="after")
    def _etiqueta(self):
        self.rol_etiqueta = permisos.etiqueta(self.rol)
        return self


class ImportarAsignaciones(BaseModel):
    texto: str = Field(..., max_length=200_000,
                       description="Una línea por persona: correo,rol[,cargo] (coma o punto y coma)")
    simular: bool = Field(False, description="True: solo revisa y cuenta, no guarda nada")


class ErrorLinea(BaseModel):
    linea: int
    error: str


class ResultadoImportacion(BaseModel):
    validas: int
    creadas: int
    actualizadas: int
    sin_cambios: int
    errores: list[ErrorLinea]
    aplicado: bool = Field(description="False si hubo errores (no se guardó NINGUNA línea) o si era simulación")

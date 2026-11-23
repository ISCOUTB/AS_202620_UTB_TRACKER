"""Esquemas de la carga masiva de roles (ADR-0024, solo administrador)."""
from pydantic import BaseModel, Field


class ImportarAsignaciones(BaseModel):
    texto: str = Field(..., max_length=200_000,
                       description="Una línea por persona: correo,rol[,cargo] (coma o punto y coma)")
    simular: bool = Field(False, description="True: solo revisa y cuenta, no guarda nada")


class ErrorLinea(BaseModel):
    linea: int
    error: str


class ResultadoImportacion(BaseModel):
    validas: int
    actualizadas: int = Field(description="Cuentas existentes a las que se les cambia el rol o el cargo")
    sin_cambios: int
    sin_cuenta: int = Field(description="Correos sin cuenta: se reportan y NO quedan esperando")
    correos_sin_cuenta: list[str] = []
    errores: list[ErrorLinea]
    aplicado: bool = Field(description="False si hubo errores (no se guardó NINGUNA línea) o si era simulación")

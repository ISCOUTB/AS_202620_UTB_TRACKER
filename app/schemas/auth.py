from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

class UsuarioCreate(BaseModel):
    nombre: str
    rol:str
    password: str
    
class UsuarioLogin(BaseModel):
    nombre: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    email: str | None = None
    
class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    email: str
    fecha_registro: datetime
    rol: str

class UsuarioDelete(BaseModel):
    nombre: str
    id: int
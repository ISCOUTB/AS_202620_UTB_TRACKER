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

class UsuarioDelete(BaseModel):
    nombre: str
    id: int
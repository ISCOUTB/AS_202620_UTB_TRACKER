"""
Modelo de auditoría: bitácora de acciones relevantes del sistema.

Los registros son de solo-agregar: ningún endpoint ni función los modifica, y el ORM rechaza
actualizarlos o borrarlos (ver listeners al final). Para una garantía a nivel de base de datos en
producción se puede añadir un trigger de PostgreSQL; ver docs/adr/0011-auditoria.md.
"""
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, event

from app.core.database import Base


class RegistroAuditoria(Base):
    __tablename__ = "auditoria"

    id = Column(Integer, primary_key=True, index=True)
    ocurrio_en = Column(
        DateTime, nullable=False, index=True,
        default=lambda: datetime.now(timezone.utc).replace(tzinfo=None),
    )
    # Quién actuó. Se guarda también el nombre: la bitácora debe seguir siendo legible si el
    # usuario se desactiva o cambia de nombre.
    actor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True, index=True)
    actor_nombre = Column(String, nullable=True)
    accion = Column(String, nullable=False, index=True)      # p. ej. "salon.presencia"
    entidad = Column(String, nullable=False, index=True)     # p. ej. "salon"
    entidad_id = Column(Integer, nullable=True)
    detalle = Column(Text, nullable=True)                    # JSON con lo que cambió
    request_id = Column(String, nullable=True)               # une el registro con el log HTTP


@event.listens_for(RegistroAuditoria, "before_update")
def _prohibir_actualizar(*_):
    raise PermissionError("Los registros de auditoría no se pueden modificar")


@event.listens_for(RegistroAuditoria, "before_delete")
def _prohibir_borrar(*_):
    raise PermissionError("Los registros de auditoría no se pueden borrar")

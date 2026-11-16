"""retirar el estado "prestado" de los equipos (ADR-0023)

Los equipos son fijos en los salones y NO se prestan (ADR-0010). Un equipo que quedó en
"prestado" sin un préstamo activo es un dato huérfano: pasa a "disponible" (operativo) y el
cambio queda en la bitácora de auditoría. NO se toca ningún préstamo (la tabla `prestamos` se
conserva como histórico) ni los equipos que aún tengan un préstamo activo o vencido.

Solo datos, sin cambios de esquema: el servidor anterior sigue funcionando.

Revision ID: e1f2a3b4c5d6
Revises: d0e1f2a3b4c5
"""
from collections.abc import Sequence

from alembic import op

revision: str = "e1f2a3b4c5d6"
down_revision: str | Sequence[str] | None = "d0e1f2a3b4c5"
branch_labels = None
depends_on = None

_HUERFANOS = (
    "FROM recursos r WHERE r.estado = 'prestado' AND NOT EXISTS ("
    "SELECT 1 FROM prestamos p WHERE p.recurso_id = r.id AND p.estado IN ('activo', 'vencido'))"
)


def upgrade() -> None:
    op.execute(
        "INSERT INTO auditoria (ocurrio_en, actor_nombre, accion, entidad, entidad_id, detalle) "
        "SELECT CURRENT_TIMESTAMP, 'migración e1f2a3b4c5d6', 'recurso.estado', 'recurso', r.id, "
        "'{\"de\": \"prestado\", \"a\": \"disponible\", \"motivo\": \"los equipos no se prestan\"}' "
        + _HUERFANOS
    )
    op.execute(
        "UPDATE recursos SET estado = 'disponible' WHERE id IN (SELECT r.id " + _HUERFANOS + ")"
    )


def downgrade() -> None:
    # No se puede saber cuáles estaban "prestado" sin la bitácora; se deja como está.
    pass

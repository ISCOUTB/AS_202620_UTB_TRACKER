"""normalizar correos de usuarios y hacerlos únicos sin distinguir mayúsculas (ADR-0014)

Antes el correo se guardaba tal cual ("Ana@UTB.edu.co ") y "ana@utb.edu.co" podía registrarse
como otra cuenta. Esta migración:
  1. Pasa todos los correos a minúsculas y sin espacios.
  2. Si dos cuentas quedan con el mismo correo, la MÁS ANTIGUA conserva el correo y las demás
     pasan a "<usuario>+duplicado<id>@<dominio>" (no se borra ninguna cuenta; el administrador
     puede revisarlas desde el panel de usuarios).
  3. Crea el índice único uq_usuarios_email_lower sobre lower(email).

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "b2c3d4e5f6a7"
down_revision: str | Sequence[str] | None = "a1b2c3d4e5f6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    filas = conn.execute(sa.text("SELECT id, email FROM usuarios ORDER BY id")).fetchall()
    vistos: set[str] = set()
    cambios: dict[int, str] = {}
    for fila_id, email in filas:
        normal = (email or "").strip().lower()
        if normal in vistos:
            usuario, _, dominio = normal.partition("@")
            normal = f"{usuario}+duplicado{fila_id}@{dominio}"
            print(f"[migracion] usuario {fila_id}: correo repetido, queda como {normal}")
        vistos.add(normal)
        if normal != email:
            cambios[fila_id] = normal
    # Dos pasos: el índice único que ya existe (sensible a mayúsculas) rechazaría poner
    # "ana@utb.edu.co" a la cuenta 1 mientras la cuenta 2 todavía lo tiene escrito así.
    actualizar = sa.text("UPDATE usuarios SET email = :e WHERE id = :i")
    for fila_id in cambios:
        conn.execute(actualizar, {"e": f"migrando-{fila_id}@migracion.invalid", "i": fila_id})
    for fila_id, normal in cambios.items():
        conn.execute(actualizar, {"e": normal, "i": fila_id})
    op.create_index(
        "uq_usuarios_email_lower", "usuarios", [sa.text("lower(email)")], unique=True
    )


def downgrade() -> None:
    # Los correos normalizados se dejan así: no se puede saber cómo estaban escritos.
    op.drop_index("uq_usuarios_email_lower", table_name="usuarios")

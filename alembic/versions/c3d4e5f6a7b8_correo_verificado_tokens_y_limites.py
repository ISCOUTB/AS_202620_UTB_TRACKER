"""correo verificado, tokens de un solo uso y límites de frecuencia en base de datos (ADR-0014)

- usuarios.email_verificado / email_verificado_en. Las cuentas que YA existían quedan
  verificadas (su correo se usa desde antes y no se las deja fuera); las nuevas nacen sin
  verificar.
- tokens_usados: jti de los tokens de un solo uso ya consumidos.
- intentos_limitados: intentos para los límites de frecuencia (antes, un diccionario en
  memoria que se perdía al reiniciar y no servía con varios procesos).

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "c3d4e5f6a7b8"
down_revision: str | Sequence[str] | None = "b2c3d4e5f6a7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ADD COLUMN directo (no batch): en SQLite el modo batch reconstruye la tabla y se pierde el
    # índice por expresión uq_usuarios_email_lower.
    op.add_column(
        "usuarios",
        sa.Column("email_verificado", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column("usuarios", sa.Column("email_verificado_en", sa.DateTime(), nullable=True))
    op.execute(
        sa.text("UPDATE usuarios SET email_verificado = :si, email_verificado_en = fecha_registro")
        .bindparams(si=True)
    )

    op.create_table(
        "tokens_usados",
        sa.Column("jti", sa.String(64), primary_key=True),
        sa.Column("proposito", sa.String(40), nullable=False),
        sa.Column("usuario_id", sa.Integer(), nullable=True),
        sa.Column("usado_en", sa.DateTime(), nullable=False),
        sa.Column("expira_en", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tokens_usados_usuario_id", "tokens_usados", ["usuario_id"])
    op.create_index("ix_tokens_usados_expira_en", "tokens_usados", ["expira_en"])

    op.create_table(
        "intentos_limitados",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("clave", sa.String(255), nullable=False),
        sa.Column("creado_en", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_intentos_limitados_clave", "intentos_limitados", ["clave"])
    op.create_index("ix_intentos_limitados_creado_en", "intentos_limitados", ["creado_en"])


def downgrade() -> None:
    op.drop_index("ix_intentos_limitados_creado_en", table_name="intentos_limitados")
    op.drop_index("ix_intentos_limitados_clave", table_name="intentos_limitados")
    op.drop_table("intentos_limitados")
    op.drop_index("ix_tokens_usados_expira_en", table_name="tokens_usados")
    op.drop_index("ix_tokens_usados_usuario_id", table_name="tokens_usados")
    op.drop_table("tokens_usados")
    with op.batch_alter_table("usuarios") as t:
        t.drop_column("email_verificado_en")
        t.drop_column("email_verificado")
    # El modo batch de SQLite no conserva índices por expresión: se recrea.
    if op.get_bind().dialect.name == "sqlite":
        op.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_usuarios_email_lower ON usuarios (lower(email))")

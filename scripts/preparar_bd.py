"""
Deja la base de datos (DATABASE_URL o utb_tracker.db) en la última versión del esquema.

- Base nueva o vacía: crea todas las tablas y la marca con la última migración.
- Base creada con create_all (sin tabla alembic_version, típico de la SQLite local de
  iniciar.ps1): detecta hasta qué migración llega mirando sus tablas, columnas e índices, la
  marca ahí y aplica las migraciones que faltan. Así una base vieja no se queda sin las
  columnas nuevas ("no such column ...").
- Base con alembic_version: solo `alembic upgrade head`.

Uso: python scripts/preparar_bd.py
"""
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from sqlalchemy import inspect  # noqa: E402

from app.config.config import DATABASE_URL  # noqa: E402
from app.db.database import Base, engine  # noqa: E402
import app.main  # noqa: E402,F401  (registra todos los modelos en Base.metadata)

# Del más nuevo al más viejo: (revisión, prueba de que el esquema ya la tiene).
MARCAS = [
    ("b8c9d0e1f2a3", lambda i: "fotos_perfil" in i.get_table_names()),
    ("a7b8c9d0e1f2", lambda i: _columna(i, "usuarios", "rol_manual")),
    ("f6a7b8c9d0e1", lambda i: _columna(i, "prestamos_salon", "respuesta")),
    ("e5f6a7b8c9d0", lambda i: _columna(i, "salones", "tipo")),
    ("d4e5f6a7b8c9", lambda i: _columna(i, "usuarios", "preferencias")),
    ("c3d4e5f6a7b8", lambda i: _columna(i, "usuarios", "email_verificado")),
    ("b2c3d4e5f6a7", lambda i: _indice(i, "usuarios", "uq_usuarios_email_lower")),
    ("a1b2c3d4e5f6", lambda i: "auditoria" in i.get_table_names()),
    ("9f0a1b2c3d4e", lambda i: _columna(i, "usuarios", "fcm_token")),
]


def _columna(insp, tabla, columna):
    return tabla in insp.get_table_names() and any(
        c["name"] == columna for c in insp.get_columns(tabla)
    )


def _indice(insp, tabla, nombre):
    return tabla in insp.get_table_names() and any(
        ix["name"] == nombre for ix in insp.get_indexes(tabla)
    )


def main() -> int:
    cfg = Config(str(RAIZ / "alembic.ini"))
    cfg.set_main_option("script_location", str(RAIZ / "alembic"))
    cfg.set_main_option("sqlalchemy.url", DATABASE_URL.replace("%", "%%"))
    insp = inspect(engine)
    tablas = insp.get_table_names()

    if "usuarios" not in tablas:
        print(f"[bd] Base nueva en {DATABASE_URL.split('@')[-1]}: creando tablas")
        Base.metadata.create_all(bind=engine)
        command.stamp(cfg, "head")
        return 0

    if "alembic_version" not in tablas:
        revision = next((rev for rev, tiene in MARCAS if tiene(insp)), None)
        if revision is None:
            print(
                "[bd] La base es demasiado antigua para actualizarla sola. Muévela o bórrala "
                "(utb_tracker.db) y vuelve a arrancar: se creará una nueva con datos de ejemplo."
            )
            return 1
        print(f"[bd] Base sin versión: el esquema llega a {revision}; se marca ahí")
        command.stamp(cfg, revision)

    command.upgrade(cfg, "head")
    # Bases creadas por un seed que no importaba todos los modelos quedaron sin algunas tablas
    # (p. ej. mensajes_outbox, y el worker fallaba). create_all solo crea las que faltan.
    faltantes = set(Base.metadata.tables) - set(inspect(engine).get_table_names())
    if faltantes:
        print(f"[bd] Creando tablas que faltaban: {', '.join(sorted(faltantes))}")
        Base.metadata.create_all(bind=engine)
    print("[bd] Esquema al día")
    return 0


if __name__ == "__main__":
    sys.exit(main())

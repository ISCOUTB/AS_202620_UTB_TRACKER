r"""Muestra el contenido de la base SQLite en la terminal.

    venv\Scripts\python scripts\ver_db.py            # lista tablas y cuántas filas tiene cada una
    venv\Scripts\python scripts\ver_db.py salones    # muestra las filas de una tabla
"""
import sqlite3
import sys
from pathlib import Path

ruta = Path(__file__).resolve().parent.parent / "utb_tracker.db"
con = sqlite3.connect(ruta)
if len(sys.argv) < 2:
    for (t,) in con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"):
        print(f"{t:<28}{con.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>5} filas")
else:
    cur = con.execute(f"SELECT * FROM {sys.argv[1]}")
    cols = [d[0] for d in cur.description if d[0] != "password"]
    print(" | ".join(cols))
    for fila in cur:
        print(" | ".join(str(v) for c, v in zip([d[0] for d in cur.description], fila) if c != "password"))

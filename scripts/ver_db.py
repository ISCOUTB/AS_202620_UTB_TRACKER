r"""Muestra el contenido de la base SQLite en la terminal.

    venv\Scripts\python scripts\ver_db.py            # lista tablas y cuántas filas tiene cada una
    venv\Scripts\python scripts\ver_db.py salones    # muestra las filas de una tabla
"""
import sqlite3
import sys
from pathlib import Path

ruta = Path(__file__).resolve().parent.parent / "utb_tracker.db"
con = sqlite3.connect(ruta)

# Obtener tablas existentes desde el catálogo de SQLite (lista blanca para prevenir inyección SQL)
tablas_validas = {
    row[0]
    for row in con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").fetchall()
}

if len(sys.argv) < 2:
    for t in sorted(tablas_validas):
        con_cur = con.execute(f'SELECT COUNT(*) FROM "{t}"')
        total = con_cur.fetchone()[0]
        print(f"{t:<28}{total:>5} filas")
else:
    tabla_solicitada = sys.argv[1]
    if tabla_solicitada not in tablas_validas:
        print(f"Error: La tabla '{tabla_solicitada}' no existe.")
        print(f"Tablas disponibles: {', '.join(sorted(tablas_validas)) if tablas_validas else 'Ninguna'}")
        sys.exit(1)

    # Usar el valor verificado de la lista blanca interna para desvincular el taint del argumento CLI
    tabla_segura = next(t for t in tablas_validas if t == tabla_solicitada)
    cur = con.execute(f'SELECT * FROM "{tabla_segura}"')
    cols = [d[0] for d in cur.description if d[0] != "password"]
    print(" | ".join(cols))
    for fila in cur:
        print(" | ".join(str(v) for c, v in zip([d[0] for d in cur.description], fila) if c != "password"))

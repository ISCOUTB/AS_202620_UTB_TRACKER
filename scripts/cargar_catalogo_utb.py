r"""
Carga el catálogo de salones UTB (ADR-0021) desde scripts/datos/catalogo_utb.json.

- Crea los salones que falten; NO toca los existentes y NUNCA borra.
- Informa creados / omitidos y el reporte de "salones fuera del catálogo" con una propuesta
  para cada uno (desactivar / renombrar / corregir): decide el administrador.
- No corre solo (ni en migraciones ni en el arranque): se ejecuta a mano.

Uso (desde la raíz del repo, con DATABASE_URL apuntando a la base que quieres cargar):
    venv\Scripts\python scripts\cargar_catalogo_utb.py --simular     # solo muestra qué haría
    venv\Scripts\python scripts\cargar_catalogo_utb.py               # aplica
    venv\Scripts\python scripts\cargar_catalogo_utb.py --archivo otra_lista.json --simular
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.db.database import SessionLocal  # noqa: E402
from app.service import catalogo  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Carga el catálogo de salones UTB.")
    parser.add_argument("--simular", action="store_true", help="No escribe nada; solo informa.")
    parser.add_argument("--archivo", default=str(catalogo.ARCHIVO_CATALOGO))
    args = parser.parse_args()

    datos = catalogo.cargar_archivo(Path(args.archivo))
    db = SessionLocal()
    try:
        resultado = catalogo.aplicar_catalogo(db, datos, simular=args.simular)
        fuera = catalogo.fuera_del_catalogo(db, set(datos["codigos"]))
    finally:
        db.close()

    modo = "SIMULACIÓN (no se escribió nada)" if args.simular else "APLICADO"
    print(f"Catálogo UTB — {modo}")
    print(f"  En el archivo: {len(datos['codigos'])} salones")
    print(f"  {'Se crearían' if args.simular else 'Creados'}: {len(resultado['creados'])}")
    if resultado["creados"]:
        print("    " + ", ".join(resultado["creados"]))
    print(f"  Omitidos (ya existían, no se tocaron): {len(resultado['omitidos'])}")
    print(f"\nSalones fuera del catálogo: {len(fuera)} (nada se borra; decide el administrador)")
    for f in fuera:
        marca = " [tiene historial]" if f["tiene_historial"] else ""
        print(f"  - {f['nombre']} (id {f['id']}){marca}: {f['problema']} → {f['propuesta']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

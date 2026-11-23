"""
Carga la lista inicial de roles por correo institucional (ADR-0019) desde un archivo LOCAL que
no está en el repositorio (privado/ y asignaciones*.csv están en .gitignore).

Formato: una persona por línea, `correo,rol[,cargo]` (coma o punto y coma; encabezado opcional).
El rol puede ser la etiqueta (Estudiante, Auditor, Administrador) o el valor guardado.

    python scripts/cargar_asignaciones.py privado/asignaciones.csv            # revisa y pregunta
    python scripts/cargar_asignaciones.py privado/asignaciones.csv --aplicar  # sin preguntar

Todo o nada: si una línea tiene un error no se guarda ninguna. Las cuentas que ya existen y
verificaron su correo reciben el rol de inmediato (y se cierran sus sesiones). Queda en la
bitácora como "asignacion_rol.importar" con origen "consola" y solo con cifras (sin correos).
Alternativa sin consola: pantalla Perfil > Roles por correo > Importar lista (administrador).
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fastapi import HTTPException  # noqa: E402

from app.core.database import SessionLocal  # noqa: E402
from app.services import asignaciones  # noqa: E402


def main() -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    args.add_argument("archivo", type=Path)
    args.add_argument("--aplicar", action="store_true", help="aplicar sin preguntar")
    opciones = args.parse_args()
    if not opciones.archivo.is_file():
        print(f"No encuentro el archivo {opciones.archivo}.")
        return 1
    texto = opciones.archivo.read_text(encoding="utf-8-sig")

    db = SessionLocal()
    try:
        revision = asignaciones.importar(db, texto, simular=True, actor=None)
        for error in revision["errores"]:
            print(f"  Línea {error['linea']}: {error['error']}")
        if revision["errores"]:
            print("Hay errores: no se guardó nada. Corrige el archivo y vuelve a intentarlo.")
            return 1
        print(f"{revision['validas']} líneas correctas: {revision['creadas']} nuevas, "
              f"{revision['actualizadas']} cambian, {revision['sin_cambios']} sin cambios.")
        if not opciones.aplicar and input("¿Aplicar? (s/N): ").strip().lower() != "s":
            print("No se aplicó nada.")
            return 0
        asignaciones.importar(db, texto, simular=False, actor=None)
        print("Listo: lista aplicada.")
        return 0
    except HTTPException as exc:
        print(exc.detail)
        return 1
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())

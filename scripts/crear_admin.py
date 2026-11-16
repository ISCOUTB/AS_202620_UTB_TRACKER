"""
Crea o promueve un ADMINISTRADOR real (ADR-0018). Es la forma segura de tener el primer
administrador en producción: la contraseña se escribe en la consola (no se ve, no queda en el
historial, ni en el repositorio, ni en el log, ni en la bitácora).

Uso (en el servidor, con el .env cargado y desde la carpeta del proyecto):

    python scripts/crear_admin.py persona@utb.edu.co             # promueve una cuenta existente
    python scripts/crear_admin.py persona@utb.edu.co --crear      # crea la cuenta si no existe

- Promover: la persona ya se registró en la app (como Estudiante); queda como Administrador y
  sus sesiones abiertas se cierran para que el cambio aplique ya.
- Crear: pide nombre y contraseña (dos veces) y cumple la política (mínimo 8 caracteres).
- Queda en la bitácora como "usuario.rol" / "usuario.registro" con actor "consola".
"""
import argparse
import getpass
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.database import SessionLocal  # noqa: E402
from app.core.hashing import hash_password  # noqa: E402
from app.core.permisos import Rol, etiqueta  # noqa: E402
from app.core.politica import correo_valido, error_password, normalizar_correo  # noqa: E402
from app.models.auth_models import Usuario  # noqa: E402
from app.services import auditoria  # noqa: E402
from app.services.auth import buscar_por_correo  # noqa: E402


def _pedir_clave(correo: str, nombre: str) -> str:
    while True:
        clave = getpass.getpass("Contraseña nueva (no se verá al escribir): ")
        error = error_password(clave, correo, nombre)
        if error:
            print(f"  {error}. Intenta otra vez.")
            continue
        if getpass.getpass("Repítela: ") != clave:
            print("  No coinciden. Intenta otra vez.")
            continue
        return clave


def main() -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    args.add_argument("correo")
    args.add_argument("--crear", action="store_true", help="crear la cuenta si no existe")
    opciones = args.parse_args()
    correo = normalizar_correo(opciones.correo)
    if not correo_valido(correo):
        print("Ese correo no es válido.")
        return 1

    db = SessionLocal()
    try:
        user = buscar_por_correo(db, correo)
        if user is None:
            if not opciones.crear:
                print("No hay una cuenta con ese correo. Regístrate en la app o usa --crear.")
                return 1
            nombre = " ".join(input("Nombre de usuario: ").split())
            if not nombre:
                print("El nombre no puede estar vacío.")
                return 1
            user = Usuario(nombre=nombre, email=correo, rol=Rol.ADMINISTRADOR.value,
                           password=hash_password(_pedir_clave(correo, nombre)),
                           email_verificado=True)
            db.add(user)
            db.flush()
            auditoria.registrar(db, "usuario.registro", "usuario", user.id,
                                detalle={"rol": user.rol, "origen": "consola"})
        else:
            anterior = user.rol
            user.rol = Rol.ADMINISTRADOR.value
            user.activo = True
            user.sesion_version = (user.sesion_version or 0) + 1
            auditoria.registrar(db, "usuario.rol", "usuario", user.id, detalle={
                "usuario": user.nombre, "de": anterior, "a": user.rol, "origen": "consola"})
        db.commit()
        print(f"Listo: {user.nombre} ({user.email}) es {etiqueta(user.rol)}.")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())

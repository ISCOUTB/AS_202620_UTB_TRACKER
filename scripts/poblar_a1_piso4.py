"""
Script para poblar la base de datos exactamente con los requerimientos del usuario:
1. Crea un usuario Administrador para pruebas (admin@utb.edu.co / Admin1234*)
2. Limpia los datos de prueba anteriores si se solicita
3. Crea los salones del Edificio A1, Piso 4: A1-401 al A1-406
4. En cada salón agrega:
   - 30 Computadores (categoria: computador)
   - 1 Video Beam (categoria: video_beam)
   - 1 Aire Acondicionado (categoria: aire_ac)
"""
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

from app.db.database import SessionLocal
from app.middleware.hashing import hash_password
from app.middleware.permisos import Rol
from app.models.auth_models import Usuario
from app.models.recurso_models import Recurso
from app.models.salon_models import Salon


def poblar():
    db = SessionLocal()
    try:
        print("--- 1. Creando / Asegurando Administrador de Pruebas ---")
        correo_admin = "admin@utb.edu.co"
        admin = db.query(Usuario).filter(Usuario.email == correo_admin).first()
        if not admin:
            admin = Usuario(
                nombre="Administrador UTB",
                email=correo_admin,
                password=hash_password("Admin1234*"),
                rol=Rol.ADMINISTRADOR.value,
                email_verificado=True,
                rol_manual=True,
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)
            print(f"✅ Administrador creado: {correo_admin} / Clave: Admin1234*")
        else:
            admin.rol = Rol.ADMINISTRADOR.value
            admin.password = hash_password("Admin1234*")
            admin.email_verificado = True
            admin.rol_manual = True
            db.commit()
            print(f"ℹ️ Administrador existente actualizado: {correo_admin} / Clave: Admin1234*")

        print("\n--- 2. Creando salones A1-401 a A1-406 con sus equipos ---")
        salones_a1 = ["A1-401", "A1-402", "A1-403", "A1-404", "A1-405", "A1-406"]

        for codigo in salones_a1:
            salon = db.query(Salon).filter(Salon.nombre == codigo).first()
            if not salon:
                salon = Salon(
                    nombre=codigo,
                    edificio="A1",
                    piso=4,
                    ubicacion=f"Edificio A1, Piso 4, Salón {codigo}",
                    capacidad=30,
                    capacidad_estimada=False,
                    tipo="laboratorio_computo",
                )
                db.add(salon)
                db.commit()
                db.refresh(salon)
                print(f"✅ Creado salón {codigo} (ID: {salon.id})")
            else:
                print(f"ℹ️ Salón {codigo} ya existía (ID: {salon.id})")

            # Ahora verificamos y agregamos los equipos para este salón:
            # 30 computadores
            for i in range(1, 31):
                serial_pc = f"{codigo}-PC-{i:02d}"
                recurso_pc = db.query(Recurso).filter(Recurso.serial == serial_pc).first()
                if not recurso_pc:
                    recurso_pc = Recurso(
                        categoria="computador",
                        serial=serial_pc,
                        salon_id=salon.id,
                        descripcion=f"Computador de Escritorio All-in-One #{i:02d} - {codigo}",
                        estado="disponible",
                        activo=True,
                    )
                    db.add(recurso_pc)

            # 1 Video Beam
            serial_vb = f"{codigo}-VB-01"
            recurso_vb = db.query(Recurso).filter(Recurso.serial == serial_vb).first()
            if not recurso_vb:
                recurso_vb = Recurso(
                    categoria="video_beam",
                    serial=serial_vb,
                    salon_id=salon.id,
                    descripcion=f"Video Beam Epson / BenQ Proyección Full HD - {codigo}",
                    estado="disponible",
                    activo=True,
                )
                db.add(recurso_vb)

            # 1 Aire Acondicionado
            serial_ac = f"{codigo}-AC-01"
            recurso_ac = db.query(Recurso).filter(Recurso.serial == serial_ac).first()
            if not recurso_ac:
                recurso_ac = Recurso(
                    categoria="aire_ac",
                    serial=serial_ac,
                    salon_id=salon.id,
                    descripcion=f"Aire Acondicionado Inverter 24000 BTU - {codigo}",
                    estado="disponible",
                    activo=True,
                )
                db.add(recurso_ac)

            db.commit()
            print(f"   -> Equipos verificados/creados en {codigo}: 30 Computadores, 1 Video Beam, 1 Aire Acondicionado.")

        print("\n🎉 ¡Poblado exitoso de datos!")
    except Exception as e:
        db.rollback()
        print(f"❌ Error al poblar base de datos: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    poblar()

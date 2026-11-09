"""
Script para inicializar el esquema y sembrar datos de prueba para la medición QS-03.
Volumen:
- 3 usuarios de prueba (1 por cada rol: usuario_utb, auxiliar, administrador)
- 35 salones (> 30 requeridos)
- 210 recursos (> 200 requeridos) distribuidos entre los salones
- Horarios académicos para consultas de disponibilidad

Uso:
    python scripts/sembrar_medicion.py
Requiere que DATABASE_URL esté definida en las variables de entorno.
"""
import os
import sys
from datetime import time

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.hashing import hash_password
from app.models.auth_models import Usuario
from app.models.recurso_models import Recurso
from app.models.salon_models import Salon, Horario
from app.messaging.models import MensajeOutbox, NotificacionProcesada  # noqa: F401


def sembrar():
    database_url = os.environ.get("DATABASE_URL", "").strip()
    if not database_url:
        print("ERROR: La variable de entorno DATABASE_URL no está definida.", file=sys.stderr)
        sys.exit(1)

    print("[1/4] Conectando a la base de datos...")
    engine = create_engine(database_url)
    
    print("[2/4] Creando esquema relacional con Base.metadata.create_all()...")
    Base.metadata.create_all(bind=engine)

    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        print("[3/4] Sembrando datos de prueba...")

        # 1. Usuarios por rol
        usuarios_data = [
            ("Estudiante Medicion", "estudiante.medicion@utb.edu.co", "usuario_utb", "Medicion2026!"),
            ("Auxiliar Medicion", "auxiliar.medicion@utb.edu.co", "auxiliar", "Medicion2026!"),
            ("Admin Medicion", "admin.medicion@utb.edu.co", "administrador", "Medicion2026!"),
        ]
        for nombre, email, rol, pwd in usuarios_data:
            existente = session.query(Usuario).filter(Usuario.email == email).first()
            if not existente:
                u = Usuario(
                    nombre=nombre,
                    email=email,
                    rol=rol,
                    password=hash_password(pwd),
                    activo=True,
                )
                session.add(u)
        session.commit()

        # 2. Salones (35 salones)
        edificios = ["Edificio A", "Edificio B", "Edificio C", "Edificio D", "Edificio E"]
        salones_creados = []
        for i in range(1, 36):
            edificio = edificios[(i - 1) % len(edificios)]
            piso = ((i - 1) // len(edificios)) + 1
            codigo_letra = edificio.split()[-1]
            nombre_salon = f"{codigo_letra}-{piso}{i:02d}"
            
            salon = session.query(Salon).filter(Salon.nombre == nombre_salon).first()
            if not salon:
                salon = Salon(
                    nombre=nombre_salon,
                    ubicacion=f"{edificio}, Piso {piso}",
                    edificio=edificio,
                    piso=piso,
                    capacidad=30 + (i % 4) * 10,
                    estado="disponible",
                    activo=True,
                )
                session.add(salon)
                session.flush()
            salones_creados.append(salon)
        session.commit()

        # 3. Horarios para salones (al menos 2 franjas por salón para simular ocupación y disponibilidad)
        for s in salones_creados:
            for dia in [1, 2, 3, 4, 5]:  # Lunes a Viernes
                h_exist = session.query(Horario).filter(Horario.salon_id == s.id, Horario.dia_semana == dia).first()
                if not h_exist:
                    h1 = Horario(
                        salon_id=s.id,
                        dia_semana=dia,
                        hora_inicio=time(7, 0),
                        hora_fin=time(9, 0),
                        profesor="Docente Cátedra",
                        materia="Arquitectura de Software",
                        semestre="2026-2",
                        activo=True,
                    )
                    h2 = Horario(
                        salon_id=s.id,
                        dia_semana=dia,
                        hora_inicio=time(14, 0),
                        hora_fin=time(16, 0),
                        profesor="Docente Laboratorio",
                        materia="Sistemas Distribuidos",
                        semestre="2026-2",
                        activo=True,
                    )
                    session.add_all([h1, h2])
        session.commit()

        # 4. Recursos (210 recursos)
        categorias = ["video_beam", "computador", "aire_ac", "tv", "audio"]
        for j in range(1, 211):
            serial = f"REC-MED-{j:04d}"
            rec_exist = session.query(Recurso).filter(Recurso.serial == serial).first()
            if not rec_exist:
                cat = categorias[(j - 1) % len(categorias)]
                salon_asignado = salones_creados[(j - 1) % len(salones_creados)]
                r = Recurso(
                    categoria=cat,
                    salon_id=salon_asignado.id,
                    serial=serial,
                    estado="disponible" if j % 10 != 0 else "prestado",
                    descripcion=f"Recurso de prueba {cat} #{j}",
                    activo=True,
                )
                session.add(r)
        session.commit()

        print("[4/4] Conteo final de registros en la base de datos:")
        total_usuarios = session.query(Usuario).count()
        total_salones = session.query(Salon).count()
        total_horarios = session.query(Horario).count()
        total_recursos = session.query(Recurso).count()

        print(f"  - Usuarios registrados: {total_usuarios}")
        print(f"  - Salones registrados:  {total_salones}")
        print(f"  - Horarios registrados: {total_horarios}")
        print(f"  - Recursos registrados: {total_recursos}")
        print("Siembra finalizada exitosamente.")

    finally:
        session.close()
        engine.dispose()


if __name__ == "__main__":
    sembrar()


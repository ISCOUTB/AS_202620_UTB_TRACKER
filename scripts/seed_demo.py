"""
Datos de ejemplo de UTB Tracker: usuarios con todos los roles, salones, clases,
préstamos de salón, recursos (video beam, computadores, aire, TV, audio),
préstamos de recursos y reportes.

Uso (desde la raíz del repo):
    venv\\Scripts\\python scripts\\seed_demo.py

Crea las tablas si no existen (SQLite local por defecto) y es REPETIBLE: borra y
vuelve a crear solo lo "DEMO" (salones DEMO-*, recursos DEMO-*). Vuélvelo a correr
cuando quieras que las clases de ejemplo coincidan con la hora actual.
"""
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.database import Base, SessionLocal, engine  # noqa: E402
from app.core.hashing import hash_password  # noqa: E402
from app.models import Horario, Prestamo, PrestamoSalon, Recurso, Reporte, Salon, Usuario  # noqa: E402
from app.models.salon_models import PresenciaSalon, ReporteSalon  # noqa: E402

CAMPUS = timezone(timedelta(hours=-5))

# (nombre, email, rol, clave)  — el login de la app pide NOMBRE + clave
USUARIOS = [
    ("Admin Demo", "admin@utb.edu.co", "administrador", "Admin123!"),
    ("Auxiliar Demo", "auxiliar@utb.edu.co", "auxiliar", "Auxiliar123!"),
    ("Auxiliar Laboratorio", "auxiliar2@utb.edu.co", "auxiliar", "Auxiliar123!"),
    ("Estudiante Demo", "estudiante@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Camila Rojas", "camila@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Andres Torres", "andres@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Valentina Diaz", "valentina@utb.edu.co", "usuario_utb", "Estudiante123!"),
]

# (nombre, edificio, piso, capacidad)
SALONES = [
    ("DEMO-A101", "A", 1, 30), ("DEMO-A102", "A", 1, 35), ("DEMO-A103", "A", 1, 40),
    ("DEMO-B201", "B", 2, 45), ("DEMO-B202", "B", 2, 50), ("DEMO-B203", "B", 2, 40),
    ("DEMO-LAB1", "Laboratorios", 3, 25), ("DEMO-LAB2", "Laboratorios", 3, 25),
]

# (categoria, serial, estado, descripcion, salón donde está)
RECURSOS = [
    ("video_beam", "DEMO-VB-001", "disponible", "Video beam Epson X49", "DEMO-A101"),
    ("video_beam", "DEMO-VB-002", "disponible", "Video beam BenQ MS550", "DEMO-A102"),
    ("video_beam", "DEMO-VB-003", "prestado", "Video beam Epson S41", None),
    ("video_beam", "DEMO-VB-004", "dañado", "Video beam Optoma, lámpara quemada", None),
    ("computador", "DEMO-PC-001", "disponible", "Portátil Lenovo ThinkPad", None),
    ("computador", "DEMO-PC-002", "prestado", "Portátil HP ProBook", None),
    ("computador", "DEMO-PC-003", "mantenimiento", "PC de escritorio Dell", "DEMO-LAB1"),
    ("aire_ac", "DEMO-AC-001", "disponible", "Aire acondicionado 24000 BTU", "DEMO-B201"),
    ("aire_ac", "DEMO-AC-002", "dañado", "Aire acondicionado sin enfriar", "DEMO-B202"),
    ("tv", "DEMO-TV-001", "disponible", "Televisor Samsung 55 pulgadas", "DEMO-B203"),
    ("audio", "DEMO-AU-001", "disponible", "Parlante JBL con micrófono", None),
    ("audio", "DEMO-AU-002", "prestado", "Micrófono inalámbrico Shure", None),
    ("otro", "DEMO-OT-001", "disponible", "Extensión eléctrica y adaptador HDMI", None),
]


def utc(d: datetime) -> datetime:
    return d.astimezone(timezone.utc).replace(tzinfo=None)


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ahora = datetime.now(CAMPUS)
        inicio = max(
            (ahora - timedelta(minutes=30)).replace(second=0, microsecond=0),
            ahora.replace(hour=0, minute=0, second=0, microsecond=0),
        )
        fin = inicio + timedelta(hours=2)
        if fin.date() != inicio.date():  # no cruzar la medianoche
            fin = inicio.replace(hour=23, minute=59)

        # ── Limpieza de lo DEMO anterior ─────────────────────────────────────
        salon_ids = [s.id for s in db.query(Salon).filter(Salon.nombre.like("DEMO-%"))]
        rec_ids = [r.id for r in db.query(Recurso).filter(Recurso.serial.like("DEMO-%"))]
        if rec_ids:
            db.query(Reporte).filter(Reporte.recurso_id.in_(rec_ids)).delete(synchronize_session=False)
            db.query(Prestamo).filter(Prestamo.recurso_id.in_(rec_ids)).delete(synchronize_session=False)
            db.query(Recurso).filter(Recurso.id.in_(rec_ids)).delete(synchronize_session=False)
        if salon_ids:
            for modelo in (ReporteSalon, PresenciaSalon, PrestamoSalon, Horario):
                db.query(modelo).filter(modelo.salon_id.in_(salon_ids)).delete(synchronize_session=False)
            db.query(Recurso).filter(Recurso.salon_id.in_(salon_ids)).update(
                {Recurso.salon_id: None}, synchronize_session=False
            )
            db.query(Salon).filter(Salon.id.in_(salon_ids)).delete(synchronize_session=False)
        db.flush()

        # ── Usuarios ─────────────────────────────────────────────────────────
        u = {}
        for nombre, email, rol, clave in USUARIOS:
            fila = db.query(Usuario).filter(Usuario.email == email).first()
            if not fila:
                fila = Usuario(nombre=nombre, email=email, rol=rol, password=hash_password(clave))
                db.add(fila)
            else:
                fila.nombre, fila.rol, fila.activo = nombre, rol, True
                fila.password = hash_password(clave)
            u[email] = fila
        db.flush()

        # ── Salones ──────────────────────────────────────────────────────────
        s = {}
        for nombre, edificio, piso, cap in SALONES:
            fila = Salon(
                nombre=nombre, ubicacion=f"Edificio {edificio}, piso {piso}",
                edificio=edificio, piso=piso, capacidad=cap, estado="disponible",
            )
            db.add(fila)
            s[nombre] = fila
        db.flush()

        # Clases en curso ahora (A101 y B201), una clase libre de otro día y una
        # que ya terminó hoy, para que el plano tenga variedad.
        for nombre, prof, materia in [
            ("DEMO-A101", "Ana Pérez", "Cálculo II"),
            ("DEMO-B201", "Luis Gómez", "Bases de datos"),
            ("DEMO-LAB1", "Marta Ruiz", "Redes de computadores"),
        ]:
            db.add(Horario(
                salon_id=s[nombre].id, dia_semana=ahora.isoweekday(),
                hora_inicio=inicio.time(), hora_fin=fin.time(),
                profesor=prof, materia=materia, semestre="2026-2",
            ))
        db.add(Horario(
            salon_id=s["DEMO-B203"].id, dia_semana=(ahora.isoweekday() % 7) + 1,
            hora_inicio=inicio.time(), hora_fin=fin.time(),
            profesor="Jorge Mendoza", materia="Ingeniería de software", semestre="2026-2",
        ))

        # ── Préstamos de salón ───────────────────────────────────────────────
        est, cam, andres, val = (u["estudiante@utb.edu.co"], u["camila@utb.edu.co"],
                                 u["andres@utb.edu.co"], u["valentina@utb.edu.co"])
        db.add_all([
            PrestamoSalon(salon_id=s["DEMO-A103"].id, usuario_id=est.id, motivo="Grupo de estudio",
                          fecha_inicio=utc(ahora - timedelta(minutes=15)),
                          fecha_fin=utc(ahora + timedelta(hours=1)), estado="aprobado"),
            PrestamoSalon(salon_id=s["DEMO-B202"].id, usuario_id=cam.id, motivo="Ensayo de exposición",
                          fecha_inicio=utc(ahora - timedelta(minutes=10)),
                          fecha_fin=utc(ahora + timedelta(hours=2)), estado="en_uso"),
            PrestamoSalon(salon_id=s["DEMO-A102"].id, usuario_id=andres.id, motivo="Tutoría de álgebra",
                          fecha_inicio=utc(ahora + timedelta(hours=3)),
                          fecha_fin=utc(ahora + timedelta(hours=5)), estado="pendiente"),
            PrestamoSalon(salon_id=s["DEMO-A102"].id, usuario_id=val.id, motivo="Reunión de semillero",
                          fecha_inicio=utc(ahora + timedelta(hours=6)),
                          fecha_fin=utc(ahora + timedelta(hours=7)), estado="pendiente"),
            PrestamoSalon(salon_id=s["DEMO-B203"].id, usuario_id=est.id, motivo="Práctica de tesis",
                          fecha_inicio=utc(ahora - timedelta(days=1)),
                          fecha_fin=utc(ahora - timedelta(days=1) + timedelta(hours=2)), estado="rechazado"),
        ])
        db.add_all([
            ReporteSalon(salon_id=s["DEMO-B202"].id, usuario_id=est.id, tipo="equipo",
                         descripcion="El proyector no enciende", estado="abierto"),
            ReporteSalon(salon_id=s["DEMO-A101"].id, usuario_id=cam.id, tipo="limpieza",
                         descripcion="Tablero sin borrar y basura en el piso", estado="abierto"),
            ReporteSalon(salon_id=s["DEMO-A103"].id, usuario_id=andres.id, tipo="infraestructura",
                         descripcion="Gotera en el techo", estado="resuelto",
                         resuelto_en=utc(ahora - timedelta(hours=3))),
        ])

        # ── Recursos y préstamos de recursos ─────────────────────────────────
        r = {}
        for cat, serial, estado, desc, salon in RECURSOS:
            fila = Recurso(categoria=cat, serial=serial, estado=estado, descripcion=desc,
                           salon_id=s[salon].id if salon else None)
            db.add(fila)
            r[serial] = fila
        db.flush()
        for serial, quien in [("DEMO-VB-003", cam), ("DEMO-PC-002", andres), ("DEMO-AU-002", val)]:
            db.add(Prestamo(recurso_id=r[serial].id, usuario_id=quien.id, estado="activo",
                            fecha_prestamo=utc(ahora - timedelta(hours=1)),
                            fecha_devolucion_esperada=utc(ahora + timedelta(hours=3))))
        db.add(Prestamo(recurso_id=r["DEMO-VB-001"].id, usuario_id=est.id, estado="devuelto",
                        fecha_prestamo=utc(ahora - timedelta(days=2)),
                        fecha_devolucion_esperada=utc(ahora - timedelta(days=2) + timedelta(hours=4)),
                        fecha_devolucion_real=utc(ahora - timedelta(days=2) + timedelta(hours=3))))
        db.add(Reporte(recurso_id=r["DEMO-VB-004"].id, usuario_id=est.id, estado_reportado="dañado",
                       descripcion="La lámpara se quemó durante la clase"))
        db.commit()

        print("Datos de demostración listos. Entra con NOMBRE + clave:")
        for nombre, email, rol, clave in USUARIOS:
            print(f"  {rol:<14} {nombre:<22} {clave:<15} ({email})")
    finally:
        db.close()


if __name__ == "__main__":
    main()

r"""
Datos de ejemplo de UTB Tracker, modelados sobre el Campus Tecnológico de la UTB
(Ternera, km 1 vía Turbaco, Cartagena).

Uso (desde la raíz del repo):
    venv\Scripts\python scripts\seed_demo.py

Qué es real y qué es inventado:
- Los EDIFICIOS son los del campus: Aulas 1, Aulas 2 y Aulas 4 (la app oficial UTB App muestra
  salones como "ED. AULAS 4 · A4-204"), Alcatraz (salas de estudio), los laboratorios de física,
  eléctrica y mecánica, las salas de sistemas, el laboratorio de energía LEAD, El Patio
  (creatividad e innovación) y la biblioteca Luis Enrique Borja Barón.
- Los CÓDIGOS siguen la convención de la UTB: <edificio>-<piso><número> (A4-204 = Aulas 4,
  piso 2, salón 04). Los laboratorios usan siglas (LAB-FIS). La lista completa no es pública,
  así que algunos números son de ejemplo.
- Personas, profesores, materias y equipos son inventados.

Los equipos NO se prestan (ADR-0010): cada uno está fijo en su salón y solo se controla su
estado (disponible, dañado, mantenimiento).

Es REPETIBLE: borra y vuelve a crear solo los salones y equipos de esta lista (y los DEMO-* de
versiones anteriores). Vuélvelo a correr para que las clases coincidan con la hora actual.
"""
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import or_  # noqa: E402

from app.core.database import Base, SessionLocal, engine  # noqa: E402
from app.core.hashing import hash_password  # noqa: E402
from app.models import Horario, Prestamo, PrestamoSalon, Recurso, Reporte, Salon, Usuario  # noqa: E402
from app.models.salon_models import PresenciaSalon, ReporteSalon  # noqa: E402

CAMPUS = timezone(timedelta(hours=-5))  # Colombia no tiene horario de verano
SEDE = "Campus Tecnológico"

# (nombre, email, rol, clave) — el login de la app pide NOMBRE + clave
USUARIOS = [
    ("Admin Demo", "admin@utb.edu.co", "administrador", "Admin123!"),
    ("Auxiliar Demo", "auxiliar@utb.edu.co", "auxiliar", "Auxiliar123!"),
    ("Auxiliar Laboratorio", "auxiliar2@utb.edu.co", "auxiliar", "Auxiliar123!"),
    ("Estudiante Demo", "estudiante@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Camila Rojas", "camila@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Andres Torres", "andres@utb.edu.co", "usuario_utb", "Estudiante123!"),
    ("Valentina Diaz", "valentina@utb.edu.co", "usuario_utb", "Estudiante123!"),
]

# (código, edificio, piso, capacidad, estado, descripción del espacio)
SALONES = [
    ("A1-101", "Aulas 1", 1, 40, "disponible", "Aula de clase"),
    ("A1-104", "Aulas 1", 1, 40, "disponible", "Aula de clase"),
    ("A1-201", "Aulas 1", 2, 35, "mantenimiento", "Aula de clase"),
    ("A1-304", "Aulas 1", 3, 30, "disponible", "Aula de clase"),
    ("A2-102", "Aulas 2", 1, 45, "disponible", "Aula de clase"),
    ("A2-203", "Aulas 2", 2, 40, "disponible", "Aula de clase"),
    ("A2-305", "Aulas 2", 3, 40, "disponible", "Aula de clase"),
    ("A4-102", "Aulas 4", 1, 45, "disponible", "Aula de clase"),
    ("A4-204", "Aulas 4", 2, 40, "disponible", "Aula de clase"),
    ("A4-206", "Aulas 4", 2, 40, "disponible", "Aula de clase"),
    ("A4-301", "Aulas 4", 3, 35, "disponible", "Aula de clase"),
    ("ALC-201", "Alcatraz", 2, 12, "disponible", "Sala de estudio grupal"),
    ("ALC-301", "Alcatraz", 3, 20, "disponible", "Sala de estudio"),
    ("LAB-FIS", "Laboratorios", 1, 24, "disponible", "Laboratorio de Física"),
    ("LAB-ELE", "Laboratorios", 1, 24, "disponible", "Laboratorio de Eléctrica"),
    ("LAB-MEC", "Laboratorios", 1, 20, "fuera_servicio", "Laboratorio de Mecánica"),
    ("LAB-SIS1", "Laboratorios", 2, 30, "disponible", "Sala de sistemas 1"),
    ("LAB-SIS2", "Laboratorios", 2, 30, "disponible", "Sala de sistemas 2"),
    ("LEAD", "Laboratorios", 2, 20, "disponible", "Laboratorio de Energía LEAD"),
    ("EL-PATIO", "Laboratorios", 1, 25, "disponible", "Laboratorio de Creatividad e Innovación El Patio"),
    ("BIB-SG1", "Biblioteca", 2, 8, "disponible", "Sala grupal, Biblioteca Luis Enrique Borja Barón"),
]

# Clases "en curso" cuando se corre el script.
# (salón, profesor, materia, ¿el auxiliar ya confirmó al profesor? None = sin confirmar)
CLASES_AHORA = [
    ("A4-204", "Adriana Argumedo", "Creatividad y Emprendimiento", None),
    ("A1-304", "Ana Pérez", "Arquitectura de Software", None),
    ("A2-203", "Luis Gómez", "Bases de Datos", True),
    ("LAB-SIS1", "Marta Ruiz", "Redes de Computadores", None),
    ("LAB-FIS", "Jorge Mendoza", "Física Mecánica", False),
    ("A1-101", "Carolina Vega", "Cálculo Integral", None),
]
# Clases de la próxima franja (2 h después), para la línea de tiempo "Próxima hora".
CLASES_DESPUES = [
    ("A4-206", "Ricardo Salas", "Ecuaciones Diferenciales"),
    ("A2-102", "Paola Herrera", "Estadística"),
    ("LAB-SIS2", "Diego Castro", "Programación Orientada a Objetos"),
]

# Equipos fijos por tipo de espacio. Serial = prefijo + código del salón, p. ej. VB-A4-204.
EQUIPOS_POR_ESPACIO = {
    "aula": [("video_beam", "VB", "Video beam Epson PowerLite"),
             ("aire_ac", "AC", "Aire acondicionado 24000 BTU")],
    "estudio": [("tv", "TV", "Televisor 55\" para presentaciones"),
                ("aire_ac", "AC", "Aire acondicionado 18000 BTU")],
    "laboratorio": [("video_beam", "VB", "Video beam BenQ"),
                    ("aire_ac", "AC", "Aire acondicionado 36000 BTU"),
                    ("computador", "PC", "PC del docente")],
    "biblioteca": [("tv", "TV", "Pantalla para trabajo en grupo")],
}
PCS_POR_SALA_DE_SISTEMAS = 6
# Equipos con novedades, para que haya algo que atender
ESTADOS_ESPECIALES = {
    "VB-A1-201": ("dañado", "Lámpara quemada"),
    "AC-A1-104": ("dañado", "No enfría"),
    "AC-A4-204": ("dañado", "Gotea agua sobre los pupitres"),
    "PC-LAB-SIS2-03": ("mantenimiento", "Formateo programado"),
    "VB-LAB-MEC": ("mantenimiento", "Salón fuera de servicio"),
}


def tipo_de_espacio(codigo: str) -> str:
    if codigo.startswith("ALC-"):
        return "estudio"
    if codigo.startswith("BIB-"):
        return "biblioteca"
    if codigo.startswith(("LAB-", "LEAD", "EL-PATIO")):
        return "laboratorio"
    return "aula"


def inventario() -> list[tuple[str, str, str, str, str]]:
    """(categoría, serial, estado, descripción, salón) para todos los equipos de ejemplo."""
    filas = []
    for codigo, *_ in SALONES:
        for cat, prefijo, desc in EQUIPOS_POR_ESPACIO[tipo_de_espacio(codigo)]:
            filas.append((cat, f"{prefijo}-{codigo}", desc, codigo))
        if codigo.startswith("LAB-SIS"):
            for n in range(1, PCS_POR_SALA_DE_SISTEMAS + 1):
                filas.append(("computador", f"PC-{codigo}-{n:02d}", "PC de estudiante", codigo))
    resultado = []
    for cat, serial, desc, codigo in filas:
        estado, nota = ESTADOS_ESPECIALES.get(serial, ("disponible", None))
        resultado.append((cat, serial, estado, f"{desc} · {nota}" if nota else desc, codigo))
    return resultado


def utc(d: datetime) -> datetime:
    return d.astimezone(timezone.utc).replace(tzinfo=None)


def limpiar(db) -> None:
    """Borra los salones y equipos de ejemplo (de esta lista y los DEMO-* antiguos)."""
    codigos = [s[0] for s in SALONES]
    seriales = [e[1] for e in inventario()]
    salon_ids = [s.id for s in db.query(Salon).filter(
        or_(Salon.nombre.like("DEMO-%"), Salon.nombre.in_(codigos)))]
    rec_ids = [r.id for r in db.query(Recurso).filter(
        or_(Recurso.serial.like("DEMO-%"), Recurso.serial.in_(seriales)))]
    if rec_ids:
        db.query(Reporte).filter(Reporte.recurso_id.in_(rec_ids)).delete(synchronize_session=False)
        db.query(Prestamo).filter(Prestamo.recurso_id.in_(rec_ids)).delete(synchronize_session=False)
        db.query(Recurso).filter(Recurso.id.in_(rec_ids)).delete(synchronize_session=False)
    if salon_ids:
        for modelo in (ReporteSalon, PresenciaSalon, PrestamoSalon, Horario):
            db.query(modelo).filter(modelo.salon_id.in_(salon_ids)).delete(synchronize_session=False)
        db.query(Recurso).filter(Recurso.salon_id.in_(salon_ids)).update(
            {Recurso.salon_id: None}, synchronize_session=False)
        db.query(Salon).filter(Salon.id.in_(salon_ids)).delete(synchronize_session=False)
    db.flush()


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
        luego_ini = fin
        luego_fin = min(fin + timedelta(hours=2), fin.replace(hour=23, minute=59))

        limpiar(db)

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
        for codigo, edificio, piso, cap, estado, desc in SALONES:
            fila = Salon(
                nombre=codigo, ubicacion=f"{desc} · Ed. {edificio}, piso {piso} · {SEDE}",
                edificio=edificio, piso=piso, capacidad=cap, estado=estado,
            )
            db.add(fila)
            s[codigo] = fila
        db.flush()

        # ── Horario: clases en curso, próxima franja y una de mañana ──────────
        aux = u["auxiliar@utb.edu.co"]
        for codigo, prof, materia, confirmado in CLASES_AHORA:
            clase = Horario(salon_id=s[codigo].id, dia_semana=ahora.isoweekday(),
                            hora_inicio=inicio.time(), hora_fin=fin.time(),
                            profesor=prof, materia=materia, semestre="2026-2")
            db.add(clase)
            if confirmado is not None:
                db.flush()
                db.add(PresenciaSalon(salon_id=s[codigo].id, horario_id=clase.id,
                                      registrado_por=aux.id, profesor_presente=confirmado,
                                      fecha=ahora.date()))
        if luego_fin > luego_ini:
            for codigo, prof, materia in CLASES_DESPUES:
                db.add(Horario(salon_id=s[codigo].id, dia_semana=ahora.isoweekday(),
                               hora_inicio=luego_ini.time(), hora_fin=luego_fin.time(),
                               profesor=prof, materia=materia, semestre="2026-2"))
        db.add(Horario(salon_id=s["A4-204"].id, dia_semana=(ahora.isoweekday() % 7) + 1,
                       hora_inicio=inicio.time(), hora_fin=fin.time(),
                       profesor="Jorge Mendoza", materia="Ingeniería de Software", semestre="2026-2"))

        # ── Solicitudes de salón (los salones SÍ se solicitan) ────────────────
        est, cam, andres, val = (u["estudiante@utb.edu.co"], u["camila@utb.edu.co"],
                                 u["andres@utb.edu.co"], u["valentina@utb.edu.co"])
        db.add_all([
            PrestamoSalon(salon_id=s["ALC-201"].id, usuario_id=est.id, motivo="Grupo de estudio",
                          fecha_inicio=utc(ahora - timedelta(minutes=15)),
                          fecha_fin=utc(ahora + timedelta(hours=1)), estado="aprobado"),
            PrestamoSalon(salon_id=s["A4-102"].id, usuario_id=cam.id, motivo="Ensayo de exposición",
                          fecha_inicio=utc(ahora - timedelta(minutes=10)),
                          fecha_fin=utc(ahora + timedelta(hours=2)), estado="en_uso"),
            PrestamoSalon(salon_id=s["A2-305"].id, usuario_id=andres.id, motivo="Tutoría de álgebra",
                          fecha_inicio=utc(ahora + timedelta(hours=3)),
                          fecha_fin=utc(ahora + timedelta(hours=5)), estado="pendiente"),
            PrestamoSalon(salon_id=s["BIB-SG1"].id, usuario_id=val.id, motivo="Reunión de semillero",
                          fecha_inicio=utc(ahora + timedelta(hours=6)),
                          fecha_fin=utc(ahora + timedelta(hours=7)), estado="pendiente"),
            PrestamoSalon(salon_id=s["ALC-301"].id, usuario_id=est.id, motivo="Práctica de tesis",
                          fecha_inicio=utc(ahora - timedelta(days=1)),
                          fecha_fin=utc(ahora - timedelta(days=1) + timedelta(hours=2)), estado="rechazado"),
        ])

        # ── Reportes de salón ────────────────────────────────────────────────
        db.add_all([
            ReporteSalon(salon_id=s["A4-204"].id, usuario_id=est.id, tipo="equipo",
                         descripcion="El aire gotea sobre los pupitres", estado="abierto"),
            ReporteSalon(salon_id=s["A1-101"].id, usuario_id=cam.id, tipo="limpieza",
                         descripcion="Tablero sin borrar y basura en el piso", estado="abierto"),
            ReporteSalon(salon_id=s["A1-104"].id, usuario_id=andres.id, tipo="equipo",
                         descripcion="El aire no enfría", estado="abierto"),
            ReporteSalon(salon_id=s["A2-102"].id, usuario_id=andres.id, tipo="infraestructura",
                         descripcion="Gotera en el techo", estado="resuelto",
                         resuelto_en=utc(ahora - timedelta(hours=3))),
        ])

        # ── Equipos fijos en cada salón (no se prestan) ──────────────────────
        r = {}
        for cat, serial, estado, desc, codigo in inventario():
            fila = Recurso(categoria=cat, serial=serial, estado=estado, descripcion=desc,
                           salon_id=s[codigo].id)
            db.add(fila)
            r[serial] = fila
        db.flush()
        db.add(Reporte(recurso_id=r["VB-A1-201"].id, usuario_id=est.id, estado_reportado="dañado",
                       descripcion="La lámpara se quemó durante la clase"))
        db.commit()

        print(f"{len(SALONES)} salones y {len(r)} equipos en el {SEDE}.")
        print("Datos de demostración listos. Entra con NOMBRE + clave:")
        for nombre, email, rol, clave in USUARIOS:
            print(f"  {rol:<14} {nombre:<22} {clave:<15} ({email})")
    finally:
        db.close()


if __name__ == "__main__":
    main()

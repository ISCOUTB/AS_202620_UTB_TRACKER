"""
Actividad de DEMOSTRACIÓN sobre los salones del catálogo (ADR-0021): horarios, estudiantes,
solicitudes, reportes, mantenimiento y bitácora. Datos FICTICIOS para la exposición.

- NO crea salones y NO borra nada (salvo con --quitar). Repetible: lo que ya existe se salta.
- Corre DESPUÉS de scripts/cargar_equipos_demo.py (los reportes se vinculan a esos equipos).
- Cómo se identifica lo de demostración (para limpiarlo): estudiantes `estNN.demo@utb.edu.co`
  (sus solicitudes, reportes y bitácora salen de ahí), horarios con semestre "2026-2 DEMO" y
  equipos con serial `DEMO-...`.
- El horario está pensado para el día y la hora de la exposición (por defecto lunes 2026-11-23,
  10:00, hora de Colombia): ese día se ve de todo: salones ocupados, con clase en la próxima
  franja, con clase más tarde y libres.

    python scripts/cargar_demo_actividad.py --simular            # solo cuenta
    python scripts/cargar_demo_actividad.py --hora 9             # otra hora de exposición
    python scripts/cargar_demo_actividad.py --quitar             # retira lo de demostración
"""
import argparse
import json
import sys
import zlib
from datetime import date, datetime, time, timedelta, timezone
from pathlib import Path

from sqlalchemy import func

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core import config  # noqa: E402
from app.core.database import SessionLocal  # noqa: E402
from app.core.hashing import hash_password  # noqa: E402
from app.models import Recurso, Reporte, Salon, Usuario  # noqa: E402
from app.models.auditoria_models import RegistroAuditoria  # noqa: E402
from app.models.recurso_models import MantenimientoRecurso  # noqa: E402
from app.models.salon_models import (  # noqa: E402
    Horario, PrestamoSalon, ReporteSalon,
)
from app.services import auditoria  # noqa: E402
from scripts.cargar_equipos_demo import SALON_DESHABILITADO, codigos_del_catalogo  # noqa: E402

SEMESTRE = "2026-2 DEMO"
FECHA = date(2026, 11, 23)  # lunes de la exposición
CLAVE_ESTUDIANTES = "Demo2026"
# Cuentas por rol (si faltan se crean; si ya existen NO se les cambia la clave). Solo aquí están
# las claves. Todo ficticio.
CUENTAS = [
    ("Admin Demo", "admin@utb.edu.co", "administrador", "Admin123!"),
    ("Auditor Demo", "auxiliar@utb.edu.co", "auxiliar", "Auxiliar123!"),
    ("Estudiante Demo", "estudiante@utb.edu.co", "usuario_utb", "Estudiante123!"),
]
ESTUDIANTES = [
    "Valeria Ospina", "Santiago Rueda", "Mariana Cortés", "Daniel Pineda", "Laura Bermúdez",
    "Esteban Cárdenas", "Natalia Vergara", "Felipe Arrieta", "Camila Montoya", "Julián Mercado",
]
DOCENTES = [
    "Marcela Quintero", "Hernán Pacheco", "Liliana Barrios", "Jorge Támara", "Patricia Mejía",
    "Andrés Lozano", "Sandra Polo", "Fabián Rincón", "Gloria Támaris", "Orlando Navas",
    "Diana Ferrer", "Mauricio Salgado", "Claudia Vélez", "Rafael Ochoa", "Irene Castaño",
    "Tomás Ibarra",
]
MATERIAS = {
    "laboratorio_computo": ["Programación I", "Estructuras de Datos", "Redes de Computadores",
                            "Bases de Datos", "Sistemas Operativos", "Programación Web"],
    "quimica": ["Química General", "Química Orgánica", "Química Analítica",
                "Laboratorio de Química Inorgánica"],
    "aula": ["Cálculo Diferencial", "Física Mecánica", "Álgebra Lineal", "Estadística",
             "Ética Profesional", "Economía", "Dibujo Técnico", "Comunicación Oral",
             "Ecuaciones Diferenciales", "Gestión de Proyectos"],
}
SLOTS = [(7, 9), (9, 11), (11, 13), (14, 16), (16, 18)]
CAMPUS = timezone(timedelta(hours=-5))
PERFILES = ["ocupado"] * 4 + ["pronto"] * 2 + ["tarde"] + ["libre"] * 3  # por posición % 10


def _h(*partes) -> int:
    """Número estable (no cambia entre corridas) a partir de textos."""
    return zlib.crc32("|".join(str(p) for p in partes).encode())


def utc(dia: date, hora: int) -> datetime:
    """Hora local de Colombia -> UTC "naive" (así se guardan los préstamos)."""
    return datetime(dia.year, dia.month, dia.day, hora).replace(tzinfo=CAMPUS).astimezone(
        timezone.utc).replace(tzinfo=None)


def indice_actual(hora: int) -> int:
    for i, (a, b) in enumerate(SLOTS):
        if a <= hora < b:
            return i
    return next((i for i, (a, _) in enumerate(SLOTS) if a > hora), len(SLOTS) - 1)


def familia(salon: Salon) -> str:
    if salon.nombre.startswith("A5-"):
        return "quimica"
    return "laboratorio_computo" if salon.tipo == "laboratorio_computo" else "aula"


def clases_de(salon: Salon, posicion: int, f0: int) -> dict[tuple[int, int], tuple[str, str]]:
    """{(día 1-5, ranura): (materia, docente)} de un salón, sin choques (una clase por ranura)."""
    perfil = PERFILES[posicion % 10]
    clases: dict[tuple[int, int], tuple[str, str]] = {}
    for dia in range(1, 6):
        for r in range(len(SLOTS)):
            if dia == 1:  # el lunes de la exposición se arma según el perfil del salón
                antes = r < f0 and _h(salon.nombre, dia, r) % 100 < 35
                if perfil == "ocupado":    # clase AHORA (y quizá otras)
                    pone = r == f0 or antes or (r > f0 and _h(salon.nombre, dia, r) % 100 < 35)
                elif perfil == "pronto":   # libre ahora, clase en la próxima franja
                    pone = r == f0 + 1 or antes
                elif perfil == "tarde":    # libre ahora y en la próxima, clase después
                    pone = r == f0 + 2 or antes
                else:                      # libre el resto del día
                    pone = antes
            else:
                pone = _h(salon.nombre, dia, r) % 100 < 40
            if pone and r < len(SLOTS):
                materias = MATERIAS[familia(salon)]
                materia = materias[_h(salon.nombre, "m", dia, r) % len(materias)]
                grupo = 1 + _h(salon.nombre, "g", dia, r) % 3
                docente = DOCENTES[_h(salon.nombre, "d", dia, r) % len(DOCENTES)]
                clases[(dia, r)] = (f"{materia} (Grupo {grupo})", docente)
    return clases


def libre(clases, dia: int, ranura: int) -> bool:
    return (dia, ranura) not in clases


def main_datos(db, hora: int, con_admin: bool = True) -> dict:
    """Con `con_admin` = False (la nube) NO se crea ninguna cuenta de Administrador con clave
    conocida: un administrador real se crea con scripts/crear_admin.py (clave por consola)."""
    cuentas = {}
    resumen = {"usuarios": 0, "horarios": 0, "solicitudes": 0, "reportes": 0, "mantenimientos": 0,
               "auditoria": 0}
    codigos = codigos_del_catalogo()
    salones = [s for s in db.query(Salon).order_by(Salon.nombre) if s.nombre in codigos]
    if not salones:
        raise SystemExit("No hay salones del catálogo. Corre primero scripts/cargar_catalogo_utb.py")
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)

    def anotar(accion, entidad, entidad_id, actor, detalle, cuando):
        reg = auditoria.registrar(db, accion, entidad, entidad_id, actor_id=actor.id, detalle=detalle)
        reg.ocurrio_en = cuando
        resumen["auditoria"] += 1

    def nombre_libre(nombre: str) -> str:
        """El nombre de usuario es único: si otra cuenta ya lo usa, se agrega " (demo)"."""
        ocupado = db.query(Usuario.id).filter(func.lower(Usuario.nombre) == nombre.lower()).first()
        return f"{nombre} (demo)" if ocupado else nombre

    # ── Cuentas ──────────────────────────────────────────────────────────────
    for nombre, email, rol, clave in CUENTAS:
        if rol == "administrador" and not con_admin:
            continue
        u = db.query(Usuario).filter(Usuario.email == email).first()
        if u is None:
            u = Usuario(nombre=nombre_libre(nombre), email=email, rol=rol,
                        rol_manual=rol != "usuario_utb",
                        password=hash_password(clave))
            db.add(u)
            resumen["usuarios"] += 1
        cuentas[email] = u
    estudiantes = []
    for i, nombre in enumerate(ESTUDIANTES, start=1):
        email = f"est{i:02d}.demo@utb.edu.co"
        u = db.query(Usuario).filter(Usuario.email == email).first()
        if u is None:
            u = Usuario(nombre=nombre_libre(nombre), email=email, rol="usuario_utb",
                        password=hash_password(CLAVE_ESTUDIANTES))
            db.add(u)
            resumen["usuarios"] += 1
        estudiantes.append(u)
    db.flush()
    operador = cuentas["auxiliar@utb.edu.co"]
    admin = cuentas.get("admin@utb.edu.co") or operador
    for i, u in enumerate(estudiantes):
        if not db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == "usuario.registro",
                                                  RegistroAuditoria.actor_id == u.id).first():
            anotar("usuario.registro", "usuario", u.id, u, {"rol": "usuario_utb"},
                   ahora - timedelta(days=14 - i))

    # ── Horarios (semana tipo; el lunes se arma para la hora de la exposición) ──
    f0 = indice_actual(hora)
    existentes = {}
    for h in db.query(Horario).filter(Horario.salon_id.in_([s.id for s in salones])):
        existentes.setdefault(h.salon_id, []).append(h)
    horarios = {}
    for pos, salon in enumerate(salones):
        clases = clases_de(salon, pos, f0)
        horarios[salon.nombre] = clases
        previos = existentes.get(salon.id, [])
        if any(h.semestre == SEMESTRE for h in previos):
            continue
        for (dia, r), (materia, docente) in sorted(clases.items()):
            ini, fin = time(SLOTS[r][0]), time(SLOTS[r][1])
            if any(h.dia_semana == dia and h.hora_inicio < fin and h.hora_fin > ini for h in previos):
                continue  # ya hay una clase real/anterior en esa franja
            db.add(Horario(salon_id=salon.id, dia_semana=dia, hora_inicio=ini, hora_fin=fin,
                           profesor=docente, materia=materia, semestre=SEMESTRE))
            resumen["horarios"] += 1
    if resumen["horarios"]:
        anotar("horario.carga_masiva", "horario", None, admin,
               {"creados": resumen["horarios"], "semestre": SEMESTRE}, ahora - timedelta(days=10))

    # ── Solicitudes de salón (ver `ocupa` para no chocar con clases) ─────────────
    por_perfil = {"ocupado": [], "pronto": [], "tarde": [], "libre": []}
    for pos, salon in enumerate(salones):
        por_perfil[PERFILES[pos % 10]].append(salon)
    libres = [s for s in por_perfil["libre"] if s.habilitado]
    ocupados = [s for s in por_perfil["ocupado"] if s.habilitado]
    deshabilitado = next((s for s in salones if s.nombre == SALON_DESHABILITADO[0]), None)

    def salon_libre(i, dia, ranura):
        for k in range(len(libres)):
            s = libres[(i + k) % len(libres)]
            if libre(horarios[s.nombre], dia, ranura):
                return s
        return libres[i % len(libres)]

    lunes = FECHA
    pasado = lambda n: FECHA - timedelta(days=n)  # noqa: E731
    P = []  # (salon, estudiante, día, hora_ini, duración, motivo, estado, respuesta)
    # 8 pendientes (la bandeja del auditor): una choca a propósito con una clase del lunes.
    P += [(ocupados[0], 0, lunes, 10, 2, "Ensayo de sustentación de proyecto", "pendiente", None)]
    P += [(salon_libre(1, 1, 3), 1, lunes, 14, 2, "Tutoría de Cálculo Diferencial", "pendiente", None)]
    P += [(salon_libre(2, 1, 4), 2, lunes, 16, 2, "Reunión de semillero de investigación", "pendiente", None)]
    P += [(salon_libre(3, 2, 3), 3, lunes + timedelta(days=1), 14, 2, "Taller de Estadística", "pendiente", None)]
    P += [(salon_libre(4, 3, 4), 4, lunes + timedelta(days=2), 16, 2, "Práctica de exposición oral", "pendiente", None)]
    P += [(salon_libre(5, 3, 3), 5, lunes + timedelta(days=2), 14, 2, "Estudio en grupo para parcial", "pendiente", None)]
    P += [(salon_libre(6, 4, 3), 6, lunes + timedelta(days=3), 14, 2, "Asesoría de trabajo de grado", "pendiente", None)]
    if deshabilitado is not None:  # caso límite: pendiente sobre un salón deshabilitado
        P += [(deshabilitado, 7, lunes + timedelta(days=2), 10, 2, "Sustentación de monografía", "pendiente", None)]
    # 5 aprobadas (una cubre la hora de la exposición en un salón libre)
    P += [(salon_libre(7, 1, f0), 8, lunes, hora, 2, "Repaso grupal de Física Mecánica", "aprobado", None)]
    P += [(salon_libre(8, 1, 4), 9, lunes, 16, 2, "Taller de Python para principiantes", "aprobado", None)]
    P += [(salon_libre(9, 2, 4), 0, lunes + timedelta(days=1), 16, 2, "Club de robótica", "aprobado", None)]
    P += [(salon_libre(10, 3, 3), 1, lunes + timedelta(days=2), 14, 2, "Charla de egresados", "aprobado", None)]
    P += [(salon_libre(11, 4, 4), 2, lunes + timedelta(days=3), 16, 2, "Ensayo de grupo de danza", "aprobado", None)]
    # 4 rechazadas (con la respuesta del auditor)
    P += [(ocupados[1], 3, pasado(3), 9, 2, "Estudio en grupo", "rechazado",
           "El salón tiene clase programada a esa hora.")]
    P += [(ocupados[2], 4, pasado(4), 9, 2, "Tutoría de Álgebra", "rechazado",
           "El salón ya estaba reservado para un parcial.")]
    P += [(salon_libre(12, 5, 3), 5, pasado(5), 14, 3, "Fiesta de fin de semestre", "rechazado",
           "Los salones no se prestan para eventos sociales.")]
    P += [(salon_libre(13, 3, 4), 6, pasado(7), 16, 1, "Reunión personal", "rechazado",
           "Indica el motivo académico de la solicitud.")]
    # 3 canceladas
    P += [(salon_libre(14, 2, 3), 7, lunes + timedelta(days=1), 14, 2, "Repaso de Cálculo", "cancelado", None)]
    P += [(salon_libre(15, 5, 3), 8, pasado(2), 14, 2, "Tutoría de Economía", "cancelado", None)]
    P += [(salon_libre(16, 4, 4), 9, pasado(6), 16, 2, "Ensayo de teatro", "cancelado", None)]
    # 4 finalizadas (ya usadas: dan números a las estadísticas)
    P += [(salon_libre(17, 5, 3), 0, pasado(3), 14, 2, "Taller de Python", "finalizado", None)]
    P += [(salon_libre(18, 4, 3), 1, pasado(4), 14, 2, "Estudio para parcial de Física", "finalizado", None)]
    P += [(salon_libre(19, 3, 4), 2, pasado(5), 16, 2, "Reunión de semillero", "finalizado", None)]
    P += [(salon_libre(20, 1, 3), 3, pasado(7), 14, 2, "Práctica de exposición", "finalizado", None)]

    for k, (salon, e, dia, h_ini, dur, motivo, estado, respuesta) in enumerate(P):
        est = estudiantes[e]
        ini, fin = utc(dia, h_ini), utc(dia, h_ini + dur)
        if db.query(PrestamoSalon).filter_by(salon_id=salon.id, usuario_id=est.id,
                                              fecha_inicio=ini).first():
            continue
        creada = ini - timedelta(days=2 + k % 3, hours=k % 5)
        p = PrestamoSalon(salon_id=salon.id, usuario_id=est.id, fecha_inicio=ini, fecha_fin=fin,
                          motivo=motivo, estado=estado, created_at=creada)
        if estado != "pendiente":
            p.respuesta = respuesta
            p.atendido_por_id = operador.id if estado != "cancelado" else None
            p.atendido_en = creada + timedelta(hours=3)
        db.add(p)
        db.flush()
        resumen["solicitudes"] += 1
        anotar("salon.solicitud.crear", "prestamo_salon", p.id, est,
               {"salon": salon.nombre, "motivo": motivo}, creada)
        if estado != "pendiente":
            actor = est if estado == "cancelado" else operador
            detalle = {"de": "pendiente", "a": estado, "salon": salon.nombre}
            if respuesta:
                detalle["respuesta"] = respuesta
            anotar("salon.solicitud.estado", "prestamo_salon", p.id, actor, detalle,
                   creada + timedelta(hours=3))

    # ── Reportes de salón y de equipos, y mantenimiento ─────────────────────────
    def recurso(codigo, clave):
        return db.query(Recurso).filter(Recurso.serial == f"DEMO-{clave}-{codigo}").first()

    def salon_de(codigo):
        return next((s for s in salones if s.nombre == codigo), None)

    R = [  # (salón, estudiante, tipo, texto, estado, clave de equipo o None, días atrás)
        ("A2-203", 0, "equipo", "El video beam no enciende: la lámpara parece quemada", "abierto", "VB", 2),
        ("A1-104", 1, "equipo", "El aire acondicionado no enfría", "abierto", "AC", 3),
        ("A1-404", 2, "equipo", "El computador 07 no enciende", "abierto", "PC", 1),
        ("A5-203", 3, "equipo", "La campana extractora no extrae bien y hace ruido", "abierto", "CAMPANA", 4),
        ("A1-406", 4, "equipo", "El computador 12 se reinicia solo y está muy lento", "abierto", "PC12", 2),
        ("A4-103", 5, "equipo", "Video beam con imagen borrosa", "abierto", "VB", 5),
        ("A1-201", 6, "limpieza", "Tablero sin borrar y basura en el piso", "abierto", None, 1),
        ("A5-201", 7, "seguridad", "Falta señalizar la ruta de evacuación", "abierto", None, 3),
        ("A2-301", 8, "limpieza", "Sillas sucias después de un evento", "resuelto", None, 9),
        ("A3-202", 9, "infraestructura", "Gotera en el techo", "resuelto", None, 8),
        ("A4-202", 0, "otro", "Falta un enchufe en la pared del fondo", "resuelto", None, 11),
    ]
    for codigo, e, tipo, texto, estado, clave, dias in R:
        salon = salon_de(codigo)
        if salon is None:
            continue
        est = estudiantes[e]
        if db.query(ReporteSalon).filter_by(salon_id=salon.id, usuario_id=est.id,
                                             descripcion=texto).first():
            continue
        rec = None
        if clave == "PC":
            rec = db.query(Recurso).filter(Recurso.serial == "DEMO-PC-A1-404-07").first()
        elif clave == "PC12":
            rec = db.query(Recurso).filter(Recurso.serial == "DEMO-PC-A1-406-12").first()
        elif clave:
            rec = recurso(codigo, clave)
        creado = ahora - timedelta(days=dias, hours=dias % 4)
        r = ReporteSalon(salon_id=salon.id, usuario_id=est.id, tipo=tipo, descripcion=texto,
                         estado=estado, created_at=creado, recurso_id=rec.id if rec else None,
                         resuelto_en=creado + timedelta(days=1, hours=2) if estado == "resuelto" else None)
        db.add(r)
        db.flush()
        resumen["reportes"] += 1
        anotar("salon.reporte.crear", "reporte_salon", r.id, est, {"salon": codigo, "tipo": tipo}, creado)
        if estado == "resuelto":
            anotar("salon.reporte.estado", "reporte_salon", r.id, operador,
                   {"de": "abierto", "a": "resuelto", "salon": codigo}, r.resuelto_en)
        if rec is not None and rec.estado == "dañado" and not db.query(Reporte).filter_by(
                recurso_id=rec.id, usuario_id=est.id).first():
            db.add(Reporte(recurso_id=rec.id, usuario_id=est.id, estado_reportado="dañado",
                           descripcion=texto, created_at=creado))
            anotar("recurso.reporte", "recurso", rec.id, est, {"estado_reportado": "dañado"}, creado)
        if rec is not None and rec.estado == "mantenimiento" and not db.query(
                MantenimientoRecurso).filter_by(recurso_id=rec.id).first():
            m = MantenimientoRecurso(recurso_id=rec.id, tipo="correctivo", estado="en_proceso",
                                     descripcion=texto, fecha_inicio=creado + timedelta(hours=5))
            db.add(m)
            db.flush()
            resumen["mantenimientos"] += 1
            anotar("mantenimiento.crear", "mantenimiento", m.id, operador,
                   {"recurso": rec.serial}, creado + timedelta(hours=5))
    # Habilitación del salón deshabilitado por el script de equipos.
    if deshabilitado is not None and not deshabilitado.habilitado and not db.query(
            RegistroAuditoria).filter_by(accion="salon.habilitacion", entidad_id=deshabilitado.id).first():
        anotar("salon.habilitacion", "salon", deshabilitado.id, operador,
               {"salon": deshabilitado.nombre, "habilitado": False,
                "motivo": SALON_DESHABILITADO[1]}, ahora - timedelta(hours=20))
    return resumen


def quitar(db) -> dict:
    ids = [u.id for u in db.query(Usuario).filter(Usuario.email.like("est__.demo@utb.edu.co"))]
    out = {}
    if ids:
        out["solicitudes"] = db.query(PrestamoSalon).filter(PrestamoSalon.usuario_id.in_(ids)).delete(
            synchronize_session=False)
        out["reportes_salon"] = db.query(ReporteSalon).filter(ReporteSalon.usuario_id.in_(ids)).delete(
            synchronize_session=False)
        out["reportes_equipo"] = db.query(Reporte).filter(Reporte.usuario_id.in_(ids)).delete(
            synchronize_session=False)
        out["auditoria"] = db.query(RegistroAuditoria).filter(RegistroAuditoria.actor_id.in_(ids)).delete(
            synchronize_session=False)
    out["horarios"] = db.query(Horario).filter(Horario.semestre == SEMESTRE).delete(synchronize_session=False)
    out["mantenimientos"] = db.query(MantenimientoRecurso).filter(
        MantenimientoRecurso.recurso_id.in_(
            db.query(Recurso.id).filter(Recurso.serial.like("DEMO-%")))).delete(synchronize_session=False)
    if ids:
        out["estudiantes"] = db.query(Usuario).filter(Usuario.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return out


def main() -> int:
    args = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    args.add_argument("--produccion", action="store_true",
                      help="permite --quitar en el servidor (la carga en la nube es la migración)")
    args.add_argument("--simular", action="store_true", help="solo cuenta, no guarda")
    args.add_argument("--hora", type=int, default=10, help="hora de la exposición (0-23), por defecto 10")
    args.add_argument("--quitar", action="store_true", help="retira lo de demostración")
    o = args.parse_args()
    if config.ENVIRONMENT == "production" and not (o.quitar and o.produccion):
        print("En producción la carga es la migración de demostración; aquí solo se permite "
              "--quitar --produccion.")
        return 1
    db = SessionLocal()
    try:
        if o.quitar:
            print("Quitado:", quitar(db))
            return 0
        resumen = main_datos(db, o.hora)
        if o.simular:
            db.rollback()
        else:
            db.commit()
        print(("Simulación: " if o.simular else "Listo: ") + json.dumps(resumen, ensure_ascii=False))
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())

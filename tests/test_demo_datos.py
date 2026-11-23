"""
Datos de demostración (scripts/cargar_equipos_demo.py y scripts/cargar_demo_actividad.py).

Reglas que importan: nunca crean salones, no duplican al repetirse, los horarios no chocan y los
equipos siguen las reglas del dueño (computadores en A1-402..407, laboratorios de química en A5).
"""
from sqlalchemy import func

from app.models import PrestamoSalon, Recurso, Salon
from app.models.salon_models import Horario, ReporteSalon
from scripts import cargar_demo_actividad as actividad
from scripts import cargar_equipos_demo as equipos


def _crear_catalogo(db):
    for codigo in sorted(equipos.codigos_del_catalogo()):
        laboratorio = codigo in equipos.PCS_POR_SALA
        db.add(Salon(nombre=codigo, ubicacion="Campus", edificio=codigo[:2], piso=int(codigo[3]),
                     capacidad=40, tipo="laboratorio_computo" if laboratorio else "aula"))
    db.commit()


def test_equipos_no_crean_salones_y_son_repetibles(db_session):
    _crear_catalogo(db_session)
    antes = db_session.query(Salon).count()
    primera = equipos.agregar(db_session, simular=False)
    assert primera["equipos_nuevos"] > 400
    assert db_session.query(Salon).count() == antes  # NUNCA crea salones
    segunda = equipos.agregar(db_session, simular=False)
    assert segunda["equipos_nuevos"] == 0
    assert db_session.query(Recurso).filter(~Recurso.serial.like("DEMO-%")).count() == 0


def test_reglas_de_equipamiento(db_session):
    _crear_catalogo(db_session)
    equipos.agregar(db_session, simular=False)

    def de(codigo, categoria=None):
        q = db_session.query(Recurso).join(Salon).filter(Salon.nombre == codigo)
        return q.filter(Recurso.categoria == categoria) if categoria else q

    assert de("A1-403", "computador").count() == 40           # sala de computadores
    assert de("A1-404", "computador").count() == 24
    assert de("A1-101", "computador").count() == 0            # un aula no lleva computadores
    assert any("Campana extractora" in r.descripcion for r in de("A5-203"))   # química
    assert any("Lavaojos" in r.descripcion for r in de("A5-201"))
    assert de("A2-301", "video_beam").count() == 1            # toda aula con video beam
    assert any(r.estado == "mantenimiento" for r in de("A5-203"))  # campana en mantenimiento
    deshabilitados = db_session.query(Salon).filter(Salon.habilitado.is_(False)).all()
    assert [s.nombre for s in deshabilitados] == ["A3-102"]


def test_actividad_sin_choques_repetible_y_con_variedad(db_session):
    _crear_catalogo(db_session)
    equipos.agregar(db_session, simular=False)
    salones_antes = db_session.query(Salon).count()
    r1 = actividad.main_datos(db_session, hora=10)
    db_session.commit()
    assert r1["horarios"] > 300 and r1["solicitudes"] == 24 and r1["reportes"] == 11
    assert db_session.query(Salon).count() == salones_antes
    r2 = actividad.main_datos(db_session, hora=10)
    db_session.commit()
    assert not any(r2[k] for k in ("usuarios", "horarios", "solicitudes", "reportes"))

    # Sin choques dentro de un salón.
    h = db_session.query(Horario).all()
    for a in h:
        for b in h:
            if a.id < b.id and a.salon_id == b.salon_id and a.dia_semana == b.dia_semana:
                assert not (a.hora_inicio < b.hora_fin and a.hora_fin > b.hora_inicio)
    # El lunes a las 10:00 hay salones con clase ahora, con clase pronto y libres.
    ahora = {x.salon_id for x in h if x.dia_semana == 1 and x.hora_inicio.hour <= 10 < x.hora_fin.hour}
    pronto = {x.salon_id for x in h if x.dia_semana == 1 and x.hora_inicio.hour == 11} - ahora
    assert ahora and pronto and len(ahora) < db_session.query(Salon).count()
    # Estados variados y un reporte vinculado a un equipo dañado.
    estados = dict(db_session.query(PrestamoSalon.estado, func.count()).group_by(PrestamoSalon.estado))
    assert {"pendiente", "aprobado", "rechazado", "cancelado", "finalizado"} <= set(estados)
    assert db_session.query(ReporteSalon).filter(ReporteSalon.recurso_id.isnot(None)).count() >= 3


def test_en_la_nube_no_se_crea_ningun_administrador_con_clave_conocida(db_session):
    from app.models import Usuario

    _crear_catalogo(db_session)
    equipos.agregar(db_session, simular=False)
    admins = db_session.query(Usuario).filter(Usuario.rol == "administrador").count()
    auditores = db_session.query(Usuario).filter(Usuario.rol == "auxiliar").count()
    actividad.main_datos(db_session, hora=10, con_admin=False)
    db_session.commit()
    assert db_session.query(Usuario).filter(Usuario.rol == "administrador").count() == admins
    assert db_session.query(Usuario).filter(Usuario.email == "admin@utb.edu.co").count() == admins
    assert db_session.query(Usuario).filter(Usuario.rol == "auxiliar").count() == auditores + 1


def test_un_nombre_ya_usado_no_rompe_la_carga(db_session):
    from app.models import Usuario

    _crear_catalogo(db_session)
    db_session.add(Usuario(nombre="Valeria Ospina", email="otra@utb.edu.co", password="x"))
    db_session.commit()
    equipos.agregar(db_session, simular=False)
    actividad.main_datos(db_session, hora=10, con_admin=False)
    db_session.commit()
    assert db_session.query(Usuario).filter(Usuario.email == "est01.demo@utb.edu.co").one().nombre \
        == "Valeria Ospina (demo)"


def test_quitar_deja_el_salon_como_estaba(db_session):
    _crear_catalogo(db_session)
    equipos.agregar(db_session, simular=False)
    actividad.main_datos(db_session, hora=10)
    db_session.commit()
    actividad.quitar(db_session)
    equipos.quitar(db_session)
    assert db_session.query(Salon).filter(Salon.habilitado.is_(False)).count() == 0
    assert db_session.query(PrestamoSalon).count() == 0


def test_no_duplica_computadores_que_ya_existen_en_la_sala(db_session):
    _crear_catalogo(db_session)
    sala = db_session.query(Salon).filter(Salon.nombre == "A1-402").one()
    for i in range(30):  # los que carga scripts/poblar_a1_piso4.py
        db_session.add(Recurso(categoria="computador", serial=f"A1-402-PC-{i:02d}", salon_id=sala.id))
    db_session.commit()
    equipos.agregar(db_session, simular=False)
    assert db_session.query(Recurso).filter(Recurso.salon_id == sala.id,
                                            Recurso.categoria == "computador").count() == 30

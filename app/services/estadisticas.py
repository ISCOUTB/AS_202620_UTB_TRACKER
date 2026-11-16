"""
Estadísticas del administrador (ADR-0018): solo datos reales de la base, cada bloque con UNA
consulta agrupada. No son las del auditor (operación del día, `/stats/resumen`).
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core import permisos
from app.models.auth_models import Usuario
from app.models.salon_models import PrestamoSalon, ReporteSalon, Salon


def _conteo(db: Session, columna, *filtros) -> dict[str, int]:
    filas = db.query(columna, func.count()).filter(*filtros).group_by(columna).all()
    return {str(clave): int(total) for clave, total in filas if clave is not None}


def resumen_admin(db: Session, dias: int = 30) -> dict:
    desde = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=dias)
    por_rol = _conteo(db, func.lower(Usuario.rol), Usuario.activo.is_(True))
    mas_pedidos = (
        db.query(Salon.nombre, func.count(PrestamoSalon.id))
        .join(PrestamoSalon, PrestamoSalon.salon_id == Salon.id)
        .filter(PrestamoSalon.created_at >= desde)
        .group_by(Salon.nombre)
        .order_by(func.count(PrestamoSalon.id).desc(), Salon.nombre)
        .limit(5)
        .all()
    )
    return {
        "dias": dias,
        "usuarios_activos_por_rol": [
            {"rol": r, "etiqueta": permisos.etiqueta(r), "total": por_rol.get(r, 0)}
            for r in permisos.ROLES_VALIDOS
        ],
        "usuarios_inactivos": db.query(func.count(Usuario.id))
        .filter(Usuario.activo.is_(False)).scalar() or 0,
        "solicitudes_por_estado": _conteo(
            db, PrestamoSalon.estado, PrestamoSalon.created_at >= desde
        ),
        "salones_mas_solicitados": [{"salon": n, "total": int(t)} for n, t in mas_pedidos],
        "salones_por_tipo": _conteo(db, Salon.tipo, Salon.activo.is_(True)),
        "reportes_salon_por_estado": _conteo(
            db, ReporteSalon.estado, ReporteSalon.created_at >= desde
        ),
        "reportes_salon_por_tipo": _conteo(
            db, ReporteSalon.tipo, ReporteSalon.created_at >= desde
        ),
    }


def resumen_operativo(db: Session) -> dict[str, int]:
    """Contadores del panel principal (GET /stats/resumen).

    Libres y ocupados salen de la OCUPACIÓN calculada (ADR-0022): "ocupado" ya no se guarda en
    la columna `estado`, así que contarlo ahí daría siempre 0.
    """
    from sqlalchemy import func

    from app.models.recurso_models import Prestamo, Recurso, Reporte
    from app.models.salon_models import PrestamoSalon
    from app.services import estado_salon

    pisos = estado_salon.resumen_por_piso(db)

    def contar(modelo, *condiciones) -> int:
        return db.query(func.count(modelo.id)).filter(*condiciones).scalar() or 0

    return {
        "salones_libres": sum(p["libres"] for p in pisos),
        "salones_ocupados": sum(p["ocupados"] for p in pisos),
        "equipos_disponibles": contar(Recurso, Recurso.activo.is_(True),
                                      Recurso.estado == "disponible"),
        "prestamos_activos": contar(Prestamo, Prestamo.estado == "activo"),
        "reportes_abiertos": contar(Reporte, Reporte.estado_reportado.in_(["dañado", "abierto"])),
        "solicitudes_salon_pendientes": contar(PrestamoSalon, PrestamoSalon.estado == "pendiente"),
    }

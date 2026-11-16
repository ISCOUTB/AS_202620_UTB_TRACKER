"""
Modelos SQLAlchemy del dominio de salones, horarios y préstamos de salón.

Entidades:
- Salon: aulas y laboratorios de la universidad.
- Horario: franjas horarias asignadas a profesores/materias por semestre.
- PrestamoSalon: solicitudes de préstamo de salón en horarios libres.
- PresenciaSalon: confirmación del auxiliar de que el profesor llegó a su clase.
- ReporteSalon: novedades del salón (limpieza, equipo, infraestructura…).
"""
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Time,
    UniqueConstraint,
    false,
    true,
)
from sqlalchemy.orm import relationship

from app.core.database import Base

FK_SALONES_ID = "salones.id"
FK_USUARIOS_ID = "usuarios.id"


class Salon(Base):
    __tablename__ = "salones"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, nullable=False)       # e.g. "A-301"
    ubicacion = Column(String, nullable=False)                  # e.g. "Edificio A, Piso 3"
    edificio = Column(String, nullable=True)
    piso = Column(Integer, nullable=True)
    capacidad = Column(Integer, nullable=False)
    # True = valor por defecto sin dato oficial (ADR-0021); pasa a False al editar la capacidad.
    capacidad_estimada = Column(Boolean, nullable=False, default=False, server_default=false())
    # aula | laboratorio_computo | sala_audiovisual | auditorio | sala_reuniones | otro (ADR-0017)
    tipo = Column(String(30), nullable=False, default="aula", server_default="aula")
    descripcion = Column(String(500), nullable=True)
    estado = Column(String, nullable=False, default="disponible")
    # valores guardados: disponible | mantenimiento | fuera_servicio (se mantienen en sincronía
    # con la habilitación, ADR-0022). "ocupado" ya no se guarda: la API lo CALCULA.
    activo = Column(Boolean, nullable=False, default=True)
    # HABILITACIÓN manual (ADR-0022): la decide el Administrador o el Auditor, con motivo.
    habilitado = Column(Boolean, nullable=False, default=True, server_default=true())
    motivo_deshabilitado = Column(String(20), nullable=True)  # mantenimiento|danio|evento|otro
    nota_deshabilitado = Column(String(300), nullable=True)
    reapertura_estimada = Column(Date, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relaciones
    horarios = relationship("Horario", back_populates="salon", cascade="all, delete-orphan")
    prestamos_salon = relationship("PrestamoSalon", back_populates="salon")
    recursos = relationship("Recurso", back_populates="salon")


class Horario(Base):
    __tablename__ = "horarios"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey(FK_SALONES_ID), nullable=False, index=True)
    dia_semana = Column(Integer, nullable=False)  # 1=Lunes … 7=Domingo
    hora_inicio = Column(Time, nullable=False)
    hora_fin = Column(Time, nullable=False)
    profesor = Column(String, nullable=True)
    materia = Column(String, nullable=True)
    semestre = Column(String, nullable=True)       # e.g. "2026-2"
    activo = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    salon = relationship("Salon", back_populates="horarios")


class PrestamoSalon(Base):
    __tablename__ = "prestamos_salon"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey(FK_SALONES_ID), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey(FK_USUARIOS_ID), nullable=False, index=True)
    fecha_inicio = Column(DateTime, nullable=False)
    fecha_fin = Column(DateTime, nullable=False)
    motivo = Column(String, nullable=True)
    estado = Column(String, nullable=False, default="pendiente", index=True)
    # valores válidos: pendiente | aprobado | rechazado | en_uso | finalizado | cancelado
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    # Respuesta del auditor (ADR-0018): motivo del rechazo o nota al aprobar.
    respuesta = Column(String(500), nullable=True)
    atendido_por_id = Column(Integer, ForeignKey(FK_USUARIOS_ID), nullable=True)
    atendido_en = Column(DateTime, nullable=True)

    salon = relationship("Salon", back_populates="prestamos_salon")
    usuario = relationship("Usuario", foreign_keys=[usuario_id])
    atendido_por = relationship("Usuario", foreign_keys=[atendido_por_id])

    @property
    def atendido_por_nombre(self):
        return self.atendido_por.nombre if self.atendido_por else None

    @property
    def salon_nombre(self):
        return self.salon.nombre if self.salon else None

    @property
    def usuario_nombre(self):
        return self.usuario.nombre if self.usuario else None

    @property
    def aviso_salon(self):
        """ADR-0022: señala al Auditor (y al estudiante) que el salón quedó deshabilitado."""
        if self.estado not in ("pendiente", "aprobado") or self.salon is None:
            return None
        from app.services.estado_salon import texto_deshabilitado  # evita import circular
        return texto_deshabilitado(self.salon)


class PresenciaSalon(Base):
    """Un registro por clase (horario) y fecha: ¿llegó el profesor?"""

    __tablename__ = "presencias_salon"
    __table_args__ = (
        UniqueConstraint("horario_id", "fecha", name="uq_presencia_horario_fecha"),
    )

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey(FK_SALONES_ID), nullable=False, index=True)
    horario_id = Column(Integer, ForeignKey("horarios.id"), nullable=False)
    fecha = Column(Date, nullable=False)
    profesor_presente = Column(Boolean, nullable=False)
    nota = Column(String, nullable=True)
    registrado_por = Column(Integer, ForeignKey(FK_USUARIOS_ID), nullable=False)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )


class ReporteSalon(Base):
    __tablename__ = "reportes_salon"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey(FK_SALONES_ID), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey(FK_USUARIOS_ID), nullable=False)
    tipo = Column(String, nullable=False)
    # valores válidos: limpieza | equipo | infraestructura | seguridad | otro
    descripcion = Column(String, nullable=False)
    estado = Column(String, nullable=False, default="abierto")
    # valores válidos: abierto | resuelto
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    resuelto_en = Column(DateTime, nullable=True)
    # Equipo al que se refiere un reporte de tipo "equipo" (vínculo opcional, ADR-0022).
    recurso_id = Column(Integer, ForeignKey("recursos.id"), nullable=True)

    salon = relationship("Salon")
    usuario = relationship("Usuario")

    # Datos legibles para el listado de reportes de todos los salones.
    @property
    def salon_nombre(self):
        return self.salon.nombre if self.salon else None

    @property
    def usuario_nombre(self):
        return self.usuario.nombre if self.usuario else None


class HistorialSalon(Base):
    """Cambios de estado de un salón y de sus equipos, para el detalle (ADR-0022).

    La bitácora de auditoría (ADR-0010) registra TODO con detalle técnico; esto es el resumen
    legible para el Auditor dentro del salón ("Deshabilitado: mantenimiento · Ana · 3 nov").
    """

    __tablename__ = "historial_salon"

    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey(FK_SALONES_ID), nullable=False, index=True)
    # deshabilitado | habilitado | equipo.estado | equipo.agregado | equipo.retirado | plantilla
    accion = Column(String(30), nullable=False)
    descripcion = Column(String(500), nullable=False)
    actor_id = Column(Integer, ForeignKey(FK_USUARIOS_ID), nullable=True)
    creado_en = Column(DateTime, nullable=False,
                       default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))

    actor = relationship("Usuario")

    @property
    def actor_nombre(self):
        return self.actor.nombre if self.actor else None

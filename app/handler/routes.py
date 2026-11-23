"""
Registro de TODAS las rutas de la API (equivalente a `routes.go` del proyecto de referencia).

`main.py` solo crea la app y llama a `registrar_rutas(app)`. El orden importa: las rutas fijas
van antes de las que llevan `/{id}`.
"""
from fastapi import FastAPI

from app.handler import auth
from app.handler import auditoria, health, resources, loans
from app.handler import salones, salones_admin, horarios, prestamos_salon, maintenance, stats
from app.handler import asignaciones, catalogo, estado_salon, usuarios


def registrar_rutas(app: FastAPI) -> None:
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(resources.router, prefix="/recursos", tags=["recursos"])
    # Legado (ADR-0010/0023): el préstamo de equipos ya no está en la app. Se conserva solo como
    # evidencia de los experimentos de idempotencia y bloqueo (S11) y figura como obsoleto.
    app.include_router(loans.router, prefix="/prestamos", tags=["prestamos (legado)"], deprecated=True)
    # Va antes que `salones`: /salones/ocupacion no debe caer en /salones/{salon_id}.
    PREFIX_SALONES = "/salones"
    app.include_router(catalogo.router, prefix="/salones/catalogo", tags=["salones-catalogo"])
    app.include_router(estado_salon.router, prefix=PREFIX_SALONES, tags=["salones-habilitacion"])
    app.include_router(salones_admin.router, prefix=PREFIX_SALONES, tags=["salones-admin"])
    app.include_router(salones.router, prefix=PREFIX_SALONES, tags=["salones"])
    app.include_router(horarios.router, prefix="/horarios", tags=["horarios"])
    app.include_router(prestamos_salon.router, prefix="/prestamos-salon", tags=["prestamos-salon"])
    app.include_router(maintenance.router, prefix="/mantenimientos", tags=["mantenimientos"])
    app.include_router(stats.router)
    app.include_router(auditoria.router, prefix="/auditoria", tags=["auditoria"])
    # Rutas fijas (/usuarios/asignaciones) antes de las de /usuarios/{id}.
    app.include_router(asignaciones.router, prefix="/usuarios/asignaciones", tags=["usuarios"])
    app.include_router(usuarios.router, prefix="/usuarios", tags=["usuarios"])

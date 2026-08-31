from fastapi import FastAPI

from app.database import Base, engine
from app.routers import health, users, resources, loans

# Crea las tablas si no existen. Suficiente para este corte vertical;
# Alembic (migraciones versionadas) queda pendiente para la siguiente
# entrega, ver docs/adr/ si se documenta como decision aparte.
Base.metadata.create_all(bind=engine)

app = FastAPI(title="UTB Tracker")

app.include_router(health.router)
app.include_router(users.router, prefix="/usuarios", tags=["usuarios"])
app.include_router(resources.router, prefix="/recursos", tags=["recursos"])
app.include_router(loans.router, prefix="/prestamos", tags=["prestamos"])


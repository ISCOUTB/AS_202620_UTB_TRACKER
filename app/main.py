from fastapi import FastAPI

from app.routers import auth
from app.core.database import Base, engine
from app.routers import health, resources, loans

Base.metadata.create_all(bind=engine)

app = FastAPI(title="UTB Tracker")

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(resources.router, prefix="/recursos", tags=["recursos"])
app.include_router(loans.router, prefix="/prestamos", tags=["prestamos"])


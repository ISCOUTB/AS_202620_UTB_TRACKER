from fastapi import FastAPI
from app.routers import users, loans, resources

app = FastAPI(
    title="UTB Tracker API",
    description="API para el sistema de control de inventario y préstamos de la UTB",
    version="1.0.0"
)

# Registrar módulos de dominio independientes (Monolito Modular)
app.include_router(users.router, prefix="/usuarios", tags=["Usuarios"])
app.include_router(loans.router, prefix="/prestamos", tags=["Préstamos"])
app.include_router(resources.router, prefix="/recursos", tags=["Recursos"])

# Endpoint de salud para verificación automatizada (A-02 / QS-01)
@app.get("/salud/")
def health_check():
    return {"status": "ok", "proyecto": "UTB Tracker"}

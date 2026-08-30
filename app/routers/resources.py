from fastapi import APIRouter

router = APIRouter()

# Esqueleto vacío para el módulo de catálogo y gestión de recursos (A-05 / RESOURCES)
@router.get("/")
def get_resources():
    return {"message": "Resources module active"}

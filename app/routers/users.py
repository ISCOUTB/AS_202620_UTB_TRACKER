from fastapi import APIRouter

router = APIRouter()

# Esqueleto vacío para el módulo de usuarios (A-01 / USERS)
@router.get("/")
def get_users():
    return {"message": "Users module active"}

from fastapi import APIRouter

router = APIRouter()

# Esqueleto vacío para el módulo de préstamos y devoluciones (A-02 / LOANS)
@router.get("/")
def get_loans():
    return {"message": "Loans module active"}

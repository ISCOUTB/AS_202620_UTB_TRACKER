from fastapi import APIRouter

router = APIRouter()


@router.get("/salud")
def health_check():
    """
    Endpoint minimo para confirmar que el esqueleto arranca correctamente.
    No es logica de negocio: es fontaneria para la siguiente entrega.
    """
    return {"status": "ok", "proyecto": "UTB Tracker"}

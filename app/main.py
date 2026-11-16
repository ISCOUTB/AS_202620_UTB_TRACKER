from contextvars import ContextVar
import logging
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import CORS_ORIGINS
from app.routers import auth
from app.core.database import Base  # noqa: F401  — Base expuesto para que conftest pueda usarlo
from app.routers import auditoria, health, resources, loans
from app.routers import salones, salones_admin, horarios, prestamos_salon, maintenance, stats
from app.routers import asignaciones, catalogo, usuarios

# Importar todos los modelos para que Base.metadata los registre
from app.models import auth_models, auditoria_models, recurso_models, salon_models  # noqa: F401
from app.models import seguridad_models  # noqa: F401
from app.messaging import models as messaging_models  # noqa: F401

request_id_ctx: ContextVar[str] = ContextVar("request_id_ctx", default="system")

# ---------------------------------------------------------------------------
# Logging estructurado (S8 — req. 8.5)
# Formato JSON-like para que sea parseable por agregadores de logs (Loki, etc.)
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","msg":"%(message)s"}',
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("utb_tracker")


app = FastAPI(
    title="UTB Tracker",
    description="API REST para gestión de salones, préstamos de equipos electrónicos y horarios — UTB.",
    version="1.0.0",
)

# ---------------------------------------------------------------------------
# CORS Middleware — permite peticiones desde el frontend Flutter
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Errores de validación (422) en español. Se conserva la forma de FastAPI
# ({"detail": [{"loc", "msg", "type"}]}) para no romper a los clientes.
# ---------------------------------------------------------------------------
_MENSAJES_422 = {
    "missing": "Este campo es obligatorio",
    "string_too_short": "Debe tener al menos {min_length} caracteres",
    "string_too_long": "Debe tener como máximo {max_length} caracteres",
    "int_parsing": "Debe ser un número entero",
    "enum": "Valor no permitido. Opciones: {expected}",
    "literal_error": "Valor no permitido. Opciones: {expected}",
    "json_invalid": "El cuerpo de la petición no es un JSON válido",
}


def _mensaje_422(error: dict) -> str:
    tipo = error.get("type", "")
    if tipo == "value_error":
        # Mensajes propios (política de contraseña, correo): sin el prefijo "Value error, ".
        return str(error.get("msg", "")).removeprefix("Value error, ")
    plantilla = _MENSAJES_422.get(tipo)
    if plantilla:
        try:
            return plantilla.format(**(error.get("ctx") or {}))
        except (KeyError, IndexError):
            return plantilla
    return str(error.get("msg", "Dato inválido"))


@app.exception_handler(RequestValidationError)
async def validacion_en_espanol(request: Request, exc: RequestValidationError):
    errores = [
        {"loc": e.get("loc"), "msg": _mensaje_422(e), "type": e.get("type")}
        for e in exc.errors()
    ]
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": errores}))


@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    """
    Middleware de logging estructurado (S8).
    Registra método, ruta, request_id, código de respuesta y latencia en ms
    en cada petición, permitiendo correlacionar logs por request_id.
    """
    request_id = str(uuid.uuid4())[:8]
    token = request_id_ctx.set(request_id)
    start = time.perf_counter()

    logger.info(
        'request_id=%s method=%s path=%s',
        request_id, request.method, request.url.path,
    )

    try:
        response = await call_next(request)
        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
        logger.info(
            'request_id=%s status=%d latency_ms=%s',
            request_id, response.status_code, elapsed_ms,
        )
        response.headers["X-Request-ID"] = request_id
        return response
    finally:
        request_id_ctx.reset(token)


# ---------------------------------------------------------------------------
# Registro de routers
# ---------------------------------------------------------------------------
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(resources.router, prefix="/recursos", tags=["recursos"])
app.include_router(loans.router, prefix="/prestamos", tags=["prestamos"])
# Va antes que `salones`: /salones/ocupacion no debe caer en /salones/{salon_id}.
app.include_router(catalogo.router, prefix="/salones/catalogo", tags=["salones-catalogo"])
app.include_router(salones_admin.router, prefix="/salones", tags=["salones-admin"])
app.include_router(salones.router, prefix="/salones", tags=["salones"])
app.include_router(horarios.router, prefix="/horarios", tags=["horarios"])
app.include_router(prestamos_salon.router, prefix="/prestamos-salon", tags=["prestamos-salon"])
app.include_router(maintenance.router, prefix="/mantenimientos", tags=["mantenimientos"])
app.include_router(stats.router)
app.include_router(auditoria.router, prefix="/auditoria", tags=["auditoria"])
# Rutas fijas (/usuarios/asignaciones) antes de las de /usuarios/{id}.
app.include_router(asignaciones.router, prefix="/usuarios/asignaciones", tags=["usuarios"])
app.include_router(usuarios.router, prefix="/usuarios", tags=["usuarios"])

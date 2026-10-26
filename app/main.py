from contextvars import ContextVar
import logging
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import CORS_ORIGINS
from app.routers import auth
from app.core.database import Base  # noqa: F401  — Base expuesto para que conftest pueda usarlo
from app.routers import health, resources, loans
from app.routers import salones, salones_admin, horarios, prestamos_salon

# Importar todos los modelos para que Base.metadata los registre
from app.models import auth_models, recurso_models, salon_models  # noqa: F401
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
app.include_router(salones_admin.router, prefix="/salones", tags=["salones-admin"])
app.include_router(salones.router, prefix="/salones", tags=["salones"])
app.include_router(horarios.router, prefix="/horarios", tags=["horarios"])
app.include_router(prestamos_salon.router, prefix="/prestamos-salon", tags=["prestamos-salon"])

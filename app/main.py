import logging
import time
import uuid

from fastapi import FastAPI, Request

from app.routers import auth
from app.core.database import Base, engine
from app.routers import health, resources, loans

# ---------------------------------------------------------------------------
# Logging estructurado (S8 — req. 8.5)
# Formato JSON-like para que sea parseable por agregadores de logs (Loki, etc.)
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","msg":%(message)s}',
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger("utb_tracker")

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="UTB Tracker",
    description="API REST para gestión de préstamos de equipos electrónicos — UTB.",
    version="0.8.0",
)


@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    """
    Middleware de logging estructurado (S8).
    Registra método, ruta, request_id, código de respuesta y latencia en ms
    en cada petición, permitiendo correlacionar logs por request_id.
    """
    request_id = str(uuid.uuid4())[:8]
    start = time.perf_counter()

    logger.info(
        '"request_id":"%s","method":"%s","path":"%s"',
        request_id, request.method, request.url.path,
    )

    response = await call_next(request)

    elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
    logger.info(
        '"request_id":"%s","status":%d,"latency_ms":%s',
        request_id, response.status_code, elapsed_ms,
    )
    response.headers["X-Request-ID"] = request_id
    return response


app.include_router(health.router)
app.include_router(auth.router)
app.include_router(resources.router, prefix="/recursos", tags=["recursos"])
app.include_router(loans.router, prefix="/prestamos", tags=["prestamos"])

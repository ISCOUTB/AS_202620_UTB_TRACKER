# Imagen del backend de UTB Tracker (API FastAPI y worker de mensajería comparten imagen).
# Misma versión de Python que el CI (.github/workflows/ci.yml).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Dependencias primero (capa cacheable). requirements.txt trae hashes: se instalan verificados.
COPY requirements.txt .
RUN pip install --require-hashes --only-binary :all: -r requirements.txt

COPY alembic.ini .
COPY alembic ./alembic
COPY app ./app
COPY scripts ./scripts

# Usuario sin privilegios: el contenedor no corre como root.
RUN useradd --create-home --uid 1000 utb
USER utb

EXPOSE 8000

# Prepara el esquema (base nueva: crea tablas y marca la versión; base existente: migra) y
# arranca la API. El worker usa esta misma imagen con otro comando (ver docker-compose.yml).
# Antes era `alembic upgrade head`, que falla con una base vacía (ADR-0014).
CMD ["sh", "-c", "python scripts/preparar_bd.py && python scripts/poblar_a1_piso4.py && uvicorn app.main:app --host 0.0.0.0 --port 8000"]

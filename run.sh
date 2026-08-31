#!/usr/bin/env bash
# Un solo comando para levantar UTB Tracker desde cero: crea el entorno
# virtual si no existe, instala dependencias, corre las pruebas y
# arranca el servidor de desarrollo.
set -e

if [ ! -d "venv" ]; then
    echo "==> Creando entorno virtual..."
    python3 -m venv venv
fi

echo "==> Instalando dependencias..."
./venv/bin/pip install -q -r requirements.txt

echo "==> Corriendo pruebas..."
./venv/bin/python -m pytest tests/ -v

echo "==> Levantando servidor en http://127.0.0.1:8000 (docs en /docs, Ctrl+C para detener)"
./venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

#!/bin/bash

# Terminar en caso de error
set -e

echo "=== Levantando Entorno de UTB Tracker ==="

# 1. Crear entorno virtual si no existe
if [ ! -d "venv" ]; then
    echo "Creando entorno virtual (venv)..."
    python -m venv venv
fi

# 2. Activar entorno virtual de forma multiplataforma
echo "Activando entorno virtual..."
if [ -d "venv/Scripts" ]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# 3. Instalar/Actualizar dependencias
echo "Instalando dependencias desde requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

# 4. Ejecutar pruebas automatizadas con pytest
echo "Ejecutando pruebas unitarias..."
python -m pytest app/tests/

# 5. Iniciar servidor de desarrollo con Uvicorn
echo "Iniciando servidor de desarrollo en http://127.0.0.1:8000..."
python -m uvicorn app.main:app --reload --port 8000

#!/usr/bin/env bash
# Un solo comando para levantar Tractar desde cero: crea el entorno
# virtual si no existe, instala dependencias, migra y corre las pruebas
# antes de arrancar el servidor de desarrollo.
set -e

if [ ! -d "venv" ]; then
    echo "==> Creando entorno virtual..."
    python3 -m venv venv
fi

echo "==> Instalando dependencias..."
./venv/bin/pip install -q -r requirements.txt

echo "==> Aplicando migraciones..."
./venv/bin/python manage.py migrate

echo "==> Corriendo pruebas..."
./venv/bin/python manage.py test

echo "==> Levantando servidor en http://127.0.0.1:8000 (Ctrl+C para detener)"
./venv/bin/python manage.py runserver

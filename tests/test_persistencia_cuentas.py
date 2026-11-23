"""
Fase 0 (ADR-0014): "las cuentas nunca se guardan".

Prueba de extremo a extremo con PROCESOS reales: prepara una base SQLite nueva con
scripts/preparar_bd.py (lo mismo que hace iniciar.ps1), levanta la API con uvicorn, registra
una cuenta, APAGA el proceso, lo vuelve a levantar y entra otra vez con la misma cuenta.
"""
import os
import socket
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

import httpx
import pytest

RAIZ = Path(__file__).resolve().parent.parent


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _levantar(entorno: dict, puerto: int) -> subprocess.Popen:
    proc = subprocess.Popen(  # noqa: S603 - prueba: lanza la API del propio repo
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1",
         "--port", str(puerto)],
        cwd=RAIZ, env=entorno, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    for _ in range(80):
        try:
            if httpx.get(f"http://127.0.0.1:{puerto}/salud", timeout=1).status_code == 200:
                return proc
        except httpx.HTTPError:
            time.sleep(0.25)
    proc.kill()
    pytest.fail("La API no arrancó")


def _apagar(proc: subprocess.Popen) -> None:
    proc.terminate()
    try:
        proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        proc.kill()


def test_cuenta_registrada_sobrevive_al_reinicio_de_la_api(tmp_path):
    db = tmp_path / "persistencia.db"
    entorno = {
        **os.environ,
        "DATABASE_URL": f"sqlite:///{db.as_posix()}",
        "ENVIRONMENT": "development",
        "CORREOS_DIR": str(tmp_path / "correos"),
    }
    preparar = subprocess.run(  # noqa: S603 - prueba: script del propio repo
        [sys.executable, "scripts/preparar_bd.py"], cwd=RAIZ, env=entorno,
        capture_output=True, text=True,
    )
    assert preparar.returncode == 0, preparar.stdout + preparar.stderr

    puerto = _puerto_libre()
    url = f"http://127.0.0.1:{puerto}"
    api = _levantar(entorno, puerto)
    try:
        r = httpx.post(f"{url}/auth/register", json={
            "nombre": "Cuenta Persistente", "email": " Persiste@UTB.edu.co",
            "password": "ClaveSegura1",
        })
        assert r.status_code == 201, r.text
    finally:
        _apagar(api)

    api = _levantar(entorno, puerto)
    try:
        for ident in ("persiste@utb.edu.co", "Cuenta Persistente"):
            r = httpx.post(f"{url}/auth/login", json={"nombre": ident, "password": "ClaveSegura1"})
            assert r.status_code == 200, (ident, r.text)
    finally:
        _apagar(api)

    filas = sqlite3.connect(db).execute(
        "SELECT nombre, email FROM usuarios WHERE nombre = 'Cuenta Persistente'"
    ).fetchall()
    assert filas == [("Cuenta Persistente", "persiste@utb.edu.co")]

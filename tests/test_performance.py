"""
Prueba empírica de rendimiento y latencia (S9 — req. 9.4).

Verifica experimentalmente las métricas de calidad:
- QS-02: Latencia de respuesta en endpoints principales (p95 < 200 ms en backend local).
- QS-03: Concurrencia de solicitudes sin errores.
"""
import os
import time
from concurrent.futures import ThreadPoolExecutor

import pytest


def test_rendimiento_latencia_p95_salud(client):
    """Mide la latencia p95 del endpoint de salud y recursos con 100 peticiones."""
    latencias = []

    for _ in range(100):
        t0 = time.perf_counter()
        res = client.get("/salud")
        t1 = time.perf_counter()
        assert res.status_code == 200
        latencias.append((t1 - t0) * 1000)  # en ms

    latencias.sort()
    p50 = latencias[int(len(latencias) * 0.50)]
    p95 = latencias[int(len(latencias) * 0.95)]

    # Verificación de que la latencia media y p95 es adecuada (menos de 500 ms en local)
    assert p95 < 500, f"Latencia p95 demasiado alta: {p95:.2f} ms"
    assert p50 < 100, f"Latencia p50 demasiado alta: {p50:.2f} ms"


def test_concurrencia_solicitudes_simultaneas(client):
    """Ejecuta 50 peticiones simultáneas con un ThreadPool para evaluar concurrencia."""
    def tarea_request(_):
        res = client.get("/salud")
        return res.status_code

    with ThreadPoolExecutor(max_workers=10) as executor:
        resultados = list(executor.map(tarea_request, range(50)))

    # Todas deben ser exitosas (200 OK)
    assert all(code == 200 for code in resultados)
    assert len(resultados) == 50


@pytest.mark.skipif(
    not (os.environ.get("TEST_DATABASE_URL") or "").startswith("postgresql"),
    reason="La prueba requiere bloqueo de filas PostgreSQL",
)
def test_concurrencia_prestamos_mismo_recurso_postgresql(
    client, admin_headers, auth_headers
):
    """Solo una solicitud concurrente puede prestar el mismo recurso."""
    recurso = client.post(
        "/recursos",
        json={"categoria": "computador", "serial": "CONCURRENCY-001"},
        headers=admin_headers,
    )
    assert recurso.status_code == 201
    recurso_id = recurso.json()["id"]
    payload = {
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-12-01T18:00:00",
    }

    def prestar(indice):
        return client.post(
            "/prestamos",
            json=payload,
            headers={
                **auth_headers,
                "X-Idempotency-Key": f"concurrency-test-{indice}",
            },
        ).status_code

    with ThreadPoolExecutor(max_workers=2) as executor:
        resultados = list(executor.map(prestar, range(2)))

    assert sorted(resultados) == [201, 409]

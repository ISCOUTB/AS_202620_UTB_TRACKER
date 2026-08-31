"""
Estas pruebas cubren la regla de negocio central del sistema
(documento de idea, seccion 6) y corresponden al escenario QS-06 de
arc42 seccion 10: un recurso solo puede prestarse si esta disponible,
y su estado cambia a "prestado" cuando el prestamo se crea.
"""


def _crear_recurso(client, serial="VB-2026-0001"):
    response = client.post("/recursos", json={
        "categoria": "video_beam",
        "salon_id": "A1-304",
        "serial": serial,
    })
    return response.json()["id"]


def test_prestamo_exitoso_cambia_estado_del_recurso(client):
    recurso_id = _crear_recurso(client)

    response = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    })
    assert response.status_code == 201

    recurso = client.get(f"/recursos/{recurso_id}").json()
    assert recurso["estado"] == "prestado"


def test_no_permite_prestar_recurso_no_disponible(client):
    recurso_id = _crear_recurso(client)

    # primer prestamo: exitoso, el recurso queda "prestado"
    client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    })

    # segundo intento sobre el mismo recurso: debe rechazarse
    response = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 2,
        "fecha_devolucion_esperada": "2026-09-16T18:00:00",
    })
    assert response.status_code == 409
    assert "no esta disponible" in response.json()["detail"]


def test_prestamo_de_recurso_inexistente_da_404(client):
    response = client.post("/prestamos", json={
        "recurso_id": 9999,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    })
    assert response.status_code == 404

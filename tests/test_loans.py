"""
Estas pruebas cubren la regla de negocio central del sistema
(documento de idea, seccion 6) y corresponden al escenario QS-06 de
arc42 seccion 10: un recurso solo puede prestarse si esta disponible,
y su estado cambia a "prestado" cuando el prestamo se crea.

Mejoras:
- Todos los endpoints protegidos con JWT.
- Test de devolución de préstamo (devolver).
"""


def _crear_recurso(client, admin_headers, serial="VB-2026-0001"):
    response = client.post("/recursos", json={
        "categoria": "video_beam",
        "serial": serial,
    }, headers=admin_headers)
    return response.json()["id"]


def test_prestamo_exitoso_cambia_estado_del_recurso(client, admin_headers, auth_headers):
    recurso_id = _crear_recurso(client, admin_headers)

    response = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    }, headers=auth_headers)
    assert response.status_code == 201

    recurso = client.get(f"/recursos/{recurso_id}", headers=auth_headers).json()
    assert recurso["estado"] == "prestado"


def test_no_permite_prestar_recurso_no_disponible(client, admin_headers, auth_headers):
    recurso_id = _crear_recurso(client, admin_headers)

    # primer prestamo: exitoso, el recurso queda "prestado"
    client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    }, headers=auth_headers)

    # segundo intento sobre el mismo recurso: debe rechazarse
    response = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 2,
        "fecha_devolucion_esperada": "2026-09-16T18:00:00",
    }, headers=auth_headers)
    assert response.status_code == 409
    assert "no esta disponible" in response.json()["detail"]


def test_prestamo_de_recurso_inexistente_da_404(client, auth_headers):
    response = client.post("/prestamos", json={
        "recurso_id": 9999,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    }, headers=auth_headers)
    assert response.status_code == 404


def test_devolver_prestamo(client, admin_headers, auth_headers):
    """Devolver un préstamo restaura el recurso a 'disponible'."""
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-DEV-001")

    # Crear préstamo
    res = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    }, headers=auth_headers)
    prestamo_id = res.json()["id"]

    # Devolver
    response = client.patch(
        f"/prestamos/{prestamo_id}/devolver",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["estado"] == "devuelto"
    assert data["fecha_devolucion_real"] is not None

    # Recurso debe estar disponible de nuevo
    recurso = client.get(f"/recursos/{recurso_id}", headers=auth_headers).json()
    assert recurso["estado"] == "disponible"


def test_devolver_prestamo_ya_devuelto_rechaza(client, admin_headers, auth_headers):
    """No se puede devolver un préstamo que ya fue devuelto."""
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-DEV-002")
    res = client.post("/prestamos", json={
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-09-15T18:00:00",
    }, headers=auth_headers)
    prestamo_id = res.json()["id"]

    # Primera devolución OK
    client.patch(f"/prestamos/{prestamo_id}/devolver", headers=auth_headers)

    # Segunda devolución debe fallar
    response = client.patch(f"/prestamos/{prestamo_id}/devolver", headers=auth_headers)
    assert response.status_code == 409

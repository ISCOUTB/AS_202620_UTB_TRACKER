"""
Pruebas del módulo de salones.

Cubre:
- CRUD completo de salones (crear, listar, obtener, actualizar, eliminar).
- Control de acceso por roles.
- Consulta de disponibilidad.
"""


def test_crear_salon(client, admin_headers):
    response = client.post("/salones", json={
        "nombre": "A-301",
        "ubicacion": "Edificio A, Piso 3",
        "edificio": "A",
        "piso": 3,
        "capacidad": 40,
    }, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["nombre"] == "A-301"
    assert data["capacidad"] == 40
    assert data["estado"] == "disponible"


def test_crear_salon_duplicado_rechazado(client, admin_headers):
    payload = {
        "nombre": "Lab-Sis-1",
        "ubicacion": "Edificio B, Piso 1",
        "capacidad": 30,
    }
    client.post("/salones", json=payload, headers=admin_headers)
    response = client.post("/salones", json=payload, headers=admin_headers)
    assert response.status_code == 409


def test_crear_salon_sin_admin_rechaza(client, auth_headers):
    response = client.post("/salones", json={
        "nombre": "Salon-Restringido",
        "ubicacion": "Test",
        "capacidad": 20,
    }, headers=auth_headers)
    assert response.status_code == 403


def test_listar_salones(client, admin_headers, auth_headers):
    client.post("/salones", json={
        "nombre": "Salon-List-1",
        "ubicacion": "Edificio C",
        "capacidad": 25,
    }, headers=admin_headers)
    client.post("/salones", json={
        "nombre": "Salon-List-2",
        "ubicacion": "Edificio C",
        "capacidad": 30,
    }, headers=admin_headers)

    response = client.get("/salones", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == 2


def test_obtener_salon_por_id(client, admin_headers, auth_headers):
    res = client.post("/salones", json={
        "nombre": "Salon-Get-1",
        "ubicacion": "Edificio D",
        "capacidad": 35,
    }, headers=admin_headers)
    salon_id = res.json()["id"]

    response = client.get(f"/salones/{salon_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["nombre"] == "Salon-Get-1"


def test_actualizar_salon(client, admin_headers):
    res = client.post("/salones", json={
        "nombre": "Salon-Upd-1",
        "ubicacion": "Edificio E",
        "capacidad": 20,
    }, headers=admin_headers)
    salon_id = res.json()["id"]

    response = client.put(f"/salones/{salon_id}", json={
        "capacidad": 50,
        "estado": "mantenimiento",
    }, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["capacidad"] == 50
    assert response.json()["estado"] == "mantenimiento"


def test_eliminar_salon(client, admin_headers, auth_headers):
    res = client.post("/salones", json={
        "nombre": "Salon-Del-1",
        "ubicacion": "Edificio F",
        "capacidad": 15,
    }, headers=admin_headers)
    salon_id = res.json()["id"]

    res_del = client.delete(f"/salones/{salon_id}", headers=admin_headers)
    assert res_del.status_code == 200

    # Ya no debe encontrarse
    res_get = client.get(f"/salones/{salon_id}", headers=auth_headers)
    assert res_get.status_code == 404


def test_disponibilidad_salon_sin_horarios(client, admin_headers, auth_headers):
    res = client.post("/salones", json={
        "nombre": "Salon-Disp-1",
        "ubicacion": "Edificio G",
        "capacidad": 30,
    }, headers=admin_headers)
    salon_id = res.json()["id"]

    response = client.get(
        f"/salones/{salon_id}/disponibilidad?dia_semana=1",
        headers=auth_headers,
    )
    assert response.status_code == 200
    franjas = response.json()
    # Sin horarios, toda la franja del día (6:00-22:00) debe estar disponible
    assert len(franjas) == 1
    assert franjas[0]["hora_inicio"] == "06:00:00"
    assert franjas[0]["hora_fin"] == "22:00:00"

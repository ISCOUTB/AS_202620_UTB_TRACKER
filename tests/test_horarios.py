"""
Pruebas del módulo de horarios.

Cubre:
- CRUD de horarios académicos.
- Detección de conflictos temporales.
- Carga masiva (bulk).
- Filtros por salón, día y semestre.
"""


def _crear_salon(client, admin_headers, nombre="Salon-H-1"):
    res = client.post("/salones", json={
        "nombre": nombre,
        "ubicacion": "Edificio Test",
        "capacidad": 30,
    }, headers=admin_headers)
    return res.json()["id"]


def test_crear_horario(client, admin_headers):
    salon_id = _crear_salon(client, admin_headers)

    response = client.post("/horarios", json={
        "salon_id": salon_id,
        "dia_semana": 1,
        "hora_inicio": "08:00:00",
        "hora_fin": "10:00:00",
        "profesor": "Dr. García",
        "materia": "Ingeniería de Software",
        "semestre": "2026-2",
    }, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["profesor"] == "Dr. García"
    assert data["materia"] == "Ingeniería de Software"


def test_conflicto_horario_rechazado(client, admin_headers):
    salon_id = _crear_salon(client, admin_headers, "Salon-Conf-1")

    # Crear primer horario: 8:00-10:00
    client.post("/horarios", json={
        "salon_id": salon_id,
        "dia_semana": 1,
        "hora_inicio": "08:00:00",
        "hora_fin": "10:00:00",
        "materia": "Clase 1",
    }, headers=admin_headers)

    # Intentar crear horario que se cruza: 9:00-11:00
    response = client.post("/horarios", json={
        "salon_id": salon_id,
        "dia_semana": 1,
        "hora_inicio": "09:00:00",
        "hora_fin": "11:00:00",
        "materia": "Clase 2",
    }, headers=admin_headers)
    assert response.status_code == 409
    assert "Conflicto" in response.json()["detail"]


def test_horario_mismo_dia_sin_cruce_acepta(client, admin_headers):
    salon_id = _crear_salon(client, admin_headers, "Salon-NoConf-1")

    # Crear primer horario: 8:00-10:00
    client.post("/horarios", json={
        "salon_id": salon_id,
        "dia_semana": 1,
        "hora_inicio": "08:00:00",
        "hora_fin": "10:00:00",
    }, headers=admin_headers)

    # Horario posterior sin cruce: 10:00-12:00
    response = client.post("/horarios", json={
        "salon_id": salon_id,
        "dia_semana": 1,
        "hora_inicio": "10:00:00",
        "hora_fin": "12:00:00",
    }, headers=admin_headers)
    assert response.status_code == 201


def test_listar_horarios_filtrados(client, admin_headers, auth_headers):
    salon_id = _crear_salon(client, admin_headers, "Salon-Filt-1")

    # Crear horarios en diferentes días
    client.post("/horarios", json={
        "salon_id": salon_id, "dia_semana": 1,
        "hora_inicio": "08:00:00", "hora_fin": "10:00:00",
        "semestre": "2026-2",
    }, headers=admin_headers)
    client.post("/horarios", json={
        "salon_id": salon_id, "dia_semana": 3,
        "hora_inicio": "14:00:00", "hora_fin": "16:00:00",
        "semestre": "2026-2",
    }, headers=admin_headers)

    # Filtrar por día
    response = client.get(
        f"/horarios?salon_id={salon_id}&dia_semana=1",
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_carga_masiva_horarios(client, admin_headers):
    salon_id = _crear_salon(client, admin_headers, "Salon-Bulk-1")

    response = client.post("/horarios/bulk", json={
        "items": [
            {
                "salon_id": salon_id, "dia_semana": 1,
                "hora_inicio": "08:00:00", "hora_fin": "10:00:00",
                "materia": "Clase Lunes", "semestre": "2026-2",
            },
            {
                "salon_id": salon_id, "dia_semana": 3,
                "hora_inicio": "08:00:00", "hora_fin": "10:00:00",
                "materia": "Clase Miércoles", "semestre": "2026-2",
            },
        ]
    }, headers=admin_headers)
    assert response.status_code == 201
    assert len(response.json()) == 2


def test_eliminar_horario(client, admin_headers, auth_headers):
    salon_id = _crear_salon(client, admin_headers, "Salon-DelH-1")
    res = client.post("/horarios", json={
        "salon_id": salon_id, "dia_semana": 5,
        "hora_inicio": "16:00:00", "hora_fin": "18:00:00",
    }, headers=admin_headers)
    horario_id = res.json()["id"]

    res_del = client.delete(f"/horarios/{horario_id}", headers=admin_headers)
    assert res_del.status_code == 200

    res_get = client.get(f"/horarios/{horario_id}", headers=auth_headers)
    assert res_get.status_code == 404


def test_disponibilidad_con_horarios(client, admin_headers, auth_headers):
    """La disponibilidad debe excluir franjas con horarios académicos."""
    salon_id = _crear_salon(client, admin_headers, "Salon-DispH-1")

    # Crear horario de 8:00 a 10:00
    client.post("/horarios", json={
        "salon_id": salon_id, "dia_semana": 2,
        "hora_inicio": "08:00:00", "hora_fin": "10:00:00",
    }, headers=admin_headers)

    # Crear horario de 14:00 a 16:00
    client.post("/horarios", json={
        "salon_id": salon_id, "dia_semana": 2,
        "hora_inicio": "14:00:00", "hora_fin": "16:00:00",
    }, headers=admin_headers)

    # Consultar disponibilidad del martes
    response = client.get(
        f"/salones/{salon_id}/disponibilidad?dia_semana=2",
        headers=auth_headers,
    )
    assert response.status_code == 200
    franjas = response.json()
    # Esperamos 3 franjas libres: 6-8, 10-14, 16-22
    assert len(franjas) == 3
    assert franjas[0]["hora_inicio"] == "06:00:00"
    assert franjas[0]["hora_fin"] == "08:00:00"
    assert franjas[1]["hora_inicio"] == "10:00:00"
    assert franjas[1]["hora_fin"] == "14:00:00"
    assert franjas[2]["hora_inicio"] == "16:00:00"
    assert franjas[2]["hora_fin"] == "22:00:00"

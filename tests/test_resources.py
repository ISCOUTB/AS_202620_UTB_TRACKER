"""
Pruebas del módulo de recursos (S4).

Cubre:
- Creación de recursos (requiere rol admin).
- Rechazo de serial duplicado (409).
- Listado de recursos.
- Actualización y eliminación.
- Reporte de estado.
"""


def test_crear_recurso(client, admin_headers):
    response = client.post("/recursos", json={
        "categoria": "video_beam",
        "serial": "VB-2026-0001",
    }, headers=admin_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["estado"] == "disponible"
    assert data["serial"] == "VB-2026-0001"


def test_no_permite_serial_duplicado(client, admin_headers):
    payload = {"categoria": "computador", "serial": "PC-24"}
    client.post("/recursos", json=payload, headers=admin_headers)
    response = client.post("/recursos", json=payload, headers=admin_headers)
    assert response.status_code == 409


def test_listar_recursos(client, admin_headers, auth_headers):
    client.post("/recursos", json={
        "categoria": "tv", "serial": "TV-01",
    }, headers=admin_headers)
    response = client.get("/recursos", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == 1


def test_crear_recurso_sin_admin_rechaza(client, auth_headers):
    """Un usuario normal no puede crear recursos."""
    response = client.post("/recursos", json={
        "categoria": "audio", "serial": "AU-01",
    }, headers=auth_headers)
    assert response.status_code == 403


def test_actualizar_recurso(client, admin_headers):
    res = client.post("/recursos", json={
        "categoria": "video_beam", "serial": "VB-UPD-01",
    }, headers=admin_headers)
    recurso_id = res.json()["id"]

    response = client.put(f"/recursos/{recurso_id}", json={
        "descripcion": "Video beam Samsung HD",
    }, headers=admin_headers)
    assert response.status_code == 200
    assert response.json()["descripcion"] == "Video beam Samsung HD"


def test_eliminar_recurso(client, admin_headers, auth_headers):
    res = client.post("/recursos", json={
        "categoria": "computador", "serial": "PC-DEL-01",
    }, headers=admin_headers)
    recurso_id = res.json()["id"]

    # Eliminar (soft-delete)
    res_del = client.delete(f"/recursos/{recurso_id}", headers=admin_headers)
    assert res_del.status_code == 200

    # Ya no debe aparecer en listado
    response = client.get("/recursos", headers=auth_headers)
    serials = [r["serial"] for r in response.json()]
    assert "PC-DEL-01" not in serials


def test_reportar_recurso(client, admin_headers, auth_headers):
    res = client.post("/recursos", json={
        "categoria": "aire_ac", "serial": "AC-RPT-01",
    }, headers=admin_headers)
    recurso_id = res.json()["id"]

    # Reportar daño
    response = client.post(f"/recursos/{recurso_id}/reportar", json={
        "estado_reportado": "dañado",
        "descripcion": "Fuga de agua en la unidad",
    }, headers=auth_headers)
    assert response.status_code == 201
    assert response.json()["estado_reportado"] == "dañado"

    # Verificar que el recurso cambió de estado
    recurso = client.get(f"/recursos/{recurso_id}", headers=auth_headers).json()
    assert recurso["estado"] == "dañado"


def test_listar_reportes_recurso(client, admin_headers, auth_headers):
    res = client.post("/recursos", json={
        "categoria": "tv", "serial": "TV-RPT-01",
    }, headers=admin_headers)
    recurso_id = res.json()["id"]

    # Crear dos reportes
    client.post(f"/recursos/{recurso_id}/reportar", json={
        "estado_reportado": "mantenimiento",
        "descripcion": "Pantalla parpadea",
    }, headers=auth_headers)
    client.post(f"/recursos/{recurso_id}/reportar", json={
        "estado_reportado": "disponible",
        "descripcion": "Reparado",
    }, headers=auth_headers)

    response = client.get(f"/recursos/{recurso_id}/reportes", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == 2

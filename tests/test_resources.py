def test_crear_recurso(client):
    response = client.post("/recursos", json={
        "categoria": "video_beam",
        "salon_id": "A1-304",
        "serial": "VB-2026-0001",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["estado"] == "disponible"
    assert data["serial"] == "VB-2026-0001"


def test_no_permite_serial_duplicado(client):
    payload = {"categoria": "computador", "salon_id": "A1-304", "serial": "PC-24"}
    client.post("/recursos", json=payload)
    response = client.post("/recursos", json=payload)
    assert response.status_code == 409


def test_listar_recursos(client):
    client.post("/recursos", json={"categoria": "tv", "salon_id": "B2-101", "serial": "TV-01"})
    response = client.get("/recursos")
    assert response.status_code == 200
    assert len(response.json()) == 1

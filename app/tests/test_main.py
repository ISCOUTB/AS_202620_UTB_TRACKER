from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """
    Verifica que el servidor de UTB Tracker arranca correctamente
    y el endpoint de salud responde con el estado esperado.
    """
    response = client.get("/salud/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "proyecto": "UTB Tracker"}

from django.test import TestCase, Client


class HealthCheckTests(TestCase):
    """
    Prueba minima del esqueleto ejecutable: confirma que el servidor
    arranca y responde. No prueba logica de negocio (todavia no existe).
    """

    def test_health_check_responde_200(self):
        client = Client()
        response = client.get("/salud/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "ok")

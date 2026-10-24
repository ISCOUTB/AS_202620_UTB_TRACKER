"""
Pruebas automatizadas de resiliencia (S11 — req. 11.1 a 11.4).

Cubre:
- Idempotencia en creación de préstamos con 'X-Idempotency-Key' (req. 11.3).
- Reintentos automáticos con backoff y jitter (req. 11.2).
- Comportamiento del patrón Circuit Breaker (req. 11.4).
"""
import time
import pytest

from app.core.resilience import (
    CircuitBreaker,
    CircuitBreakerOpenException,
    CircuitBreakerState,
    with_retry,
)


def _crear_recurso(client, admin_headers, serial="RESIL-001"):
    response = client.post(
        "/recursos",
        json={
            "categoria": "computador",
            "serial": serial,
        },
        headers=admin_headers,
    )
    return response.json()["id"]


def test_idempotencia_prestamo_con_misma_clave(client, admin_headers, auth_headers):
    """
    Verifica que al enviar la misma cabecera X-Idempotency-Key repetidamente:
    1. La primera petición crea el préstamo (201).
    2. La segunda petición (reintento del móvil) retorna el mismo préstamo sin 409.
    3. Una petición diferente sobre el mismo recurso falla con 409 (recurso ya prestado).
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="IDEM-999")
    idempotency_key = "req-uuid-test-12345"

    payload = {
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-10-25T18:00:00",
    }
    headers = {**auth_headers, "X-Idempotency-Key": idempotency_key}

    # Primera petición: creación normal
    res1 = client.post("/prestamos", json=payload, headers=headers)
    assert res1.status_code == 201
    prestamo_id_1 = res1.json()["id"]

    # Segunda petición idéntica con la misma clave (simula reintento por red inestable)
    res2 = client.post("/prestamos", json=payload, headers=headers)
    assert res2.status_code == 201
    assert res2.json()["id"] == prestamo_id_1
    assert res2.json()["recurso_id"] == recurso_id

    # Tercera petición con otra clave: debe ser rechazada con 409
    headers_otra = {**auth_headers, "X-Idempotency-Key": "otra-clave-diferente"}
    res3 = client.post("/prestamos", json=payload, headers=headers_otra)
    assert res3.status_code == 409
    assert "no esta disponible" in res3.json()["detail"]


def test_with_retry_exito_tras_fallo_transitorio():
    """El decorador reintenta y retorna el resultado si la función se recupera."""
    intentos = 0

    @with_retry(max_retries=3, base_delay=0.01, max_delay=0.05)
    def operacion_inestable():
        nonlocal intentos
        intentos += 1
        if intentos < 3:
            raise ConnectionError("Fallo transitorio de conexión a BD")
        return "exito"

    resultado = operacion_inestable()
    assert resultado == "exito"
    assert intentos == 3


def test_with_retry_lanza_excepcion_al_superar_maximo():
    """Lanza la excepción si se supera el número máximo de reintentos."""
    intentos = 0

    @with_retry(max_retries=2, base_delay=0.01, max_delay=0.05)
    def operacion_siempre_falla():
        nonlocal intentos
        intentos += 1
        raise TimeoutError("Timeout persistente")

    with pytest.raises(TimeoutError):
        operacion_siempre_falla()

    assert intentos == 3  # 1 inicial + 2 reintentos


def test_circuit_breaker_transiciones_de_estado():
    """Comprueba el cambio a OPEN tras fallos y rechazo inmediato."""
    cb = CircuitBreaker(failure_threshold=2, recovery_timeout=0.2)

    @cb
    def servicio_externo():
        raise RuntimeError("Servicio caído")

    # Primer fallo: aún CLOSED
    with pytest.raises(RuntimeError):
        servicio_externo()
    assert cb.state == CircuitBreakerState.CLOSED

    # Segundo fallo: alcanza umbral -> OPEN
    with pytest.raises(RuntimeError):
        servicio_externo()
    assert cb.state == CircuitBreakerState.OPEN

    # Siguiente llamada: rechazada de inmediato por cortacircuitos abierto
    with pytest.raises(CircuitBreakerOpenException):
        servicio_externo()

    # Esperar recuperación a HALF_OPEN
    time.sleep(0.25)

    # Definir una función que tenga éxito para restaurar a CLOSED
    @cb
    def servicio_recuperado():
        return "OK"

    resultado = servicio_recuperado()
    assert resultado == "OK"
    assert cb.state == CircuitBreakerState.CLOSED

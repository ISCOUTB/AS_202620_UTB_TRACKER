"""
Pruebas del taller de mensajería asíncrona — UTB Tracker.

Cubre:
1. Inserción atómica en la misma transacción (Outbox Pattern).
2. Rollback no deja mensaje en outbox (Atomicidad).
3. Procesamiento exitoso por el worker.
4. Idempotencia en el consumidor ante reentrega (Deduplicación).
5. Reintentos con backoff exponencial sin sleep bloqueante.
6. Dead Letter Queue / Estado 'muerto' al superar max_intentos.
7. Tolerancia a campos desconocidos (Evolución de contratos / Compatibilidad).
8. Rechazo explícito ante versiones de contrato no soportadas.
9. Trazabilidad con correlation_id y message_id en logs.
"""
from datetime import datetime, timedelta, timezone
import json
import logging
import uuid
import pytest

from app.messaging.events import VERSIONES_SOPORTADAS, EventoPrestamoCreado, PayloadPrestamoCreado
from app.messaging.models import MensajeOutbox, NotificacionProcesada
from app.messaging.worker import (
    NotificadorSimulado,
    _calcular_siguiente_intento,
    procesar_pendientes,
)
from app.models.recurso_models import Recurso


def _crear_recurso(client, admin_headers, serial="VB-MSG-001"):
    res = client.post(
        "/recursos",
        json={"categoria": "video_beam", "serial": serial},
        headers=admin_headers,
    )
    assert res.status_code == 201
    return res.json()["id"]


def test_outbox_se_inserta_en_misma_transaccion_que_prestamo(
    client, admin_headers, auth_headers, db_session
):
    """
    Req 1: Al crear un préstamo exitosamente, se inserta una fila en mensajes_outbox
    en la misma transacción atómica, con correlation_id, tipo='prestamo.creado' y estado='pendiente'.
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-ATOM-01")

    res = client.post(
        "/prestamos",
        json={
            "recurso_id": recurso_id,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )
    assert res.status_code == 201
    prestamo_id = res.json()["id"]

    # Verificar que el mensaje está en el outbox
    msg = (
        db_session.query(MensajeOutbox)
        .filter(MensajeOutbox.tipo == "prestamo.creado")
        .first()
    )
    assert msg is not None
    assert msg.estado == "pendiente"
    assert msg.version == 1
    assert msg.intentos == 0
    assert msg.correlation_id is not None
    assert len(msg.correlation_id) > 0

    # Verificar payload
    payload = json.loads(msg.payload)
    assert payload["prestamo_id"] == prestamo_id
    assert payload["usuario_id"] == 1
    assert payload["recurso_id"] == recurso_id


def test_rollback_no_deja_mensaje_en_outbox(
    client, admin_headers, auth_headers, db_session
):
    """
    Req 2: Si la creación del préstamo falla (ej. recurso inexistente o conflicto),
    el rollback evita que quede ningún mensaje espurio en mensajes_outbox.
    """
    # Intentar prestar recurso inexistente (404)
    res_404 = client.post(
        "/prestamos",
        json={
            "recurso_id": 99999,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )
    assert res_404.status_code == 404

    # Intentar prestar con usuario inexistente (404)
    rec_id = _crear_recurso(client, admin_headers, serial="VB-ROLL-01")
    res_no_user = client.post(
        "/prestamos",
        json={
            "recurso_id": rec_id,
            "usuario_id": 88888,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )
    assert res_no_user.status_code == 404

    # Ningún mensaje debe haber quedado registrado en outbox
    mensajes = db_session.query(MensajeOutbox).all()
    assert len(mensajes) == 0


def test_worker_procesa_mensaje_exitosamente(
    client, admin_headers, auth_headers, db_session
):
    """
    Req 3: El worker lee un mensaje pendiente, invoca al notificador,
    registra en notificaciones_procesadas y actualiza el estado a 'enviado'.
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-WORK-01")
    client.post(
        "/prestamos",
        json={
            "recurso_id": recurso_id,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )

    notificador = NotificadorSimulado(fallos_antes_de_exito=0)
    procesados = procesar_pendientes(db_session, notificador)
    assert procesados == 1
    assert notificador._envios == 1

    msg = db_session.query(MensajeOutbox).first()
    assert msg.estado == "enviado"
    assert msg.procesado_en is not None
    assert msg.ultimo_error is None

    dedup = db_session.query(NotificacionProcesada).filter_by(message_id=msg.message_id).first()
    assert dedup is not None


def test_consumidor_idempotente_ante_reentrega(
    client, admin_headers, auth_headers, db_session
):
    """
    Req 4: Si ocurre un reprocesamiento o reentrega del mismo message_id,
    el consumidor detecta la entrada en notificaciones_procesadas y no duplica el envío.
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-IDEM-01")
    client.post(
        "/prestamos",
        json={
            "recurso_id": recurso_id,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )

    notificador = NotificadorSimulado(fallos_antes_de_exito=0)
    procesar_pendientes(db_session, notificador)
    assert notificador._envios == 1

    # Simular reentrega: el mensaje vuelve a aparecer como pendiente con el mismo message_id
    msg = db_session.query(MensajeOutbox).first()
    msg.estado = "pendiente"
    db_session.commit()

    # Segunda ejecución del worker
    procesar_pendientes(db_session, notificador)
    # No debe haberse llamado a enviar() por segunda vez
    assert notificador._envios == 1
    assert msg.estado == "enviado"


def test_reintentos_backoff_exponencial_sin_sleep(db_session):
    """
    Req 5: Cuando el notificador falla, se reprograma con backoff exponencial y jitter,
    sin usar time.sleep() que bloquearía el worker. La prueba corre instantáneamente.
    """
    ahora = datetime.now(timezone.utc)
    mid = str(uuid.uuid4())
    payload = json.dumps({"prestamo_id": 1, "usuario_id": 1})

    msg = MensajeOutbox(
        message_id=mid,
        tipo="prestamo.creado",
        version=1,
        payload=payload,
        correlation_id="test-corr",
        estado="pendiente",
        intentos=0,
        siguiente_intento=ahora.replace(tzinfo=None),
        creado_en=ahora.replace(tzinfo=None),
    )
    db_session.add(msg)
    db_session.commit()

    # Notificador configurado para fallar 1 vez y luego tener éxito
    notificador = NotificadorSimulado(fallos_antes_de_exito=1)

    t0 = datetime.now()
    # Intento 1: falla
    procesar_pendientes(db_session, notificador, ahora=ahora)
    t_elapsed = (datetime.now() - t0).total_seconds()

    # Comprobar que no hubo sleep bloqueante
    assert t_elapsed < 0.5, "El reintento no debe bloquear con time.sleep()"

    db_session.refresh(msg)
    assert msg.estado == "pendiente"
    assert msg.intentos == 1
    assert msg.ultimo_error is not None
    assert msg.siguiente_intento > ahora.replace(tzinfo=None)

    # Intento 2 antes de la hora programada: no debe procesarse
    procesar_pendientes(db_session, notificador, ahora=ahora)
    assert msg.intentos == 1

    # Intento 2 en el futuro (hora programada alcanzada): debe tener éxito
    futuro = ahora + timedelta(seconds=60)
    procesar_pendientes(db_session, notificador, ahora=futuro)
    db_session.refresh(msg)
    assert msg.estado == "enviado"
    assert msg.intentos == 2
    assert notificador._envios == 1


def test_mensaje_muerto_al_superar_max_intentos(db_session):
    """
    Req 6: Si los fallos superan max_intentos (por defecto 5, o parametrizado a 3),
    el mensaje pasa a estado 'muerto' (Dead Letter Queue) y guarda el error.
    """
    ahora = datetime.now(timezone.utc)
    mid = str(uuid.uuid4())
    msg = MensajeOutbox(
        message_id=mid,
        tipo="prestamo.creado",
        version=1,
        payload=json.dumps({"prestamo_id": 99, "usuario_id": 1}),
        correlation_id="test-dlq",
        estado="pendiente",
        intentos=0,
        siguiente_intento=ahora.replace(tzinfo=None),
        creado_en=ahora.replace(tzinfo=None),
    )
    db_session.add(msg)
    db_session.commit()

    # Notificador que siempre falla
    notificador = NotificadorSimulado(fallos_antes_de_exito=999)

    # Ejecutar 3 intentos con max_intentos=3
    for i in range(1, 4):
        tiempo = ahora + timedelta(seconds=i * 100)
        procesar_pendientes(db_session, notificador, ahora=tiempo, max_intentos=3)
        db_session.refresh(msg)

    assert msg.estado == "muerto"
    assert msg.intentos == 3
    assert "Fallo simulado" in msg.ultimo_error


def test_tolerancia_a_campos_desconocidos_en_evento(db_session):
    """
    Req 7: Compatibilidad hacia adelante — el consumidor acepta mensajes que contengan
    campos desconocidos sin romperse (gracias a ConfigDict(extra='ignore')).
    """
    ahora = datetime.now(timezone.utc)
    mid = str(uuid.uuid4())
    # Payload con campos inesperados de una versión o extensión futura
    payload_futuro = {
        "prestamo_id": 42,
        "usuario_id": 1,
        "campo_futuro_nuevo": "valor_ignorado",
        "metadata_extra": {"origen": "terminal_iot", "version_firmware": "3.2.1"},
    }

    msg = MensajeOutbox(
        message_id=mid,
        tipo="prestamo.creado",
        version=1,
        payload=json.dumps(payload_futuro),
        correlation_id="test-extra-fields",
        estado="pendiente",
        siguiente_intento=ahora.replace(tzinfo=None),
        creado_en=ahora.replace(tzinfo=None),
    )
    db_session.add(msg)
    db_session.commit()

    notificador = NotificadorSimulado(fallos_antes_de_exito=0)
    procesar_pendientes(db_session, notificador, ahora=ahora)

    db_session.refresh(msg)
    assert msg.estado == "enviado"
    assert notificador._envios == 1


def test_rechazo_explicito_si_version_de_contrato_no_soportada(db_session):
    """
    Req 8: Si el mensaje tiene una versión de contrato no soportada (ej. versión 2),
    el worker lo marca como 'muerto' con un error explícito en lugar de descartarlo silenciosamente.
    """
    ahora = datetime.now(timezone.utc)
    mid = str(uuid.uuid4())

    msg = MensajeOutbox(
        message_id=mid,
        tipo="prestamo.creado",
        version=99,  # Versión futura o incompatible
        payload=json.dumps({"prestamo_id": 1, "usuario_id": 1}),
        correlation_id="test-version-check",
        estado="pendiente",
        siguiente_intento=ahora.replace(tzinfo=None),
        creado_en=ahora.replace(tzinfo=None),
    )
    db_session.add(msg)
    db_session.commit()

    notificador = NotificadorSimulado(fallos_antes_de_exito=0)
    procesar_pendientes(db_session, notificador, ahora=ahora)

    db_session.refresh(msg)
    assert msg.estado == "muerto"
    assert "no soportada" in msg.ultimo_error
    assert notificador._envios == 0


def test_trazabilidad_logs_correlation_id(caplog, db_session):
    """
    Req 9: Cada log del worker incluye explícitamente message_id y correlation_id
    para permitir trazabilidad distribuida de punta a punta.
    """
    ahora = datetime.now(timezone.utc)
    mid = str(uuid.uuid4())
    cid = "corr-test-12345"

    msg = MensajeOutbox(
        message_id=mid,
        tipo="prestamo.creado",
        version=1,
        payload=json.dumps({"prestamo_id": 10, "usuario_id": 1}),
        correlation_id=cid,
        estado="pendiente",
        siguiente_intento=ahora.replace(tzinfo=None),
        creado_en=ahora.replace(tzinfo=None),
    )
    db_session.add(msg)
    db_session.commit()

    notificador = NotificadorSimulado(fallos_antes_de_exito=0)

    with caplog.at_level(logging.INFO):
        procesar_pendientes(db_session, notificador, ahora=ahora)

    logs_text = caplog.text
    assert mid in logs_text, f"message_id {mid} no encontrado en logs"
    assert cid in logs_text, f"correlation_id {cid} no encontrado en logs"


# ──────────────────────────────────────────────────────────────────────────────
# Pruebas nuevas (tarea 1 del taller)
# ──────────────────────────────────────────────────────────────────────────────


def test_idempotencia_http_con_x_idempotency_key(
    client, admin_headers, auth_headers, db_session
):
    """
    Tarea 1a: Dos POST /prestamos con la misma X-Idempotency-Key devuelven
    el mismo préstamo y dejan exactamente UN mensaje en mensajes_outbox.
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-IDEMP-01")

    idem_key = "test-idempotency-key-001"
    body = {
        "recurso_id": recurso_id,
        "usuario_id": 1,
        "fecha_devolucion_esperada": "2026-10-30T18:00:00",
    }

    # Primer POST
    res1 = client.post(
        "/prestamos",
        json=body,
        headers={**auth_headers, "X-Idempotency-Key": idem_key},
    )
    assert res1.status_code == 201, f"Primer POST falló: {res1.json()}"
    prestamo_id_1 = res1.json()["id"]

    # Segundo POST con la misma clave
    res2 = client.post(
        "/prestamos",
        json=body,
        headers={**auth_headers, "X-Idempotency-Key": idem_key},
    )
    assert res2.status_code == 201, f"Segundo POST falló: {res2.json()}"
    prestamo_id_2 = res2.json()["id"]

    # Deben ser el mismo préstamo
    assert prestamo_id_1 == prestamo_id_2, (
        f"Esperaba el mismo ID, pero obtuve {prestamo_id_1} y {prestamo_id_2}"
    )

    # Debe haber exactamente UN mensaje outbox para este recurso
    mensajes = (
        db_session.query(MensajeOutbox)
        .filter(MensajeOutbox.tipo == "prestamo.creado")
        .all()
    )
    assert len(mensajes) == 1, (
        f"Esperaba 1 mensaje en outbox, hay {len(mensajes)}"
    )


def test_desacoplamiento_temporal_sin_worker(
    client, admin_headers, auth_headers, db_session
):
    """
    Tarea 1b: Sin ejecutar el worker, POST /prestamos responde 201 y el
    mensaje queda "pendiente"; luego procesar_pendientes lo pasa a "enviado".
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-DESAC-01")

    res = client.post(
        "/prestamos",
        json={
            "recurso_id": recurso_id,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )
    assert res.status_code == 201

    # El mensaje debe existir y estar "pendiente"
    msg = (
        db_session.query(MensajeOutbox)
        .filter(MensajeOutbox.tipo == "prestamo.creado")
        .first()
    )
    assert msg is not None, "No se encontró mensaje en outbox"
    assert msg.estado == "pendiente", f"Esperaba 'pendiente', tiene '{msg.estado}'"

    # Ahora ejecutamos el worker (procesar_pendientes)
    notificador = NotificadorSimulado(fallos_antes_de_exito=0)
    procesados = procesar_pendientes(db_session, notificador)
    assert procesados == 1, f"Esperaba 1 procesado, obtuve {procesados}"

    db_session.refresh(msg)
    assert msg.estado == "enviado", f"Esperaba 'enviado', tiene '{msg.estado}'"
    assert notificador._envios == 1


def test_rollback_real_forzando_fallo_en_commit(
    client, admin_headers, auth_headers, db_session
):
    """
    Tarea 1c: Fuerza una excepción en db.commit() dentro de crear_prestamo
    (después de flush + inserción en outbox) y verifica que:
    - No queda préstamo en la BD.
    - No queda mensaje en mensajes_outbox.
    - El recurso sigue con estado "disponible".
    """
    from app.main import app
    from app.core.database import get_db
    from app.models.recurso_models import Prestamo, Recurso

    recurso_id = _crear_recurso(client, admin_headers, serial="VB-RBACK-01")

    # Verificar estado inicial del recurso
    recurso_antes = db_session.query(Recurso).filter(Recurso.id == recurso_id).first()
    assert recurso_antes.estado == "disponible"

    # Contar préstamos y mensajes antes
    prestamos_antes = db_session.query(Prestamo).count()
    mensajes_antes = db_session.query(MensajeOutbox).count()

    # Parchear el commit de la sesión que usa el servicio.
    # override_get_db crea una nueva sesión; necesitamos interceptar su commit.
    original_get_db_fn = app.dependency_overrides.get(get_db)

    def sabotaged_get_db():
        gen = original_get_db_fn()
        session = next(gen)
        original_commit = session.commit

        def commit_que_falla(*args, **kwargs):
            # Restaurar commit original para que el cleanup funcione
            session.commit = original_commit
            session.rollback()
            raise RuntimeError("Fallo forzado en commit para probar rollback")

        session.commit = commit_que_falla
        try:
            yield session
        finally:
            try:
                next(gen)
            except StopIteration:
                pass

    app.dependency_overrides[get_db] = sabotaged_get_db

    try:
        # TestClient de Starlette propaga excepciones del servidor por defecto
        # en lugar de devolver HTTP 500, así que usamos pytest.raises.
        with pytest.raises(RuntimeError, match="Fallo forzado en commit"):
            client.post(
                "/prestamos",
                json={
                    "recurso_id": recurso_id,
                    "usuario_id": 1,
                    "fecha_devolucion_esperada": "2026-10-30T18:00:00",
                },
                headers=auth_headers,
            )
    finally:
        # Restaurar el override original
        app.dependency_overrides[get_db] = original_get_db_fn

    # Refrescar la sesión de lectura para ver el estado actual de la BD
    db_session.expire_all()

    # No debe haber nuevos préstamos
    prestamos_despues = db_session.query(Prestamo).count()
    assert prestamos_despues == prestamos_antes, (
        f"Esperaba {prestamos_antes} préstamos, hay {prestamos_despues}"
    )

    # No debe haber nuevos mensajes en outbox
    mensajes_despues = db_session.query(MensajeOutbox).count()
    assert mensajes_despues == mensajes_antes, (
        f"Esperaba {mensajes_antes} mensajes, hay {mensajes_despues}"
    )

    # El recurso debe seguir "disponible"
    db_session.refresh(recurso_antes)
    assert recurso_antes.estado == "disponible", (
        f"Esperaba 'disponible', tiene '{recurso_antes.estado}'"
    )


def test_trazabilidad_http_x_request_id_coincide_con_correlation_id(
    client, admin_headers, auth_headers, db_session
):
    """
    Verifica que al hacer POST /prestamos vía HTTP (sin pasar correlation_id),
    el encabezado X-Request-ID devuelto en la respuesta HTTP coincide exactamente
    con el correlation_id persistido en el registro de mensajes_outbox.
    """
    recurso_id = _crear_recurso(client, admin_headers, serial="VB-REQID-01")

    res = client.post(
        "/prestamos",
        json={
            "recurso_id": recurso_id,
            "usuario_id": 1,
            "fecha_devolucion_esperada": "2026-10-30T18:00:00",
        },
        headers=auth_headers,
    )
    assert res.status_code == 201
    assert "X-Request-ID" in res.headers, "Encabezado X-Request-ID no presente en la respuesta"
    request_id_header = res.headers["X-Request-ID"]

    # Consultar el mensaje outbox generado para este préstamo
    msg = (
        db_session.query(MensajeOutbox)
        .filter(MensajeOutbox.tipo == "prestamo.creado")
        .order_by(MensajeOutbox.id.desc())
        .first()
    )
    assert msg is not None, "No se encontró el mensaje outbox"
    assert msg.correlation_id == request_id_header, (
        f"Esperaba correlation_id={request_id_header}, pero outbox tiene {msg.correlation_id}"
    )


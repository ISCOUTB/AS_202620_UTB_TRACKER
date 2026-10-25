"""
Worker de mensajería asíncrona — consumidor del outbox (taller).

Diseño:
  - procesar_pendientes(db, notificador, ahora, max_intentos): función pura
    invocable desde pruebas sin necesidad de time.sleep ni threads.
  - NotificadorBase: interfaz/protocolo del notificador externo.
  - NotificadorSimulado: implementación de log, usada en desarrollo.
    Acepta un contador de fallos inyectables para pruebas.
  - Punto de entrada CLI: `python -m app.messaging.worker`
    Bucle de polling configurable con parada limpia vía Ctrl-C.

Política de reintentos (backoff exponencial con jitter):
  - Por qué NO usamos with_retry de resilience.py:
    with_retry llama a time.sleep() en el hilo actual, lo que bloquea
    el worker durante décadas en los intentos posteriores. En cambio,
    calculamos el instante `siguiente_intento` con la misma fórmula
    (base_delay * 2^intento + jitter) y lo persistimos en la BD.
    El worker se despierta al siguiente poll y decide si ya es hora
    de reintentar comparando con "ahora". Esto permite que el proceso
    esté disponible para otros mensajes mientras espera.
  - Fórmula: base_delay=2s, delay = min(60, 2 * 2^intentos) + jitter
    Intento 1 → 2s, intento 2 → 4s, intento 3 → 8s, intento 4 → 16s,
    intento 5 → 32s (máx 5 intentos → DLQ / estado "muerto").

Trazabilidad:
  - Cada log incluye siempre message_id y correlation_id para poder
    seguir un mensaje de punta a punta en cualquier agregador de logs.
"""
import json
import logging
import os
import random
import time
from datetime import datetime, timedelta, timezone
from typing import Optional, Protocol

from sqlalchemy.orm import Session

from app.messaging.events import VERSIONES_SOPORTADAS
from app.messaging.models import MensajeOutbox, NotificacionProcesada

logger = logging.getLogger("utb_tracker.messaging.worker")

# --------------------------------------------------------------------------
# Configuración via variables de entorno
# --------------------------------------------------------------------------
WORKER_POLL_INTERVAL = int(os.getenv("WORKER_POLL_INTERVAL", "5"))      # segundos
WORKER_MAX_INTENTOS = int(os.getenv("WORKER_MAX_INTENTOS", "5"))        # intentos
WORKER_BASE_DELAY = float(os.getenv("WORKER_BASE_DELAY", "2.0"))        # segundos
WORKER_MAX_DELAY = float(os.getenv("WORKER_MAX_DELAY", "60.0"))         # segundos
# Variable para forzar fallos del notificador en pruebas/staging
WORKER_FORZAR_FALLOS = int(os.getenv("WORKER_FORZAR_FALLOS", "0"))


# --------------------------------------------------------------------------
# Interfaz del notificador (protocolo estructural)
# --------------------------------------------------------------------------
class NotificadorBase(Protocol):
    """
    Protocolo que debe cumplir cualquier notificador externo.
    Permite inyectar distintas implementaciones (log, SMTP, push, etc.)
    sin acoplar el worker a ninguna biblioteca concreta.
    """
    def enviar(self, email: str, asunto: str, cuerpo: str) -> None:
        """Envía una notificación. Lanza excepción en caso de fallo."""
        ...


class NotificadorSimulado:
    """
    Implementación simulada del notificador: escribe en el log.

    Acepta `fallos_antes_de_exito` para simular un servicio externo
    inestable en pruebas: los primeros N llamados lanzan excepción,
    el N+1 tiene éxito.
    """

    def __init__(self, fallos_antes_de_exito: int = 0):
        self._fallos_restantes = fallos_antes_de_exito + WORKER_FORZAR_FALLOS
        self._envios = 0

    def enviar(self, email: str, asunto: str, cuerpo: str) -> None:
        if self._fallos_restantes > 0:
            self._fallos_restantes -= 1
            raise RuntimeError(
                f"[NotificadorSimulado] Fallo simulado "
                f"({self._fallos_restantes} restantes)"
            )
        self._envios += 1
        logger.info(
            "[NotificadorSimulado] Notificación enviada — "
            "email=%s asunto=%r envio_num=%d",
            email,
            asunto,
            self._envios,
        )


# --------------------------------------------------------------------------
# Cálculo del backoff (misma fórmula que resilience.py, sin sleep)
# --------------------------------------------------------------------------
def _calcular_siguiente_intento(intentos: int) -> datetime:
    """
    Calcula el instante UTC del próximo intento usando backoff exponencial.

    Fórmula: delay = min(WORKER_MAX_DELAY, WORKER_BASE_DELAY * 2^intentos)
             delay += jitter aleatorio de hasta 10 % de delay.
    Retorna: datetime UTC = ahora + delay.
    """
    delay = min(WORKER_MAX_DELAY, WORKER_BASE_DELAY * (2 ** intentos))
    jitter = random.uniform(0, delay * 0.1)
    total = delay + jitter
    return datetime.now(timezone.utc) + timedelta(seconds=total)


# --------------------------------------------------------------------------
# Función principal del worker (pura e inyectable desde pruebas)
# --------------------------------------------------------------------------
def procesar_pendientes(
    db: Session,
    notificador: NotificadorBase,
    ahora: Optional[datetime] = None,
    max_intentos: int = WORKER_MAX_INTENTOS,
) -> int:
    """
    Procesa mensajes del outbox cuyo siguiente_intento <= ahora.

    Parámetros:
      db:           Sesión SQLAlchemy activa.
      notificador:  Implementación del notificador externo.
      ahora:        Reloj inyectado para pruebas (por defecto: UTC ahora).
      max_intentos: Máximo de intentos antes de marcar "muerto".

    Retorna:
      Número de mensajes procesados (exitosos + muertos).
    """
    if ahora is None:
        ahora = datetime.now(timezone.utc)

    # Normalizar a naive UTC para comparar con los valores guardados
    # SQLite almacena datetimes como naive; PostgreSQL como aware.
    ahora_naive = ahora.replace(tzinfo=None) if ahora.tzinfo else ahora

    pendientes = (
        db.query(MensajeOutbox)
        .filter(
            MensajeOutbox.estado == "pendiente",
            MensajeOutbox.siguiente_intento <= ahora_naive,
        )
        .order_by(MensajeOutbox.creado_en)
        .all()
    )

    procesados = 0
    for msg in pendientes:
        _procesar_un_mensaje(db, msg, notificador, ahora, max_intentos)
        procesados += 1

    return procesados


def _procesar_un_mensaje(
    db: Session,
    msg: MensajeOutbox,
    notificador: NotificadorBase,
    ahora: datetime,
    max_intentos: int,
) -> None:
    """
    Intenta entregar un único mensaje del outbox.

    Flujo:
      1. Validar versión del contrato.
      2. Verificar deduplicación en notificaciones_procesadas.
      3. Resolver email del usuario desde la BD.
      4. Llamar al notificador.
      5. Marcar en notificaciones_procesadas (idempotencia).
      6. Actualizar estado del mensaje en outbox.
    """
    mid = msg.message_id
    cid = msg.correlation_id or "n/a"

    # 1. Validar versión
    if msg.version not in VERSIONES_SOPORTADAS:
        error = (
            f"Versión {msg.version} no soportada. "
            f"Versiones soportadas: {sorted(VERSIONES_SOPORTADAS)}"
        )
        logger.error(
            "[worker] message_id=%s correlation_id=%s "
            "VERSION_NO_SOPORTADA — %s",
            mid, cid, error,
        )
        msg.estado = "muerto"
        msg.ultimo_error = error
        db.commit()
        return

    # 2. Deduplicación: ya procesado previamente
    ya_procesado = (
        db.query(NotificacionProcesada)
        .filter(NotificacionProcesada.message_id == mid)
        .first()
    )
    if ya_procesado:
        logger.info(
            "[worker] message_id=%s correlation_id=%s "
            "DUPLICADO_DESCARTADO — mensaje ya procesado, omitiendo envío",
            mid, cid,
        )
        # Aun así sincronizamos el estado del outbox si quedó desincronizado
        if msg.estado == "pendiente":
            msg.estado = "enviado"
            msg.procesado_en = ya_procesado.procesado_en
            db.commit()
        return

    # 3. Resolver email del usuario desde el payload
    try:
        raw_dict = json.loads(msg.payload)
        if isinstance(raw_dict, dict) and "payload" in raw_dict and isinstance(raw_dict["payload"], dict):
            payload_dict = raw_dict["payload"]
        else:
            payload_dict = raw_dict
        usuario_id = payload_dict.get("usuario_id")
        prestamo_id = payload_dict.get("prestamo_id")
    except (json.JSONDecodeError, KeyError, AttributeError) as exc:
        _marcar_muerto(db, msg, f"Payload inválido: {exc}", mid, cid)
        return

    email = _resolver_email(db, usuario_id)
    if not email:
        _marcar_muerto(
            db, msg,
            f"Usuario {usuario_id} no encontrado en BD",
            mid, cid,
        )
        return

    # 4. Intentar envío
    msg.intentos += 1
    logger.info(
        "[worker] message_id=%s correlation_id=%s "
        "INTENTO_%d tipo=%s prestamo_id=%s usuario_id=%s",
        mid, cid, msg.intentos, msg.tipo, prestamo_id, usuario_id,
    )

    try:
        notificador.enviar(
            email=email,
            asunto="UTB Tracker — Préstamo registrado",
            cuerpo=(
                f"Hola, se registró el préstamo #{prestamo_id}. "
                f"Correlation-ID: {cid}"
            ),
        )
    except Exception as exc:  # noqa: BLE001
        error_str = str(exc)
        logger.warning(
            "[worker] message_id=%s correlation_id=%s "
            "FALLO intento=%d error=%r",
            mid, cid, msg.intentos, error_str,
        )

        if msg.intentos >= max_intentos:
            _marcar_muerto(db, msg, error_str, mid, cid)
        else:
            prox = _calcular_siguiente_intento(msg.intentos)
            msg.siguiente_intento = prox.replace(tzinfo=None)
            msg.ultimo_error = error_str
            logger.info(
                "[worker] message_id=%s correlation_id=%s "
                "REPROGRAMADO siguiente_intento=%s",
                mid, cid, prox.isoformat(),
            )
            db.commit()
        return

    # 5. Éxito: registrar en tabla de deduplicación
    ahora_naive = ahora.replace(tzinfo=None) if ahora.tzinfo else ahora
    db.add(NotificacionProcesada(
        message_id=mid,
        procesado_en=ahora_naive,
    ))

    # 6. Actualizar outbox
    msg.estado = "enviado"
    msg.procesado_en = ahora_naive
    msg.ultimo_error = None
    db.commit()

    logger.info(
        "[worker] message_id=%s correlation_id=%s ENVIADO prestamo_id=%s",
        mid, cid, prestamo_id,
    )


def _marcar_muerto(
    db: Session,
    msg: MensajeOutbox,
    error: str,
    mid: str,
    cid: str,
) -> None:
    msg.estado = "muerto"
    msg.ultimo_error = error
    db.commit()
    logger.error(
        "[worker] message_id=%s correlation_id=%s "
        "MUERTO intentos=%d error=%r",
        mid, cid, msg.intentos, error,
    )


def _resolver_email(db: Session, usuario_id: Optional[int]) -> Optional[str]:
    """Consulta el email de un usuario en la BD. Retorna None si no existe."""
    if usuario_id is None:
        return None
    from app.models.auth_models import Usuario
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    return usuario.email if usuario else None


# --------------------------------------------------------------------------
# Punto de entrada CLI: python -m app.messaging.worker
# --------------------------------------------------------------------------
def _run_loop() -> None:
    """Bucle principal de polling. Se detiene limpiamente con Ctrl-C."""
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format=(
            '{"time":"%(asctime)s","level":"%(levelname)s",'
            '"logger":"%(name)s","msg":"%(message)s"}'
        ),
        datefmt="%Y-%m-%dT%H:%M:%S",
    )

    from app.core.database import SessionLocal
    from app.messaging.models import MensajeOutbox, NotificacionProcesada  # noqa: F401 — registra tablas

    notificador = NotificadorSimulado()
    logger.info("[worker] Iniciando. poll_interval=%ds", WORKER_POLL_INTERVAL)

    try:
        while True:
            db = SessionLocal()
            try:
                n = procesar_pendientes(db, notificador)
                if n:
                    logger.info("[worker] Ciclo completado — procesados=%d", n)
            except Exception:  # noqa: BLE001
                logger.exception("[worker] Error inesperado en el ciclo de polling")
            finally:
                db.close()
            time.sleep(WORKER_POLL_INTERVAL)
    except KeyboardInterrupt:
        logger.info("[worker] Detenido por el usuario (Ctrl-C).")


if __name__ == "__main__":
    _run_loop()

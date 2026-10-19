"""
Mecanismos de resiliencia del sistema (S11 — req. 11.2 y 11.4).

Provee:
1. with_retry: decorador de reintentos con retroceso exponencial (backoff)
   y perturbación aleatoria (jitter) para operaciones transitorias.
2. CircuitBreaker: patrón cortacircuitos para proteger el sistema ante caídas
   prolongadas en dependencias o servicios externos (CLOSED -> OPEN -> HALF_OPEN).
"""
import functools
import logging
import random
import time
from enum import Enum
from typing import Any, Callable, Type

logger = logging.getLogger("utb_tracker.resilience")


def with_retry(
    max_retries: int = 3,
    base_delay: float = 0.1,
    max_delay: float = 1.0,
    retryable_exceptions: tuple[Type[Exception], ...] = (Exception,),
):
    """
    Decorador que reintenta la función decorada con backoff exponencial y jitter.
    Fórmula: delay = min(max_delay, base_delay * (2 ** intento)) + jitter.
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            attempt = 0
            while True:
                try:
                    return func(*args, **kwargs)
                except retryable_exceptions as exc:
                    attempt += 1
                    if attempt > max_retries:
                        logger.error(
                            f"[Resilience] Fallo definitivo tras {max_retries} reintentos en {func.__name__}: {exc}"
                        )
                        raise
                    # Backoff exponencial + Jitter
                    jitter = random.uniform(0, base_delay * 0.5)
                    delay = min(max_delay, base_delay * (2 ** (attempt - 1))) + jitter
                    logger.warning(
                        f"[Resilience] Intento {attempt}/{max_retries} falló en {func.__name__}: {exc}. "
                        f"Reintentando en {delay:.3f}s..."
                    )
                    time.sleep(delay)
        return wrapper
    return decorator


class CircuitBreakerState(Enum):
    CLOSED = "CLOSED"        # Operación normal
    OPEN = "OPEN"            # Bloqueado: rechaza llamadas de inmediato
    HALF_OPEN = "HALF_OPEN"  # Prueba de recuperación


class CircuitBreakerOpenException(Exception):
    """Excepción lanzada cuando el cortacircuitos está en estado OPEN."""
    pass


class CircuitBreaker:
    """
    Implementación del patrón Circuit Breaker (S11 — req. 11.4).
    Evita saturar recursos caídos fallando rápidamente sin esperar timeouts.
    """

    def __init__(
        self,
        failure_threshold: int = 3,
        recovery_timeout: float = 5.0,
        expected_exceptions: tuple[Type[Exception], ...] = (Exception,),
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exceptions = expected_exceptions

        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.last_state_change = time.time()

    def __call__(self, func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            self._check_state()

            if self.state == CircuitBreakerState.OPEN:
                raise CircuitBreakerOpenException(
                    f"CircuitBreaker para {func.__name__} está ABIERTO (OPEN). Llamada rechazada de inmediato."
                )

            try:
                result = func(*args, **kwargs)
                self._on_success()
                return result
            except self.expected_exceptions as exc:
                self._on_failure()
                raise exc

        return wrapper

    def _check_state(self):
        now = time.time()
        if self.state == CircuitBreakerState.OPEN:
            if now - self.last_state_change >= self.recovery_timeout:
                self.state = CircuitBreakerState.HALF_OPEN
                self.last_state_change = now
                logger.info("[CircuitBreaker] Estado transicionado a HALF_OPEN para prueba")

    def _on_success(self):
        if self.state in (CircuitBreakerState.HALF_OPEN, CircuitBreakerState.CLOSED):
            self.failure_count = 0
            self.state = CircuitBreakerState.CLOSED

    def _on_failure(self):
        self.failure_count += 1
        if self.failure_count >= self.failure_threshold or self.state == CircuitBreakerState.HALF_OPEN:
            self.state = CircuitBreakerState.OPEN
            self.last_state_change = time.time()
            logger.error(
                f"[CircuitBreaker] Umbral de fallos ({self.failure_count}) alcanzado. Estado cambiado a OPEN."
            )

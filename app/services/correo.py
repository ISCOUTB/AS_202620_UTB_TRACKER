"""
Servicio de correo de UTB Tracker (ADR-0015).

Dos caminos:
  - encolar(db, ...): lo usan los servicios. Escribe el evento "correo.enviar" en el outbox EN
    LA MISMA TRANSACCIÓN del cambio (ADR-0006). Si la transacción se revierte, no sale correo.
  - enviar(destino, plantilla, datos): lo usa el worker. Renderiza la plantilla y la entrega con
    el proveedor configurado.

Proveedores:
  - ProveedorSMTP: correo real con STARTTLS (USE_REAL_MAIL=true + SMTP_*).
  - ProveedorDesarrollo: NO envía; guarda el correo completo (.eml y .html) en CORREOS_DIR
    (logs/correos/) y escribe en el log dónde quedó. Permite probar todo el flujo sin cuenta de
    correo. En producción, config.py avisa en el log si USE_REAL_MAIL sigue en false.
"""
import logging
import re
import smtplib
import ssl
from datetime import datetime, timezone
from email.message import EmailMessage
from email.utils import formataddr, make_msgid
from pathlib import Path
from typing import Optional, Protocol

from sqlalchemy.orm import Session

from app.core import config
from app.core.politica import correo_valido, normalizar_correo
from app.messaging.publisher import publicar_evento
from app.services.plantillas_correo import categoria, renderizar

logger = logging.getLogger("utb_tracker.correo")

TIPO_EVENTO = "correo.enviar"


class Proveedor(Protocol):
    def entregar(self, mensaje: EmailMessage) -> str:
        """Entrega el mensaje; devuelve una referencia para el log. Lanza excepción si falla."""
        ...


def _construir(destino: str, plantilla: str, datos: dict, remitente: str) -> EmailMessage:
    destino = normalizar_correo(destino)
    if not correo_valido(destino):
        raise ValueError("Destino de correo inválido")
    asunto, texto, html = renderizar(plantilla, datos)
    msg = EmailMessage()
    # EmailMessage rechaza saltos de línea en cabeceras: sin inyección de cabeceras.
    msg["From"] = remitente
    msg["To"] = destino
    msg["Subject"] = asunto
    msg["Message-ID"] = make_msgid(domain="utb-tracker")
    msg["X-UTB-Plantilla"] = plantilla
    msg.set_content(texto)
    msg.add_alternative(html, subtype="html")
    return msg


class ProveedorSMTP:
    def __init__(
        self,
        host: str = "",
        port: int = 0,
        username: str = "",
        password: str = "",
        remitente: str = "",
    ):
        self.host = host or config.SMTP_HOST
        self.port = port or config.SMTP_PORT
        self.username = username or config.SMTP_USERNAME
        self.password = password or config.SMTP_PASSWORD
        self.remitente = remitente or config.SMTP_FROM
        if not self.host or not self.remitente:
            raise RuntimeError("SMTP_HOST y SMTP_FROM son obligatorios con USE_REAL_MAIL=true")

    def entregar(self, mensaje: EmailMessage) -> str:
        contexto = ssl.create_default_context()
        with smtplib.SMTP(self.host, self.port, timeout=15) as servidor:
            servidor.starttls(context=contexto)
            if self.username:
                servidor.login(self.username, self.password)
            servidor.send_message(mensaje)
        return f"smtp:{self.host}"


class ProveedorDesarrollo:
    """Guarda el correo en disco en lugar de enviarlo (modo desarrollo)."""

    def __init__(self, carpeta: Optional[str] = None):
        self.carpeta = Path(carpeta or config.CORREOS_DIR)

    def entregar(self, mensaje: EmailMessage) -> str:
        self.carpeta.mkdir(parents=True, exist_ok=True)
        sello = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S-%f")
        destino = re.sub(r"[^a-zA-Z0-9@._-]", "_", str(mensaje["To"]))
        base = f"{sello}_{mensaje['X-UTB-Plantilla']}_{destino}"
        # Sin with_suffix: el correo termina en ".co" y with_suffix lo reemplazaría.
        eml, html_ruta = self.carpeta / f"{base}.eml", self.carpeta / f"{base}.html"
        eml.write_bytes(bytes(mensaje))
        html = mensaje.get_body(preferencelist=("html",))
        if html is not None:
            html_ruta.write_text(html.get_content(), encoding="utf-8")
        texto = mensaje.get_body(preferencelist=("plain",)).get_content()
        enlaces = re.findall(r"https?://\S+", texto)
        # Solo en desarrollo se escribe el enlace en el log (lleva el token).
        if config.ENVIRONMENT != "production":
            logger.info(
                "[correo-dev] NO enviado. Para=%s Asunto=%r Archivo=%s Enlace=%s",
                mensaje["To"], str(mensaje["Subject"]), html_ruta,
                enlaces[0] if enlaces else "-",
            )
        return str(eml)


def crear_proveedor() -> Proveedor:
    return ProveedorSMTP() if config.USE_REAL_MAIL else ProveedorDesarrollo()


def enviar(
    destino: str, plantilla: str, datos: dict, proveedor: Optional[Proveedor] = None
) -> str:
    """Interfaz única: renderiza y entrega YA (la usa el worker)."""
    proveedor = proveedor or crear_proveedor()
    remitente = config.SMTP_FROM or formataddr(("UTB Tracker", "no-responder@utb-tracker.local"))
    return proveedor.entregar(_construir(destino, plantilla, datos, remitente))


def encolar(
    db: Session,
    destino: str,
    plantilla: str,
    datos: dict,
    usuario_id: Optional[int] = None,
) -> None:
    """Deja el correo en el outbox en la transacción actual (el commit lo hace quien llama).

    Ojo: `datos` puede llevar enlaces con tokens; el outbox vive en la base (igual de protegida
    que las cuentas) y el worker nunca escribe el payload en el log.
    """
    renderizar(plantilla, datos)  # falla aquí (y no en el worker) si faltan datos
    publicar_evento(db, TIPO_EVENTO, {
        "destino": normalizar_correo(destino),
        "plantilla": plantilla,
        "categoria": categoria(plantilla),
        "datos": datos,
        "usuario_id": usuario_id,
    })


def ocultar_correo(correo: str) -> str:
    """'ana.perez@utb.edu.co' -> 'an***@utb.edu.co' (para avisos al correo anterior)."""
    usuario, _, dominio = correo.partition("@")
    return f"{usuario[:2]}***@{dominio}"

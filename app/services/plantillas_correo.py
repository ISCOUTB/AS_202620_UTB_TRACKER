"""
Plantillas de correo de UTB Tracker (ADR-0015).

Cada plantilla devuelve (asunto, texto_plano, html). Todo dato que viene del usuario o de la
base se escapa con html.escape antes de entrar al HTML, y los enlaces solo se aceptan si son
http(s). Identidad: verde #187943 e índigo #332D83 del Manual de identidad UTB.
"""
from html import escape
from typing import Callable

VERDE = "#187943"
INDIGO = "#332D83"

# Categorías (para preferencias, Fase 2). "seguridad" siempre se envía.
SEGURIDAD = "seguridad"
CUENTA = "cuenta"


def _e(valor) -> str:
    return escape(str(valor if valor is not None else ""), quote=True)


def _enlace_seguro(url: str) -> str:
    url = str(url or "")
    if not url.startswith(("http://", "https://")):
        raise ValueError("Enlace de correo inválido")
    return url


def _boton(texto: str, url: str) -> str:
    return (
        f'<p style="margin:24px 0"><a href="{_e(_enlace_seguro(url))}" '
        f'style="background:{VERDE};color:#ffffff;padding:12px 22px;border-radius:10px;'
        f'text-decoration:none;font-weight:bold;display:inline-block">{_e(texto)}</a></p>'
        f'<p style="font-size:12px;color:#666">Si el botón no funciona, copia este enlace en tu '
        f'navegador:<br><span style="word-break:break-all">{_e(url)}</span></p>'
    )


def _codigo(codigo: str) -> str:
    return (
        '<p style="font-size:12px;color:#666">O pega este código en la app:</p>'
        f'<p style="font-family:monospace;font-size:12px;background:#f2f2f6;padding:10px;'
        f'border-radius:8px;word-break:break-all">{_e(codigo)}</p>'
    )


def _layout(titulo: str, cuerpo_html: str) -> str:
    return f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>{_e(titulo)}</title></head>
<body style="margin:0;background:#f4f4f7;font-family:Arial,Helvetica,sans-serif;color:#1b1b1f">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px 12px">
<table role="presentation" width="100%" style="max-width:560px;background:#ffffff;border-radius:16px;overflow:hidden">
<tr><td style="background:{INDIGO};padding:18px 24px;color:#ffffff">
<span style="font-size:20px;font-weight:bold">UTB Tracker</span><br>
<span style="font-size:11px;letter-spacing:1.5px;color:#cfd0ff">CAMPUS TECNOLÓGICO</span></td></tr>
<tr><td style="height:4px;background:{VERDE}"></td></tr>
<tr><td style="padding:24px">
<h1 style="font-size:20px;color:{INDIGO};margin:0 0 12px">{_e(titulo)}</h1>
{cuerpo_html}
</td></tr>
<tr><td style="padding:14px 24px;background:#fafafc;font-size:11px;color:#777">
Correo automático de UTB Tracker, la herramienta de salones del Campus Tecnológico de la
Universidad Tecnológica de Bolívar. No respondas a este mensaje.</td></tr>
</table></td></tr></table></body></html>"""


def _texto(lineas: list[str]) -> str:
    return "\n".join(lineas + ["", "— UTB Tracker · Campus Tecnológico (correo automático)"])


# --------------------------------------------------------------------------
# Plantillas
# --------------------------------------------------------------------------
def verificacion(d: dict) -> tuple[str, str, str]:
    asunto = "Confirma tu correo en UTB Tracker"
    horas = d.get("horas", 24)
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        "Para activar tu cuenta de UTB Tracker confirma que este correo es tuyo abriendo:",
        d["enlace"],
        "",
        f"El enlace vence en {horas} horas y sirve una sola vez.",
        "Si no creaste esta cuenta, ignora este correo.",
    ])
    html = _layout("Confirma tu correo", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        "<p>Para activar tu cuenta confirma que este correo es tuyo. Mientras no lo hagas puedes "
        "entrar y consultar, pero no solicitar salones.</p>"
        + _boton("Confirmar mi correo", d["enlace"])
        + f"<p style='font-size:12px;color:#666'>Vence en {_e(horas)} horas y sirve una sola vez. "
        "Si no creaste esta cuenta, ignora este correo.</p>"
    ))
    return asunto, texto, html


def bienvenida(d: dict) -> tuple[str, str, str]:
    asunto = "¡Bienvenido a UTB Tracker!"
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        "Tu correo quedó confirmado. Ya puedes solicitar salones del Campus Tecnológico y seguir",
        "el estado de tus solicitudes en la pestaña Control.",
    ])
    html = _layout("¡Tu cuenta está lista!", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        "<p>Tu correo quedó confirmado. Ya puedes <b>solicitar salones</b> del Campus Tecnológico "
        "y seguir el estado de tus solicitudes en la pestaña <b>Control</b>.</p>"
    ))
    return asunto, texto, html


def recuperacion(d: dict) -> tuple[str, str, str]:
    asunto = "Recupera tu contraseña de UTB Tracker"
    minutos = d.get("minutos", 30)
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        "Pediste cambiar tu contraseña. Ábrelo aquí:",
        d["enlace"],
        "",
        "O en la app: Iniciar sesión > ¿Olvidaste tu contraseña? > Ya tengo un código, y pega:",
        d["codigo"],
        "",
        f"Vence en {minutos} minutos y sirve una sola vez.",
        "Si no fuiste tú, ignora este correo: tu contraseña no cambia.",
    ])
    html = _layout("Recupera tu contraseña", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        "<p>Pediste cambiar tu contraseña de UTB Tracker.</p>"
        + _boton("Elegir una contraseña nueva", d["enlace"])
        + _codigo(d["codigo"])
        + f"<p style='font-size:12px;color:#666'>Vence en {_e(minutos)} minutos y sirve una sola "
        "vez. Si no fuiste tú, ignora este correo: tu contraseña no cambia.</p>"
    ))
    return asunto, texto, html


def cambio_correo_nuevo(d: dict) -> tuple[str, str, str]:
    asunto = "Confirma tu nuevo correo en UTB Tracker"
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        f"Pediste usar {d.get('correo_nuevo', '')} en tu cuenta de UTB Tracker. Confírmalo aquí:",
        d["enlace"],
        "",
        "Hasta que lo confirmes, tu cuenta sigue usando el correo anterior.",
    ])
    html = _layout("Confirma tu nuevo correo", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        f"<p>Pediste usar <b>{_e(d.get('correo_nuevo'))}</b> en tu cuenta. Hasta que lo confirmes, "
        "tu cuenta sigue usando el correo anterior.</p>"
        + _boton("Confirmar el nuevo correo", d["enlace"])
    ))
    return asunto, texto, html


def cambio_correo_aviso(d: dict) -> tuple[str, str, str]:
    asunto = "Aviso: pidieron cambiar el correo de tu cuenta"
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        f"Se pidió cambiar el correo de tu cuenta de UTB Tracker a {d.get('correo_nuevo_oculto', '')}.",
        "El cambio solo se hace si se confirma desde ese correo nuevo.",
        "Si no fuiste tú, cambia tu contraseña de inmediato y avisa al administrador.",
    ])
    html = _layout("Pidieron cambiar tu correo", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        f"<p>Se pidió cambiar el correo de tu cuenta a <b>{_e(d.get('correo_nuevo_oculto'))}</b>. "
        "El cambio solo se hace si se confirma desde ese correo nuevo.</p>"
        "<p><b>Si no fuiste tú</b>, cambia tu contraseña de inmediato y avisa al administrador.</p>"
    ))
    return asunto, texto, html


def cambio_password(d: dict) -> tuple[str, str, str]:
    asunto = "Tu contraseña de UTB Tracker cambió"
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        f"La contraseña de tu cuenta cambió el {d.get('fecha', '')}. Se cerraron las demás sesiones.",
        "Si no fuiste tú, usa ¿Olvidaste tu contraseña? de inmediato y avisa al administrador.",
    ])
    html = _layout("Tu contraseña cambió", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        f"<p>La contraseña de tu cuenta cambió el <b>{_e(d.get('fecha'))}</b>. Por seguridad se "
        "cerraron las sesiones abiertas en otros dispositivos.</p>"
        "<p><b>Si no fuiste tú</b>, usa «¿Olvidaste tu contraseña?» de inmediato y avisa al "
        "administrador.</p>"
    ))
    return asunto, texto, html


def inicio_sesion_sospechoso(d: dict) -> tuple[str, str, str]:
    asunto = "Alerta: inicio de sesión tras varios intentos fallidos"
    texto = _texto([
        f"Hola, {d.get('nombre', '')}:",
        "",
        f"Se entró a tu cuenta el {d.get('fecha', '')} después de {d.get('fallidos', '')} intentos",
        "fallidos. Si fuiste tú, no hagas nada. Si no, cambia tu contraseña y cierra las demás",
        "sesiones desde Perfil > Seguridad.",
    ])
    html = _layout("Inicio de sesión tras intentos fallidos", (
        f"<p>Hola, <b>{_e(d.get('nombre'))}</b>:</p>"
        f"<p>Se entró a tu cuenta el <b>{_e(d.get('fecha'))}</b> después de "
        f"<b>{_e(d.get('fallidos'))}</b> intentos fallidos.</p>"
        "<p>Si fuiste tú, no hagas nada. Si no, cambia tu contraseña y cierra las demás sesiones "
        "desde <b>Perfil &gt; Seguridad</b>.</p>"
    ))
    return asunto, texto, html


PLANTILLAS: dict[str, tuple[Callable[[dict], tuple[str, str, str]], str]] = {
    "verificacion": (verificacion, SEGURIDAD),
    "bienvenida": (bienvenida, CUENTA),
    "recuperacion": (recuperacion, SEGURIDAD),
    "cambio_correo_nuevo": (cambio_correo_nuevo, SEGURIDAD),
    "cambio_correo_aviso": (cambio_correo_aviso, SEGURIDAD),
    "cambio_password": (cambio_password, SEGURIDAD),
    "inicio_sesion_sospechoso": (inicio_sesion_sospechoso, SEGURIDAD),
}


def categoria(plantilla: str) -> str:
    return PLANTILLAS[plantilla][1]


def renderizar(plantilla: str, datos: dict) -> tuple[str, str, str]:
    if plantilla not in PLANTILLAS:
        raise ValueError(f"Plantilla de correo desconocida: {plantilla}")
    asunto, texto, html = PLANTILLAS[plantilla][0](datos)
    # El asunto va en una cabecera: nunca con saltos de línea.
    return " ".join(asunto.split()), texto, html

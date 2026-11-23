"""
Páginas HTML mínimas que abren los enlaces de los correos (ADR-0014): "Correo verificado" y
"Elige tu nueva contraseña". Sin plantillas externas ni paquetes nuevos; todo dato se escapa.
La página de contraseña envía JSON a POST /auth/reset-password con fetch (no hace falta
python-multipart) y aplica la misma política que la API.
"""
import json
from html import escape

from app.service.politica import PASSWORD_MINIMO
from app.service.plantillas_correo import INDIGO, VERDE

# Las páginas no cargan nada externo y solo ejecutan su propio script en línea.
CSP = (
    "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; "
    "connect-src 'self'; form-action 'none'; frame-ancestors 'none'; base-uri 'none'"
)


def _pagina(titulo: str, cuerpo: str, ok: bool = True) -> str:
    color = VERDE if ok else "#B3261E"
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex"><title>{escape(titulo)} · UTB Tracker</title>
<style>
body{{margin:0;background:#0b0b10;font-family:Arial,Helvetica,sans-serif;color:#fff;
display:flex;min-height:100vh;align-items:center;justify-content:center}}
.c{{width:min(420px,92vw);background:#1b1c21;border-radius:18px;overflow:hidden;
box-shadow:0 10px 40px #0008}}
.h{{background:{INDIGO};padding:18px 22px}}.h b{{font-size:20px}}
.h small{{display:block;font-size:11px;letter-spacing:1.5px;color:#cfd0ff}}
.f{{height:4px;background:{VERDE}}}.b{{padding:22px}}
h1{{font-size:21px;margin:0 0 10px;color:{color}}}p{{color:#c5c8d0;line-height:1.45}}
input{{width:100%;box-sizing:border-box;padding:12px;margin:6px 0 4px;border-radius:10px;
border:1px solid #3a3d46;background:#111216;color:#fff;font-size:15px}}
button{{width:100%;margin-top:12px;padding:12px;border:0;border-radius:10px;
background:{VERDE};color:#fff;font-weight:bold;font-size:15px;cursor:pointer}}
#m{{min-height:20px;font-size:14px}}
</style></head><body><main class="c"><div class="h"><b>UTB Tracker</b>
<small>CAMPUS TECNOLÓGICO</small></div><div class="f"></div><div class="b">
<h1>{escape(titulo)}</h1>{cuerpo}</div></main></body></html>"""


def enlace_invalido(mensaje: str) -> str:
    return _pagina("El enlace no sirve", (
        f"<p>{escape(mensaje)}</p>"
        "<p>Desde la app puedes pedir uno nuevo: <b>Reenviar correo</b> o "
        "<b>¿Olvidaste tu contraseña?</b>.</p>"
    ), ok=False)


def formulario_restablecer(token: str) -> str:
    # El token va como dato JSON dentro del script (json.dumps escapa comillas y </script>).
    token_js = json.dumps(token).replace("<", "\\u003c")
    return _pagina("Elige tu nueva contraseña", f"""
<p>Escribe una contraseña de al menos {PASSWORD_MINIMO} caracteres, distinta de tu correo y de tu
nombre de usuario.</p>
<label for="p1">Nueva contraseña</label><input id="p1" type="password" autocomplete="new-password">
<label for="p2">Repítela</label><input id="p2" type="password" autocomplete="new-password">
<p id="m" role="status" aria-live="polite"></p><button id="b" type="button">Guardar</button>
<script>
const T={token_js};const m=document.getElementById('m');
document.getElementById('b').onclick=async()=>{{
 const a=document.getElementById('p1').value,b=document.getElementById('p2').value;
 if(a.length<{PASSWORD_MINIMO}){{m.textContent='La contraseña debe tener al menos {PASSWORD_MINIMO} caracteres';return}}
 if(a!==b){{m.textContent='Las contraseñas no coinciden';return}}
 m.textContent='Guardando…';
 try{{const r=await fetch('/auth/reset-password',{{method:'POST',
  headers:{{'Content-Type':'application/json'}},body:JSON.stringify({{token:T,new_password:a}})}});
  const j=await r.json().catch(()=>({{}}));
  if(r.ok){{document.querySelector('.b').innerHTML='<h1>Contraseña actualizada</h1><p>Ya puedes entrar a la app con tu nueva contraseña. Se cerraron las sesiones abiertas en otros dispositivos.</p>';return}}
  const d=j.detail;m.textContent=Array.isArray(d)?d.map(e=>e.msg).join('. '):(d||'No se pudo guardar');
 }}catch(e){{m.textContent='Sin conexión con el servidor. Intenta de nuevo.'}}
}};
</script>""")

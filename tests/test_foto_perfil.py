"""
Foto de perfil (ADR-0020, Fase 3): validación del lado servidor, limpieza de metadatos,
reemplazo y borrado, caché por versión, permisos, límite de frecuencia y borrado al desactivar.

Las imágenes se arman byte a byte (sin Pillow): una estructura JPEG/PNG válida con metadatos
de ubicación y datos escondidos al final, que el servidor debe quitar.
"""
import json
import struct
import zlib

import pytest

from app.core import config
from app.models.auditoria_models import RegistroAuditoria
from app.models.auth_models import FotoPerfil
from app.services import imagenes

GPS = b"GPS-LATITUD-10.39-LONGITUD-75.48"
ESCONDIDO = b"<script>alert(1)</script>"


# --------------------------------------------------------------------------
# Imágenes de prueba
# --------------------------------------------------------------------------
def _png(ancho=64, alto=64, extra=b"") -> bytes:
    def bloque(tipo, datos):
        return struct.pack(">I", len(datos)) + tipo + datos + struct.pack(
            ">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF)

    filas = b"".join(b"\x00" + b"\x80\x40\x20" * ancho for _ in range(alto))
    return (imagenes.FIRMA_PNG
            + bloque(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0))
            + bloque(b"tEXt", b"Location\x00" + GPS)
            + bloque(b"eXIf", b"MM\x00*" + GPS)
            + bloque(b"IDAT", zlib.compress(filas))
            + bloque(b"IEND", b"") + extra)


def _segmento(marcador, cuerpo):
    return bytes((0xFF, marcador)) + struct.pack(">H", len(cuerpo) + 2) + cuerpo


def _exif(orientacion=6) -> bytes:
    # IFD0 con Orientation + un puntero al IFD de GPS (que debe desaparecer).
    tiff = b"II*\x00" + struct.pack("<I", 8) + struct.pack("<H", 2)
    tiff += struct.pack("<HHIHH", 0x0112, 3, 1, orientacion, 0)
    tiff += struct.pack("<HHII", 0x8825, 4, 1, 38) + struct.pack("<I", 0) + GPS
    return b"Exif\x00\x00" + tiff


def _jpeg(ancho=64, alto=64, orientacion=6, extra=b"") -> bytes:
    return (b"\xff\xd8"
            + _segmento(0xE0, b"JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
            + _segmento(0xE1, _exif(orientacion))
            + _segmento(0xE1, b"http://ns.adobe.com/xap/1.0/\x00" + GPS)  # XMP
            + _segmento(0xFE, b"comentario " + GPS)
            + _segmento(0xDB, b"\x00" + bytes(range(64)))
            + _segmento(0xC0, b"\x08" + struct.pack(">HH", alto, ancho) + b"\x01\x01\x11\x00")
            + _segmento(0xC4, b"\x00" + b"\x01" + b"\x00" * 15 + b"\x00")
            + _segmento(0xDA, b"\x01\x01\x00\x00\x3f\x00")
            + b"\x12\x34\xff\x00\x56\xff\xd0\x78"  # datos con relleno FF00 y un RST0
            + b"\xff\xd9" + extra)


def _subir(client, headers, datos, tipo="image/jpeg"):
    return client.put("/auth/me/foto", content=datos,
                      headers={**headers, "Content-Type": tipo})


def _acciones(db, accion):
    db.expire_all()
    return db.query(RegistroAuditoria).filter(RegistroAuditoria.accion == accion).all()


# --------------------------------------------------------------------------
# Limpieza (unidad)
# --------------------------------------------------------------------------
def test_jpeg_sin_metadatos_conserva_solo_la_orientacion():
    limpia = imagenes.limpiar(_jpeg(extra=ESCONDIDO))
    assert limpia.tipo == "image/jpeg" and (limpia.ancho, limpia.alto) == (64, 64)
    assert GPS not in limpia.contenido
    assert b"adobe" not in limpia.contenido
    assert ESCONDIDO not in limpia.contenido and limpia.contenido.endswith(b"\xff\xd9")
    assert imagenes._orientacion_exif(limpia.contenido[6:6 + 40]) == 6
    # Sin orientación especial no queda ningún EXIF.
    assert b"Exif" not in imagenes.limpiar(_jpeg(orientacion=1)).contenido


def test_png_sin_bloques_de_texto_ni_exif():
    limpia = imagenes.limpiar(_png(extra=ESCONDIDO))
    assert limpia.tipo == "image/png" and (limpia.ancho, limpia.alto) == (64, 64)
    assert GPS not in limpia.contenido and ESCONDIDO not in limpia.contenido
    assert limpia.contenido.endswith(b"IEND\xaeB`\x82")


@pytest.mark.parametrize("datos", [
    _jpeg()[:-40],                                  # truncado
    _png()[:-20],                                   # truncado
    _png().replace(b"IHDR", b"IHDX", 1),            # CRC no coincide
    b"\xff\xd8\xff\xd9",                            # sin tamaño
])
def test_estructuras_danadas_se_rechazan(datos):
    with pytest.raises(imagenes.ImagenInvalida):
        imagenes.limpiar(datos)


# --------------------------------------------------------------------------
# Endpoints
# --------------------------------------------------------------------------
@pytest.mark.parametrize("datos, tipo", [(_jpeg(), "image/jpeg"), (_png(), "image/png")])
def test_sube_jpeg_y_png_validos(client, auth_headers, db_session, datos, tipo):
    r = _subir(client, auth_headers, datos, tipo)
    assert r.status_code == 200, r.text
    assert r.json()["tiene_foto"] is True and r.json()["tipo"] == tipo
    me = client.get("/auth/me", headers=auth_headers).json()
    assert me["tiene_foto"] is True and me["foto_version"] == r.json()["foto_version"] > 0
    foto = client.get("/auth/me/foto", headers=auth_headers)
    assert foto.status_code == 200
    assert foto.headers["content-type"] == tipo
    assert foto.headers["x-content-type-options"] == "nosniff"
    assert "private" in foto.headers["cache-control"]
    assert GPS not in foto.content  # lo guardado ya no tiene la ubicación
    registro = _acciones(db_session, "usuario.foto_actualizada")[0]
    assert json.loads(registro.detalle)["tipo"] == tipo  # sin el contenido


def test_tipo_lo_decide_el_contenido_no_la_extension(client, auth_headers):
    falso = b"GIF89a" + b"\x00" * 200  # se hace pasar por .jpg
    r = _subir(client, auth_headers, falso, "image/jpeg")
    assert r.status_code == 415
    assert r.json()["detail"] == "Solo se aceptan fotos JPEG o PNG."
    html = b"<html><script>alert(1)</script></html>"
    assert _subir(client, auth_headers, html, "image/png").status_code == 415
    # Un PNG verdadero declarado como texto se acepta como PNG.
    r = _subir(client, auth_headers, _png(), "text/plain")
    assert r.status_code == 200 and r.json()["tipo"] == "image/png"


def test_demasiado_grande_413(client, auth_headers, monkeypatch):
    monkeypatch.setattr(config, "FOTO_MAX_BYTES", 1024)
    r = _subir(client, auth_headers, _png(ancho=64, alto=64) + b"\x00" * 2048)
    assert r.status_code == 413
    assert "demasiado grande" in r.json()["detail"]


def test_dimensiones_fuera_de_rango_422(client, auth_headers):
    assert _subir(client, auth_headers, _png(ancho=8, alto=8)).status_code == 422
    assert _subir(client, auth_headers, _jpeg(ancho=4000, alto=3000)).status_code == 422


def test_danada_422_y_vacia_422(client, auth_headers):
    assert _subir(client, auth_headers, _jpeg()[:-40]).status_code == 422
    assert _subir(client, auth_headers, b"").status_code == 422


def test_reemplaza_y_borra(client, auth_headers, db_session):
    v1 = _subir(client, auth_headers, _jpeg()).json()["foto_version"]
    v2 = _subir(client, auth_headers, _png()).json()["foto_version"]
    assert v2 > v1
    db_session.expire_all()
    assert db_session.query(FotoPerfil).count() == 1  # se reemplaza, no se acumula
    r = client.delete("/auth/me/foto", headers=auth_headers)
    assert r.status_code == 200 and r.json()["tiene_foto"] is False
    db_session.expire_all()
    assert db_session.query(FotoPerfil).count() == 0
    me = client.get("/auth/me", headers=auth_headers).json()
    assert me["tiene_foto"] is False and me["foto_version"] == 0
    assert client.get("/auth/me/foto", headers=auth_headers).status_code == 404
    assert _acciones(db_session, "usuario.foto_eliminada")


def test_sin_sesion_no_se_sube_ni_se_ve(client):
    assert client.put("/auth/me/foto", content=_jpeg()).status_code == 401
    assert client.get("/usuarios/1/foto").status_code == 401


def test_un_usuario_no_ve_ni_toca_la_foto_de_otro(client, auth_headers, admin_headers, db_session):
    from app.models.auth_models import Usuario

    _subir(client, admin_headers, _jpeg())
    admin = db_session.query(Usuario).filter(Usuario.email == "admin@utb.edu.co").one()
    otro = db_session.query(Usuario).filter(Usuario.email == "user2@utb.edu.co").one()
    # Un estudiante no ve la foto de otro (403), el administrador sí (listas de gestión).
    assert client.get(f"/usuarios/{admin.id}/foto", headers=auth_headers).status_code == 403
    assert client.get(f"/usuarios/{admin.id}/foto", headers=admin_headers).status_code == 200
    # Subir/borrar solo actúa sobre la propia: no hay forma de nombrar a otro usuario.
    client.delete("/auth/me/foto", headers=auth_headers)
    db_session.expire_all()
    assert db_session.get(FotoPerfil, admin.id) is not None
    assert db_session.get(FotoPerfil, otro.id) is None


def test_lista_de_usuarios_trae_la_version_de_la_foto(client, admin_headers, auth_headers):
    version = _subir(client, auth_headers, _jpeg()).json()["foto_version"]
    filas = client.get("/usuarios", headers=admin_headers).json()
    fila = next(u for u in filas if u["email"] == "user1@utb.edu.co")
    assert fila["tiene_foto"] is True and fila["foto_version"] == version
    assert next(u for u in filas if u["email"] == "user2@utb.edu.co")["tiene_foto"] is False


def test_limite_de_frecuencia(client, auth_headers, monkeypatch):
    monkeypatch.setattr(config, "FOTO_RATE_LIMIT", 2)
    assert _subir(client, auth_headers, _jpeg()).status_code == 200
    assert _subir(client, auth_headers, _png()).status_code == 200
    r = _subir(client, auth_headers, _jpeg())
    assert r.status_code == 429
    assert "Espera" in r.json()["detail"]


def test_desactivar_cuenta_borra_la_foto(client, auth_headers, db_session):
    _subir(client, auth_headers, _jpeg())
    r = client.post("/auth/me/desactivar", headers=auth_headers, json={"password": "TestPassword1"})
    assert r.status_code == 200, r.text
    db_session.expire_all()
    assert db_session.query(FotoPerfil).count() == 0


def test_administrador_desactiva_y_se_borra_la_foto(client, auth_headers, admin_headers, db_session):
    from app.models.auth_models import Usuario

    _subir(client, auth_headers, _jpeg())
    user = db_session.query(Usuario).filter(Usuario.email == "user1@utb.edu.co").one()
    r = client.patch(f"/usuarios/{user.id}/estado", headers=admin_headers, json={"activo": False})
    assert r.status_code == 200, r.text
    db_session.expire_all()
    assert db_session.get(FotoPerfil, user.id) is None

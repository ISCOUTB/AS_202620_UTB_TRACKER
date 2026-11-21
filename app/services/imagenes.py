"""
Revisión y limpieza de fotos de perfil SIN librerías externas (ADR-0020).

No se decodifica la imagen (no hay Pillow): se recorre su estructura con la biblioteca estándar.

- El tipo se decide por la FIRMA real del contenido, nunca por la extensión ni por el
  Content-Type que declara el cliente.
- JPEG: se recorren los segmentos; se quitan APP1..APP15 (EXIF con GPS, XMP, ICC...) y los
  comentarios. Solo se conserva la orientación del EXIF en un EXIF mínimo nuevo (si no, la foto
  se vería girada). Lo que haya después del fin de imagen (EOI) se descarta.
- PNG: se verifican los CRC y se conservan solo los bloques necesarios para dibujarla; se
  quitan tEXt/zTXt/iTXt/eXIf/tIME y cualquier otro. Lo que haya después de IEND se descarta.

Cualquier estructura rara o truncada se rechaza (ImagenInvalida).
"""
import struct
import zlib
from dataclasses import dataclass

FIRMA_JPEG = b"\xff\xd8\xff"
FIRMA_PNG = b"\x89PNG\r\n\x1a\n"

# Marcadores SOF (tamaño de la imagen). C4 (DHT), C8 (reservado) y CC (DAC) no lo son.
_SOF = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
_SIN_LONGITUD = {0x01, *range(0xD0, 0xD8)}  # TEM y RSTn
_MAX_SEGMENTOS = 500

# Bloques PNG que se conservan (críticos + los que afectan cómo se ven los colores).
_PNG_CONSERVAR = {b"IHDR", b"PLTE", b"IDAT", b"IEND", b"tRNS", b"gAMA", b"cHRM", b"sRGB"}
_MAX_BLOQUES_PNG = 10_000


class ImagenInvalida(ValueError):
    """La imagen está dañada o tiene una estructura que no se acepta."""


class TipoNoPermitido(ValueError):
    """No es JPEG ni PNG (por su contenido real)."""


MIME_JPEG = "image/jpeg"
MIME_PNG = "image/png"
ERR_JPEG_INCOMPLETA = "La foto JPEG está incompleta"
ERR_JPEG_DANADA = "La foto JPEG está dañada"


@dataclass
class ImagenLimpia:
    contenido: bytes
    tipo: str  # "image/jpeg" | "image/png"
    ancho: int
    alto: int


def tipo_por_firma(datos: bytes) -> str | None:
    if datos.startswith(FIRMA_JPEG):
        return MIME_JPEG
    if datos.startswith(FIRMA_PNG):
        return MIME_PNG
    return None


def limpiar(datos: bytes) -> ImagenLimpia:
    tipo = tipo_por_firma(datos)
    if tipo == MIME_JPEG:
        return _limpiar_jpeg(datos)
    if tipo == MIME_PNG:
        return _limpiar_png(datos)
    raise TipoNoPermitido("Solo se aceptan fotos JPEG o PNG")


# --------------------------------------------------------------------------
# JPEG
# --------------------------------------------------------------------------
def _orientacion_exif(cuerpo: bytes) -> int | None:
    """Lee la etiqueta Orientation (0x0112) del IFD0 de un segmento APP1 'Exif'."""
    if not cuerpo.startswith(b"Exif\x00\x00") or len(cuerpo) < 14:
        return None
    tiff = cuerpo[6:]
    orden = {b"II": "<", b"MM": ">"}.get(tiff[:2])
    if orden is None:
        return None
    try:
        (inicio,) = struct.unpack_from(orden + "I", tiff, 4)
        (cantidad,) = struct.unpack_from(orden + "H", tiff, inicio)
        for i in range(min(cantidad, 200)):
            etiqueta, tipo, _, valor = struct.unpack_from(orden + "HHI4s", tiff, inicio + 2 + 12 * i)
            if etiqueta == 0x0112 and tipo == 3:
                (orientacion,) = struct.unpack_from(orden + "H", valor, 0)
                return orientacion if 1 <= orientacion <= 8 else None
    except struct.error:
        return None
    return None


def _app1_solo_orientacion(orientacion: int) -> bytes:
    """EXIF mínimo: cabecera TIFF + IFD0 con UNA etiqueta (Orientation). Nada más."""
    tiff = (b"MM\x00\x2a" + struct.pack(">I", 8) + struct.pack(">H", 1)
            + struct.pack(">HHIHH", 0x0112, 3, 1, orientacion, 0) + struct.pack(">I", 0))
    cuerpo = b"Exif\x00\x00" + tiff
    return b"\xff\xe1" + struct.pack(">H", len(cuerpo) + 2) + cuerpo


_SENTINEL_EOI = -1


def _escanear_datos_jpeg(datos: bytes, pos: int, n: int) -> tuple[bytes, int]:
    """Recorre los datos comprimidos tras un SOS hasta el próximo marcador real."""
    inicio = pos
    while True:
        pos = datos.find(b"\xff", pos)
        if pos < 0 or pos + 1 >= n:
            raise ImagenInvalida(ERR_JPEG_INCOMPLETA)
        siguiente = datos[pos + 1]
        if siguiente == 0x00 or 0xD0 <= siguiente <= 0xD7 or siguiente == 0xFF:
            pos += 1 if siguiente == 0xFF else 2
            continue
        break
    return datos[inicio:pos], pos


def _leer_marcador_jpeg(
    datos: bytes, pos: int, n: int, segmentos: int,
) -> tuple[int, bytes, bytes, int]:
    """Lee el siguiente marcador JPEG y devuelve (marcador, segmento, cuerpo, new_pos).

    Devuelve ``_SENTINEL_EOI`` como marcador si se alcanza EOI.
    """
    if pos + 1 >= n or datos[pos] != 0xFF:
        raise ImagenInvalida(ERR_JPEG_DANADA)
    while pos < n and datos[pos] == 0xFF:  # relleno permitido entre marcadores
        pos += 1
    if pos >= n:
        raise ImagenInvalida(ERR_JPEG_INCOMPLETA)
    marcador = datos[pos]
    pos += 1
    if segmentos + 1 > _MAX_SEGMENTOS:
        raise ImagenInvalida("La foto JPEG tiene una estructura que no se acepta")
    if marcador == 0xD9:
        return _SENTINEL_EOI, b"\xff\xd9", b"", pos
    if marcador in _SIN_LONGITUD:
        return marcador, bytes((0xFF, marcador)), b"", pos
    if pos + 2 > n:
        raise ImagenInvalida(ERR_JPEG_INCOMPLETA)
    (largo,) = struct.unpack_from(">H", datos, pos)
    if largo < 2 or pos + largo > n:
        raise ImagenInvalida(ERR_JPEG_DANADA)
    cuerpo = datos[pos + 2:pos + largo]
    segmento = datos[pos - 2:pos + largo]
    pos += largo
    return marcador, segmento, cuerpo, pos


def _limpiar_jpeg(datos: bytes) -> ImagenLimpia:
    salida = [b"\xff\xd8"]
    pos, n = 2, len(datos)
    ancho = alto = None
    orientacion = None
    en_datos = False  # después de un SOS: datos comprimidos hasta el próximo marcador
    segmentos = 0
    while True:
        if en_datos:
            trozo, pos = _escanear_datos_jpeg(datos, pos, n)
            salida.append(trozo)
            en_datos = False
        marcador, segmento, cuerpo, pos = _leer_marcador_jpeg(datos, pos, n, segmentos)
        segmentos += 1
        if marcador == _SENTINEL_EOI:
            salida.append(segmento)
            break
        if marcador in _SIN_LONGITUD:
            salida.append(segmento)
            continue
        if marcador == 0xE1 and orientacion is None:
            orientacion = _orientacion_exif(cuerpo)
        if 0xE1 <= marcador <= 0xEF or marcador == 0xFE:
            continue  # metadatos y comentarios: fuera
        if marcador in _SOF:
            if len(cuerpo) < 5:
                raise ImagenInvalida(ERR_JPEG_DANADA)
            alto, ancho = struct.unpack_from(">HH", cuerpo, 1)
        if marcador == 0xDA:
            en_datos = True
        salida.append(segmento)
    if not ancho or not alto:
        raise ImagenInvalida("La foto JPEG no indica su tamaño")
    if orientacion and orientacion != 1:
        salida.insert(1, _app1_solo_orientacion(orientacion))
    return ImagenLimpia(b"".join(salida), MIME_JPEG, ancho, alto)


# --------------------------------------------------------------------------
# PNG
# --------------------------------------------------------------------------
def _leer_bloque_png(
    datos: bytes, pos: int, n: int,
) -> tuple[bytes, bytes, bytes, int]:
    """Lee un bloque PNG completo y valida su CRC.

    Devuelve (tipo, contenido, raw_chunk, new_pos).
    """
    if pos + 12 > n:
        raise ImagenInvalida("La foto PNG está incompleta")
    largo, tipo = struct.unpack_from(">I4s", datos, pos)
    fin = pos + 12 + largo
    if fin > n:
        raise ImagenInvalida("La foto PNG está incompleta")
    contenido = datos[pos + 8:pos + 8 + largo]
    (crc,) = struct.unpack_from(">I", datos, pos + 8 + largo)
    if zlib.crc32(tipo + contenido) & 0xFFFFFFFF != crc:
        raise ImagenInvalida("La foto PNG está dañada")
    return tipo, contenido, datos[pos:fin], fin


def _limpiar_png(datos: bytes) -> ImagenLimpia:
    salida = [FIRMA_PNG]
    pos, n = len(FIRMA_PNG), len(datos)
    ancho = alto = None
    bloques = 0
    while True:
        tipo, contenido, raw_chunk, pos = _leer_bloque_png(datos, pos, n)
        if bloques == 0:
            if tipo != b"IHDR" or len(contenido) != 13:
                raise ImagenInvalida("La foto PNG está dañada")
            ancho, alto = struct.unpack_from(">II", contenido, 0)
        bloques += 1
        if bloques > _MAX_BLOQUES_PNG:
            raise ImagenInvalida("La foto PNG tiene una estructura que no se acepta")
        if tipo in _PNG_CONSERVAR:
            salida.append(raw_chunk)
        if tipo == b"IEND":
            break  # lo que siga se descarta
    if not ancho or not alto:
        raise ImagenInvalida("La foto PNG no indica su tamaño")
    return ImagenLimpia(b"".join(salida), "image/png", ancho, alto)

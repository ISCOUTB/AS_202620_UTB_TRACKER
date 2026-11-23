"""
Utilidades HTTP de la foto de perfil (ADR-0020), compartidas por los routers `auth` (la propia)
y `usuarios` (la de otra persona). Sin endpoints propios.
"""
from fastapi import HTTPException, Request, Response, status

from app.config import config
from app.service import fotos


async def leer_cuerpo_limitado(request: Request) -> bytes:
    """Lee el cuerpo SIN pasar del máximo: corta apenas se excede (413), aunque el cliente
    mienta en Content-Length o no lo envíe. Así no hace falta python-multipart."""
    maximo = config.FOTO_MAX_BYTES
    declarado = request.headers.get("content-length", "")
    if declarado.isdigit() and int(declarado) > maximo:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                            detail=fotos.mensaje_muy_grande())
    partes, total = [], 0
    async for trozo in request.stream():
        total += len(trozo)
        if total > maximo:
            raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                                detail=fotos.mensaje_muy_grande())
        partes.append(trozo)
    return b"".join(partes)


def respuesta_foto(foto) -> Response:  # FotoPerfil (de services.fotos)
    """Los bytes con su tipo real. La app pide ?v=<versión>: una versión nueva es otra URL,
    así que la copia en caché (privada, nunca en proxies) puede durar."""
    return Response(
        content=foto.contenido,
        media_type=foto.tipo,
        headers={
            "Cache-Control": "private, max-age=86400",
            "ETag": f'"{foto.version}"',
            "X-Content-Type-Options": "nosniff",
            "Content-Security-Policy": "default-src 'none'",
            "Content-Disposition": "inline",
        },
    )

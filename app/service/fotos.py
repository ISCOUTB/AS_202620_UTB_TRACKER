"""
Foto de perfil (ADR-0020): subir, reemplazar, quitar y ver.

El servidor nunca confía en el cliente: tamaño máximo estricto, tipo por la firma real (solo
JPEG y PNG), dimensiones de miniatura, metadatos quitados (app/service/imagenes.py) y límite
de subidas por usuario. En la bitácora queda la acción, nunca el contenido.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import config
from app.middleware import permisos
from app.models.auth_models import FotoPerfil, Usuario
from app.service import auditoria, imagenes, limites

MSG_MUY_GRANDE = "La foto es demasiado grande (máximo {kb} KB). Elige otra o recórtala."
MSG_TIPO = "Solo se aceptan fotos JPEG o PNG."
MSG_DIMENSIONES = "La foto debe medir entre {minimo} y {maximo} píxeles por lado."
MSG_LIMITE = "Cambiaste la foto muchas veces. Espera un rato antes de volver a intentarlo."
MSG_SIN_FOTO = "No hay foto de perfil."
MSG_NO_PERMITIDO = "No tienes permiso para ver la foto de otra persona."


def mensaje_muy_grande() -> str:
    return MSG_MUY_GRANDE.format(kb=config.FOTO_MAX_BYTES // 1024)


def _ahora() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def version_de(db: Session, usuario_id: int) -> Optional[int]:
    """Versión de la foto (sin leer los bytes) o None si no tiene."""
    return db.query(FotoPerfil.version).filter(FotoPerfil.usuario_id == usuario_id).scalar()


def guardar(db: Session, user: Usuario, datos: bytes) -> FotoPerfil:
    if len(datos) > config.FOTO_MAX_BYTES:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                            detail=mensaje_muy_grande())
    if not datos:
        raise HTTPException(status_code=422, detail="No llegó ninguna foto.")
    clave = f"foto:{user.id}"
    limites.exigir(db, clave, config.FOTO_RATE_LIMIT, config.FOTO_RATE_WINDOW_SECONDS, MSG_LIMITE)
    try:
        limpia = imagenes.limpiar(datos)
    except imagenes.TipoNoPermitido as exc:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                            detail=MSG_TIPO) from exc
    except imagenes.ImagenInvalida as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    lados = (limpia.ancho, limpia.alto)
    if min(lados) < config.FOTO_LADO_MINIMO or max(lados) > config.FOTO_LADO_MAXIMO:
        raise HTTPException(status_code=422, detail=MSG_DIMENSIONES.format(
            minimo=config.FOTO_LADO_MINIMO, maximo=config.FOTO_LADO_MAXIMO))

    ahora = _ahora()
    foto = db.get(FotoPerfil, user.id) or FotoPerfil(usuario_id=user.id)
    anterior = foto.version or 0
    foto.contenido = limpia.contenido
    foto.tipo = limpia.tipo
    foto.tamano = len(limpia.contenido)
    foto.ancho, foto.alto = limpia.ancho, limpia.alto
    # Siempre crece, aunque dos subidas caigan en el mismo milisegundo.
    foto.version = max(int(ahora.replace(tzinfo=timezone.utc).timestamp() * 1000), anterior + 1)
    foto.actualizado_en = ahora
    db.add(foto)
    limites.anotar(db, clave)
    auditoria.registrar(db, "usuario.foto_actualizada", "usuario", user.id, actor_id=user.id,
                        detalle={"tipo": foto.tipo, "tamano": foto.tamano,
                                 "ancho": foto.ancho, "alto": foto.alto})
    db.commit()
    db.refresh(foto)
    return foto


def borrar_contenido(db: Session, usuario_id: int) -> bool:
    """Borra la fila (y con ella los bytes). Sin commit. True si había foto."""
    return db.query(FotoPerfil).filter(FotoPerfil.usuario_id == usuario_id).delete(
        synchronize_session=False) > 0


def quitar(db: Session, user: Usuario) -> None:
    if borrar_contenido(db, user.id):
        auditoria.registrar(db, "usuario.foto_eliminada", "usuario", user.id, actor_id=user.id)
    db.commit()


def obtener(db: Session, usuario_id: int, solicitante: Usuario) -> FotoPerfil:
    """La propia siempre; la de otra persona solo con `usuarios.ver` (auditor y administrador,
    para las listas donde aparece quien pide o reporta). Nunca pública."""
    if usuario_id != solicitante.id and not permisos.tiene(
        solicitante.rol, permisos.Permiso.USUARIOS_VER
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=MSG_NO_PERMITIDO)
    foto = db.get(FotoPerfil, usuario_id)
    if foto is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MSG_SIN_FOTO)
    return foto

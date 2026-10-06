from sqlalchemy.orm import Session
from app.core.security import create_access_token
from app.schemas.auth import UsuarioCreate, UsuarioLogin
from app.models.auth_models import Usuario
from fastapi import HTTPException, status


def create_user(db: Session, schema: UsuarioCreate):
    user_exists = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if user_exists is False:
        try: 
            new_user = Usuario(nombre=schema.nombre)
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            return new_user
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
        
def login(db: Session, schema: UsuarioLogin):
    user = db.query(Usuario).filter(Usuario.nombre == schema.nombre).first()
    if user is None or user.password != schema.password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nombre de usuario o contraseña incorrectos")
    else:
        token = create_access_token({"sub": user.correo})
        return {"access_token": token, "token_type": "bearer"}
    
def delete_user(db: Session, user_id: int):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    else:
        try:
            db.delete(user)
            db.commit()
            return {"message": "Usuario eliminado correctamente"}
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

def get_user_by_id(db: Session, user_id: int):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return user

def logout(db: Session, user_id: int):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    else:
        return {"message": "Cierre de sesión exitoso"}
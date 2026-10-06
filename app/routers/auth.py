from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from  app.services.auth import login, create_user, delete_user, get_user_by_id, logout
from app.core.database import get_db
from app.schemas.auth import UsuarioCreate, TokenResponse, UsuarioLogin, UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])
    
@router.post("/login", response_model=TokenResponse)
def login(user: UsuarioLogin, db: Session = Depends(get_db)):
    return login(db, user)
        
@router.post("/register", response_model=UserResponse)
def  register(user: UsuarioCreate, db: Session = Depends(get_db)):
    return create_user(db, user)

@router.delete("/delete/{user_id}")
def delete_user_endpoint(user_id: int, db: Session = Depends(get_db)):
    return delete_user(db, user_id)

@router.get("/user/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    return get_user_by_id(db, user_id)

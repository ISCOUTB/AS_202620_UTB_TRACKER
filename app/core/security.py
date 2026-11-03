from datetime import datetime, timedelta, timezone

import jwt

from app.core.config import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM,
    FORGET_PWD_SECRET_KEY,
    REFRESH_TOKEN_EXPIRE_DAYS,
    SECRET_KEY,
)


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type", "access") != "access":
            return None
        return payload.get("sub")
    except jwt.PyJWTError:
        return None


def verify_refresh_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            return None
        return payload.get("sub")
    except jwt.PyJWTError:
        return None


def create_reset_password_token(email: str):
    data = {"sub": email, "exp": datetime.now(timezone.utc) + timedelta(minutes=10)}
    return jwt.encode(data, FORGET_PWD_SECRET_KEY, algorithm=ALGORITHM)


def verify_reset_password_token(token: str):
    try:
        payload = jwt.decode(token, FORGET_PWD_SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except jwt.PyJWTError:
        return None
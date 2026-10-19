import os

from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./utb_tracker.db")
SECRET_KEY = os.getenv("SECRET_KEY", "utb_tracker_jwt_secret_key_default_2026")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
FORGET_PWD_SECRET_KEY = os.getenv(
    "FORGET_PWD_SECRET_KEY", "utb_forget_pwd_secret_default_2026"
)

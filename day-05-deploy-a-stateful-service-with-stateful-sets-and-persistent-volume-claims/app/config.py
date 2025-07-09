from pydantic_settings import BaseSettings
from dotenv import load_dotenv
import os


load_dotenv()


user = os.getenv("DB_USERNAME")
password = os.getenv("DB_PASSWORD")


class Settings(BaseSettings):
    sqlalchemy_string: str = f"postgresql://{user}:{password}@host/chingae"
    
settings = Settings()
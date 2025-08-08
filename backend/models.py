from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"

    phone_number = Column(String, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

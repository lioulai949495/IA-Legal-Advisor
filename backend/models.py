from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"

    phone_number = Column(String, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Case(Base):
    __tablename__ = "cases"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, index=True)  # 对应 phone_number
    title = Column(String)
    description = Column(String)
    case_type = Column(String)
    status = Column(String, default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class Document(Base):
    __tablename__ = "documents"

    id = Column(String, primary_key=True, index=True)
    case_id = Column(String, index=True)
    filename = Column(String)
    file_url = Column(String)
    file_type = Column(String)
    file_size = Column(String)
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())

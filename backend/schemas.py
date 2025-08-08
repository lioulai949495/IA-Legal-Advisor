from pydantic import BaseModel
from typing import Optional

class PhoneRequest(BaseModel):
    phone_number: str

class LoginRequest(BaseModel):
    phone_number: str
    code: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UserProfileResponse(BaseModel):
    id: str
    username: str | None = None
    email: str | None = None
    phone_number: str | None = None
    created_at: str
    membership_level: str | None = None
    membership_expiry: str | None = None

class CreateCaseRequest(BaseModel):
    title: str
    description: str
    case_type: str

class UpdateCaseRequest(BaseModel):
    title: str | None = None
    description: str | None = None

class CaseResponse(BaseModel):
    id: str
    title: str
    description: str
    case_type: str
    status: str
    created_at: str
    updated_at: str
    user_id: str

class DocumentResponse(BaseModel):
    id: str
    case_id: str
    filename: str
    file_url: str
    file_type: str
    file_size: int | None = None
    uploaded_at: str

# 用于获取子类型和聊天的请求体
class ChatRequest(BaseModel):
    category: str
    role: Optional[str] = None
    subtype: Optional[str] = None
    message: Optional[str] = None # 用于最终的自由对话

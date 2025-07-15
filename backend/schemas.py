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

# 用于获取子类型和聊天的请求体
class ChatRequest(BaseModel):
    category: str
    role: Optional[str] = None
    subtype: Optional[str] = None
    message: Optional[str] = None # 用于最终的自由对话

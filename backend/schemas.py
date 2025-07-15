from pydantic import BaseModel

class PhoneRequest(BaseModel):
    phone_number: str

class LoginRequest(BaseModel):
    phone_number: str
    code: str

class Token(BaseModel):
    access_token: str
    token_type: str

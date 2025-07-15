from fastapi import FastAPI, Depends, HTTPException, Header
from sqlalchemy.orm import Session
import random

import models
import schemas
import ai_services
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

verification_codes = {}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def verify_token(x_token: str = Header(None)):
    if not x_token or not x_token.startswith("fake-token-for-"):
        raise HTTPException(status_code=401, detail="Invalid or missing token")
    return x_token

@app.get("/")
def read_root():
    return {"message": "IA法律顾问后端服务 v1.1 已成功启动！数据库已连接。"}

@app.post("/send-code")
def send_verification_code(request: schemas.PhoneRequest):
    # ... (此部分代码不变)
    phone_number = request.phone_number
    code = str(random.randint(100000, 999999))
    verification_codes[phone_number] = code
    print(f"发送验证码到 {phone_number}: {code}")
    return {"message": f"验证码已发送到 {phone_number}"}

@app.post("/login", response_model=schemas.Token)
def login(request: schemas.LoginRequest, db: Session = Depends(get_db)):
    # ... (此部分代码不变)
    phone_number = request.phone_number
    code = request.code
    if verification_codes.get(phone_number) != code:
        raise HTTPException(status_code=400, detail="验证码错误")
    if phone_number in verification_codes:
        del verification_codes[phone_number]
    db_user = db.query(models.User).filter(models.User.phone_number == phone_number).first()
    if not db_user:
        db_user = models.User(phone_number=phone_number)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
    access_token = f"fake-token-for-{phone_number}"
    return {"access_token": access_token, "token_type": "bearer"}

# --- 新的引导式对话流程 ---

@app.post("/start-chat")
def start_chat(token: str = Depends(verify_token)):
    return ai_services.get_initial_categories()

@app.post("/get-roles")
def get_roles(request: schemas.ChatRequest, token: str = Depends(verify_token)):
    return ai_services.get_roles_for_category(request.category)

@app.post("/get-subtypes")
def get_subtypes(request: schemas.ChatRequest, token: str = Depends(verify_token)):
    if not request.role:
        raise HTTPException(status_code=400, detail="Role is required")
    return ai_services.get_subtypes_for_role(request.category, request.role)

@app.post("/chat")
def chat_with_ai(request: schemas.ChatRequest, token: str = Depends(verify_token)):
    if not all([request.category, request.role, request.subtype, request.message]):
        raise HTTPException(status_code=400, detail="Category, role, subtype, and message are required for a full analysis")
    return ai_services.get_ai_response(request.category, request.role, request.subtype, request.message)

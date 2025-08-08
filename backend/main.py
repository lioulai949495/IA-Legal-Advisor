from fastapi import FastAPI, Depends, HTTPException, Header
from sqlalchemy.orm import Session
import random
import time

import models
import schemas
import ai_services
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

start_time = time.time()
verification_codes = {}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def verify_token(x_token: str = Header(None), authorization: str = Header(None)):
    token = None
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization[7:].strip()
    elif x_token:
        token = x_token

    if not token or not token.startswith("fake-token-for-"):
        raise HTTPException(status_code=401, detail="Invalid or missing token")
    return token

@app.get("/")
def read_root():
    return {"message": "IA法律顾问后端服务 v1.1 已成功启动！数据库已连接。"}

@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "ia-backend",
        "version": "1.1",
        "uptime_seconds": int(time.time() - start_time)
    }

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
    # 开发期通用测试验证码 000000，同时保留原有校验
    if verification_codes.get(phone_number) != code and code != "000000":
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
    try:
        if not all([request.category, request.role, request.subtype, request.message]):
            raise HTTPException(status_code=400, detail="category, role, subtype, message are required")
        result = ai_services.get_ai_response(
            category=request.category,
            role=request.role,
            subtype=request.subtype,
            message=request.message,
        )
        return result
    except HTTPException:
        raise
    except Exception as e:
        print(f"/chat error: {e}")
        raise HTTPException(status_code=500, detail="AI service error")

@app.get("/profile", response_model=schemas.UserProfileResponse)
def get_profile(token: str = Depends(verify_token)):
    # token: fake-token-for-<phone>
    phone = token.replace("fake-token-for-", "")
    return {
        "id": phone,
        "username": "用户" + phone[-4:],
        "email": f"{phone}@temp.com",
        "phone_number": phone,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "membership_level": "basic",
        "membership_expiry": None,
    }


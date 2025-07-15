from fastapi import FastAPI, Depends, HTTPException, Header
from sqlalchemy.orm import Session
import random

import models
import schemas
import ai_services # 导入AI服务
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# 模拟一个地方来存储手机号和验证码的对应关系
verification_codes = {}

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 模拟的Token验证依赖
async def verify_token(x_token: str = Header(None)):
    if not x_token or not x_token.startswith("fake-token-for-"):
        raise HTTPException(status_code=401, detail="Invalid or missing token")
    return x_token

@app.get("/")
def read_root():
    return {"message": "IA法律顾问后端服务 v1.1 已成功启动！数据库已连接。"}

@app.post("/send-code")
def send_verification_code(request: schemas.PhoneRequest):
    phone_number = request.phone_number
    code = str(random.randint(100000, 999999))
    verification_codes[phone_number] = code
    print(f"发送验证码到 {phone_number}: {code}")
    return {"message": f"验证码已发送到 {phone_number}"}

@app.post("/login", response_model=schemas.Token)
def login(request: schemas.LoginRequest, db: Session = Depends(get_db)):
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
        print(f"新用户注册成功: {phone_number}")
    else:
        print(f"用户登录成功: {phone_number}")
    access_token = f"fake-token-for-{phone_number}"
    return {"access_token": access_token, "token_type": "bearer"}

# 新增的开始聊天接口
@app.post("/start-chat")
def start_chat(token: str = Depends(verify_token)):
    return ai_services.get_initial_prompt()

# 修改后的聊天接口
@app.post("/chat")
def chat_with_ai(request: schemas.PhoneRequest, token: str = Depends(verify_token)):
    user_selection = request.phone_number # 复用PhoneRequest模型，这里其实是用户的选项文本
    ai_response = ai_services.get_ai_response(user_selection)
    return ai_response

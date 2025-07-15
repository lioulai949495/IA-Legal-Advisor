from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
import random

import models
import schemas
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

@app.get("/")
def read_root():
    return {"message": "IA法律顾问后端服务已成功启动！数据库已连接。"}

@app.post("/send-code")
def send_verification_code(request: schemas.PhoneRequest):
    """
    接收手机号，生成一个6位数的验证码，并模拟发送。
    在真实世界中，这里会调用一个短信服务API。
    """
    phone_number = request.phone_number
    # 生成一个100000到999999之间的随机数作为验证码
    code = str(random.randint(100000, 999999))
    
    # 存储验证码（在真实应用中，这应该有时效性，比如存入Redis）
    verification_codes[phone_number] = code
    
    # **重要**: 在后台打印验证码，方便我们测试
    print(f"发送验证码到 {phone_number}: {code}")
    
    return {"message": f"验证码已发送到 {phone_number}"}

@app.post("/login", response_model=schemas.Token)
def login(request: schemas.LoginRequest, db: Session = Depends(get_db)):
    """
    接收手机号和验证码，进行登录或注册。
    """
    phone_number = request.phone_number
    code = request.code
    
    # 检查验证码是否正确
    if verification_codes.get(phone_number) != code:
        raise HTTPException(status_code=400, detail="验证码错误")
    
    # 验证成功后，可以删除已使用的验证码
    if phone_number in verification_codes:
        del verification_codes[phone_number]
        
    # 检查用户是否已存在
    db_user = db.query(models.User).filter(models.User.phone_number == phone_number).first()
    
    # 如果用户不存在，则创建新用户
    if not db_user:
        db_user = models.User(phone_number=phone_number)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        print(f"新用户注册成功: {phone_number}")
    else:
        print(f"用户登录成功: {phone_number}")

    # 在真实应用中，这里会生成一个JWT (JSON Web Token) 作为访问令牌
    # 为了简化，我们暂时返回一个固定的模拟token
    access_token = f"fake-token-for-{phone_number}"
    return {"access_token": access_token, "token_type": "bearer"}

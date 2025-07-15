from fastapi import FastAPI
from .database import engine, Base
from . import models

# 在应用启动时，根据我们的模型创建数据库表
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "IA法律顾问后端服务已成功启动！数据库已连接。"}

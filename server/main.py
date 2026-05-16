import os
from datetime import datetime, timezone
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

import database as db

app = FastAPI(title="Emotion Test API")

# ==================== AI Service Config ====================
# 从环境变量读取 AI 服务配置，未设置时使用默认值
AI_CONFIG = {
    "deepseek": {
        "apiKey": os.getenv("DEEPSEEK_API_KEY", ""),
        "baseUrl": os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com"),
        "model": os.getenv("DEEPSEEK_MODEL", "deepseek-v4-flash"),
    },
    "kimi": {
        "apiKey": os.getenv("KIMI_API_KEY", ""),
        "baseUrl": os.getenv("KIMI_BASE_URL", "https://api.moonshot.cn/v1"),
        "model": os.getenv("KIMI_MODEL", "kimi-k2.6"),
    },
    "xfyun": {
        "appId": os.getenv("XFYUN_APP_ID", ""),
        "apiKey": os.getenv("XFYUN_API_KEY", ""),
        "apiSecret": os.getenv("XFYUN_API_SECRET", ""),
    },
}


@app.on_event("startup")
def startup():
    db.init_db()


# ==================== Schemas ====================

class UserInfoIn(BaseModel):
    uid: str
    basicInfo: str = ""
    detailedInfo: str = ""
    passingScore: Optional[int] = None


class SurveyIn(BaseModel):
    uid: str
    questionsJson: str
    createdAt: Optional[str] = None
    creatorBasicInfo: str = ""


class EventIn(BaseModel):
    answererUid: str
    creatorUid: str
    totalScore: int
    submitTime: Optional[str] = None


# ==================== User endpoints ====================

@app.get("/users")
def list_users():
    return db.get_all_user_info()


@app.get("/users/{uid}")
def get_user(uid: str):
    row = db.get_user_info(uid)
    if row is None:
        raise HTTPException(status_code=404, detail="User not found")
    return row


@app.put("/users/{uid}")
def save_user(uid: str, body: UserInfoIn):
    db.save_user_info(uid, body.basicInfo, body.detailedInfo, body.passingScore)
    return {"uid": uid}


# ==================== Survey endpoints ====================

@app.get("/surveys")
def list_surveys():
    return db.get_all_surveys()


@app.get("/surveys/{uid}")
def get_survey(uid: str):
    row = db.get_survey_by_uid(uid)
    if row is None:
        raise HTTPException(status_code=404, detail="Survey not found")
    return row


@app.post("/surveys")
def save_survey(body: SurveyIn):
    survey_id = db.save_survey(
        uid=body.uid,
        questions_json=body.questionsJson,
        created_at=body.createdAt,
        creator_basic_info=body.creatorBasicInfo,
    )
    return {"id": survey_id, "uid": body.uid}


@app.delete("/surveys")
def delete_all_surveys():
    db.delete_all_surveys()
    return {"deleted": "all"}


@app.delete("/surveys/{uid}")
def delete_survey(uid: str):
    db.delete_survey_by_uid(uid)
    return {"deleted": uid}


# ==================== Event endpoints ====================

@app.post("/events")
def save_event(body: EventIn):
    submit_time = body.submitTime or datetime.now(timezone.utc).isoformat()
    db.save_event(body.answererUid, body.creatorUid, body.totalScore, submit_time)
    return {"answererUid": body.answererUid, "creatorUid": body.creatorUid}


@app.get("/events")
def list_events():
    return db.get_all_events()


@app.get("/events/answerer/{answerer_uid}/latest")
def get_latest_event(answerer_uid: str):
    row = db.get_latest_event(answerer_uid)
    if row is None:
        raise HTTPException(status_code=404, detail="No events found")
    return row


@app.get("/events/answerer/{answerer_uid}/creator/{creator_uid}")
def get_events_by_both(answerer_uid: str, creator_uid: str):
    return db.get_events_by_answerer_and_creator(answerer_uid, creator_uid)


@app.get("/events/answerer/{answerer_uid}")
def get_events_by_answerer(answerer_uid: str):
    return db.get_events_by_answerer(answerer_uid)


@app.get("/events/creator/{creator_uid}")
def get_events_by_creator(creator_uid: str):
    return db.get_events_by_creator(creator_uid)


@app.delete("/events")
def delete_all_events():
    db.delete_all_events()
    return {"deleted": "all"}


@app.delete("/events/answerer/{answerer_uid}")
def delete_events_by_answerer(answerer_uid: str):
    db.delete_events_by_answerer(answerer_uid)
    return {"deleted": answerer_uid}


@app.delete("/events/creator/{creator_uid}")
def delete_events_by_creator(creator_uid: str):
    db.delete_events_by_creator(creator_uid)
    return {"deleted": creator_uid}


# ==================== Config endpoint ====================

@app.get("/config")
def get_config():
    """返回 AI 服务配置（供客户端使用）"""
    return AI_CONFIG

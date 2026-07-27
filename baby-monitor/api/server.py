"""FastAPI 后端 - 为移动端提供行为分析 API"""

from __future__ import annotations

import base64
import importlib.util
import sys
import tempfile
from contextlib import asynccontextmanager
from pathlib import Path

import cv2
import numpy as np
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

_spec = importlib.util.spec_from_file_location("pipeline", _ROOT / "Pipeline" / "0_pipeline.py")
_pipeline_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_pipeline_mod)
BabyMonitorPipeline = _pipeline_mod.BabyMonitorPipeline

from config import BEHAVIOR_LABELS

_pipeline: BabyMonitorPipeline | None = None


@asynccontextmanager
async def lifespan(_app: FastAPI):
    global _pipeline
    _pipeline = BabyMonitorPipeline()
    yield
    if _pipeline:
        _pipeline.close()
        _pipeline = None


app = FastAPI(
    title="宝宝智能监控 API",
    description="为 Android / iOS / 鸿蒙 客户端提供宝宝行为分析服务",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AnalyzeResult(BaseModel):
    behavior: str
    behavior_cn: str
    confidence: float
    alert: bool
    alert_message: str
    movement: float
    torso_angle: float
    annotated_image_b64: str | None = None


class VideoSummary(BaseModel):
    frames_processed: int
    dominant_behavior: str
    distribution: dict[str, float]
    alert_count: int
    last_behavior: str


class HealthResponse(BaseModel):
    status: str
    version: str
    supported_behaviors: dict[str, str]


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(
        status="ok",
        version="1.0.0",
        supported_behaviors=BEHAVIOR_LABELS,
    )


@app.post("/api/v1/analyze/image", response_model=AnalyzeResult)
async def analyze_image(
    file: UploadFile = File(...),
    return_image: bool = Form(default=True),
):
    """分析单张图片，返回行为识别结果"""
    data = await file.read()
    arr = np.frombuffer(data, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame is None:
        return JSONResponse(status_code=400, content={"detail": "无法解析图片"})

    _pipeline.reset()
    result = _pipeline.process_frame(frame)

    annotated_b64 = None
    if return_image:
        _, buf = cv2.imencode(".jpg", result["frame"], [cv2.IMWRITE_JPEG_QUALITY, 85])
        annotated_b64 = base64.b64encode(buf).decode("utf-8")

    return AnalyzeResult(
        behavior=result["behavior"],
        behavior_cn=result["behavior_cn"],
        confidence=result["confidence"],
        alert=result["alert"],
        alert_message=result["alert_message"],
        movement=result["movement"],
        torso_angle=result["torso_angle"],
        annotated_image_b64=annotated_b64,
    )


@app.post("/api/v1/analyze/video", response_model=VideoSummary)
async def analyze_video(
    file: UploadFile = File(...),
    max_frames: int = Form(default=150),
):
    """分析视频文件，返回行为统计摘要"""
    suffix = Path(file.filename or "video.mp4").suffix or ".mp4"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    try:
        report = _pipeline.process_video(tmp_path, max_frames=max_frames, save_output=False)
        summary = report["summary"]
        return VideoSummary(
            frames_processed=report["frames_processed"],
            dominant_behavior=summary.get("dominant", "未知"),
            distribution=summary.get("distribution", {}),
            alert_count=summary.get("alerts", 0),
            last_behavior=report["last_behavior"],
        )
    finally:
        Path(tmp_path).unlink(missing_ok=True)


class FrameRequest(BaseModel):
    image_b64: str = Field(..., description="Base64 编码的 JPEG 图片")
    timestamp: float = 0.0


@app.post("/api/v1/analyze/frame", response_model=AnalyzeResult)
def analyze_frame(req: FrameRequest):
    """分析 Base64 编码的单帧（适合实时摄像头流）"""
    try:
        raw = base64.b64decode(req.image_b64)
    except Exception:
        return JSONResponse(status_code=400, content={"detail": "Base64 解码失败"})

    arr = np.frombuffer(raw, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame is None:
        return JSONResponse(status_code=400, content={"detail": "无法解析图片"})

    result = _pipeline.process_frame(frame, req.timestamp)
    return AnalyzeResult(
        behavior=result["behavior"],
        behavior_cn=result["behavior_cn"],
        confidence=result["confidence"],
        alert=result["alert"],
        alert_message=result["alert_message"],
        movement=result["movement"],
        torso_angle=result["torso_angle"],
    )

"""行为定义与基于姿态的规则分类器"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum

import numpy as np

from config import (
    CRAWL_ANGLE_THRESHOLD,
    FALL_VELOCITY_THRESHOLD,
    MOVEMENT_THRESHOLD,
    STAND_ANGLE_THRESHOLD,
    STILL_FRAMES_FOR_SLEEP,
)


class BehaviorType(str, Enum):
    SLEEPING = "sleeping"
    LYING = "lying"
    CRAWLING = "crawling"
    SITTING = "sitting"
    STANDING = "standing"
    PLAYING = "playing"
    FALLING = "falling"
    UNATTENDED = "unattended"
    UNKNOWN = "unknown"


@dataclass
class PoseFrame:
    """单帧姿态数据"""

    landmarks: np.ndarray | None  # shape (33, 3) -> x, y, visibility
    timestamp: float = 0.0
    movement_score: float = 0.0
    torso_angle: float = 0.0
    center_y: float = 0.0


@dataclass
class BehaviorState:
    """跨帧行为状态追踪"""

    current: BehaviorType = BehaviorType.UNKNOWN
    confidence: float = 0.0
    still_counter: int = 0
    prev_center_y: float | None = None
    history: list[BehaviorType] = field(default_factory=list)
    alert: bool = False
    alert_message: str = ""


# MediaPipe Pose 关键点索引
LM = {
    "nose": 0,
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_hip": 23,
    "right_hip": 24,
    "left_knee": 25,
    "right_knee": 26,
}


def _visible_point(landmarks: np.ndarray, idx: int) -> tuple[float, float] | None:
    x, y, vis = landmarks[idx]
    if vis < 0.5:
        return None
    return float(x), float(y)


def compute_torso_angle(landmarks: np.ndarray) -> float:
    """计算躯干与水平面的夹角（度）"""
    ls = _visible_point(landmarks, LM["left_shoulder"])
    rs = _visible_point(landmarks, LM["right_shoulder"])
    lh = _visible_point(landmarks, LM["left_hip"])
    rh = _visible_point(landmarks, LM["right_hip"])

    points = [p for p in (ls, rs, lh, rh) if p is not None]
    if len(points) < 2:
        return 0.0

    shoulder_y = np.mean([p[1] for p in (ls, rs) if p is not None]) if (ls or rs) else points[0][1]
    hip_y = np.mean([p[1] for p in (lh, rh) if p is not None]) if (lh or rh) else points[-1][1]
    shoulder_x = np.mean([p[0] for p in (ls, rs) if p is not None]) if (ls or rs) else points[0][0]
    hip_x = np.mean([p[0] for p in (lh, rh) if p is not None]) if (lh or rh) else points[-1][0]

    dx = abs(shoulder_x - hip_x)
    dy = abs(shoulder_y - hip_y)
    if dx + dy < 1e-6:
        return 0.0
    return math.degrees(math.atan2(dy, dx))


def compute_center_y(landmarks: np.ndarray) -> float:
    """躯干中心 Y 坐标（归一化）"""
    vals = []
    for idx in (LM["left_shoulder"], LM["right_shoulder"], LM["left_hip"], LM["right_hip"]):
        pt = _visible_point(landmarks, idx)
        if pt:
            vals.append(pt[1])
    return float(np.mean(vals)) if vals else 0.5


def compute_movement(prev: np.ndarray | None, curr: np.ndarray) -> float:
    """计算相邻帧关键点平均位移"""
    if prev is None:
        return 0.0
    n = min(len(prev), len(curr))
    diffs = []
    for i in range(n):
        if prev[i, 2] > 0.5 and curr[i, 2] > 0.5:
            diffs.append(math.hypot(curr[i, 0] - prev[i, 0], curr[i, 1] - prev[i, 1]))
    return float(np.mean(diffs)) if diffs else 0.0


def classify_behavior(
    pose: PoseFrame,
    state: BehaviorState,
    person_detected: bool,
) -> BehaviorState:
    """根据姿态特征与历史状态判定行为"""
    state.alert = False
    state.alert_message = ""

    if not person_detected or pose.landmarks is None:
        state.current = BehaviorType.UNATTENDED
        state.confidence = 0.9
        state.alert = True
        state.alert_message = "未检测到宝宝，请确认监护状态"
        return state

    angle = pose.torso_angle
    movement = pose.movement_score

    # 跌倒检测：躯干中心突然下移
    if state.prev_center_y is not None:
        drop = pose.center_y - state.prev_center_y
        if drop > FALL_VELOCITY_THRESHOLD and angle < STAND_ANGLE_THRESHOLD:
            state.current = BehaviorType.FALLING
            state.confidence = 0.85
            state.alert = True
            state.alert_message = "检测到疑似跌倒，请立即查看！"
            state.prev_center_y = pose.center_y
            state.history.append(state.current)
            return state

    state.prev_center_y = pose.center_y

    # 静止计数（睡眠判定）
    if movement < MOVEMENT_THRESHOLD:
        state.still_counter += 1
    else:
        state.still_counter = 0

    if state.still_counter >= STILL_FRAMES_FOR_SLEEP and angle < CRAWL_ANGLE_THRESHOLD:
        state.current = BehaviorType.SLEEPING
        state.confidence = min(0.95, 0.6 + state.still_counter * 0.01)
    elif angle < CRAWL_ANGLE_THRESHOLD:
        if movement > MOVEMENT_THRESHOLD:
            state.current = BehaviorType.CRAWLING
            state.confidence = 0.75
        else:
            state.current = BehaviorType.LYING
            state.confidence = 0.7
    elif angle < STAND_ANGLE_THRESHOLD:
        state.current = BehaviorType.SITTING
        state.confidence = 0.72
    else:
        if movement > MOVEMENT_THRESHOLD * 1.5:
            state.current = BehaviorType.PLAYING
            state.confidence = 0.78
        else:
            state.current = BehaviorType.STANDING
            state.confidence = 0.7

    state.history.append(state.current)
    if len(state.history) > 120:
        state.history = state.history[-120:]

    return state

"""Step 4: 行为分类与可视化"""

from __future__ import annotations

import cv2
import numpy as np

from config import ALERT_BEHAVIORS, BEHAVIOR_LABELS
from models.behaviors import BehaviorState, BehaviorType, PoseFrame, classify_behavior


def analyze_frame(
    frame: np.ndarray,
    pose: PoseFrame,
    state: BehaviorState,
    person_detected: bool,
    bbox: tuple[int, int, int, int] | None = None,
) -> tuple[BehaviorState, np.ndarray]:
    """对单帧进行行为分类并绘制标注"""
    state = classify_behavior(pose, state, person_detected)
    annotated = draw_overlay(frame, state, pose, bbox)
    return state, annotated


def draw_overlay(
    frame: np.ndarray,
    state: BehaviorState,
    pose: PoseFrame,
    bbox: tuple[int, int, int, int] | None = None,
) -> np.ndarray:
    """在画面上绘制行为标签与告警信息"""
    out = frame.copy()
    h, w = out.shape[:2]

    label_cn = BEHAVIOR_LABELS.get(state.current.value, "未知")
    conf = state.confidence
    color = (0, 0, 255) if state.current.value in ALERT_BEHAVIORS else (0, 200, 0)

    if bbox:
        x, y, bw, bh = bbox
        cv2.rectangle(out, (x, y), (x + bw, y + bh), color, 2)

    # 顶部信息栏
    cv2.rectangle(out, (0, 0), (w, 80), (0, 0, 0), -1)
    cv2.putText(out, f"行为: {label_cn}", (12, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.9, color, 2)
    cv2.putText(
        out,
        f"置信度: {conf:.0%}  |  活动度: {pose.movement_score:.3f}  |  躯干角: {pose.torso_angle:.0f}°",
        (12, 62),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.55,
        (220, 220, 220),
        1,
    )

    if state.alert and state.alert_message:
        cv2.rectangle(out, (0, h - 50), (w, h), (0, 0, 180), -1)
        cv2.putText(out, state.alert_message, (12, h - 16), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

    return out


def summarize_session(state: BehaviorState) -> dict:
    """汇总一次分析会话的行为统计"""
    if not state.history:
        return {"dominant": "unknown", "distribution": {}, "alerts": 0}

    counts: dict[str, int] = {}
    for b in state.history:
        counts[b.value] = counts.get(b.value, 0) + 1

    dominant = max(counts, key=counts.get)
    total = sum(counts.values())
    distribution = {BEHAVIOR_LABELS.get(k, k): round(v / total * 100, 1) for k, v in counts.items()}

    return {
        "dominant": BEHAVIOR_LABELS.get(dominant, dominant),
        "distribution": distribution,
        "alerts": sum(1 for b in state.history if b.value in ALERT_BEHAVIORS),
        "total_frames": total,
    }

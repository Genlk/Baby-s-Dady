"""Step 3: 姿态估计（MediaPipe Tasks API）"""

from __future__ import annotations

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from config import (
    POSE_MIN_DETECTION_CONFIDENCE,
    POSE_MIN_TRACKING_CONFIDENCE,
    POSE_MODEL_COMPLEXITY,
)
from models.behaviors import (
    PoseFrame,
    compute_center_y,
    compute_movement,
    compute_torso_angle,
)

_MODEL_PATH = __import__("pathlib").Path(__file__).resolve().parent.parent / "models" / "assets" / "pose_landmarker_lite.task"

# 模型复杂度映射：lite 对应 complexity 0/1，full 对应 2
_MODEL_FILES = {
    0: "pose_landmarker_lite.task",
    1: "pose_landmarker_lite.task",
    2: "pose_landmarker_full.task",
}


def _resolve_model_path() -> str:
    assets_dir = _MODEL_PATH.parent
    name = _MODEL_FILES.get(POSE_MODEL_COMPLEXITY, "pose_landmarker_lite.task")
    path = assets_dir / name
    if not path.exists():
        # fallback to lite
        path = assets_dir / "pose_landmarker_lite.task"
    if not path.exists():
        raise FileNotFoundError(
            f"姿态模型未找到: {path}。请运行: "
            "curl -L -o models/assets/pose_landmarker_lite.task "
            "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"
        )
    return str(path)


class PoseAnalyzer:
    """MediaPipe PoseLandmarker 姿态分析器"""

    def __init__(self) -> None:
        base_options = python.BaseOptions(model_asset_path=_resolve_model_path())
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.VIDEO,
            num_poses=1,
            min_pose_detection_confidence=POSE_MIN_DETECTION_CONFIDENCE,
            min_pose_presence_confidence=POSE_MIN_DETECTION_CONFIDENCE,
            min_tracking_confidence=POSE_MIN_TRACKING_CONFIDENCE,
        )
        self._landmarker = vision.PoseLandmarker.create_from_options(options)
        self._prev_landmarks: np.ndarray | None = None
        self._timestamp_ms = 0

    def close(self) -> None:
        self._landmarker.close()

    def _draw_landmarks(self, frame_bgr: np.ndarray, pose_landmarks) -> np.ndarray:
        """在帧上绘制姿态关键点"""
        annotated = frame_bgr.copy()
        h, w = annotated.shape[:2]
        # 绘制连接线
        connections = vision.PoseLandmarksConnections.POSE_LANDMARKS
        points = {}
        for idx, lm in enumerate(pose_landmarks):
            px, py = int(lm.x * w), int(lm.y * h)
            points[idx] = (px, py)
            cv2.circle(annotated, (px, py), 4, (0, 255, 0), -1)

        for conn in connections:
            start = conn.start
            end = conn.end
            if start in points and end in points:
                cv2.line(annotated, points[start], points[end], (0, 200, 255), 2)
        return annotated

    def analyze(self, frame_bgr: np.ndarray, timestamp: float = 0.0) -> tuple[PoseFrame, np.ndarray]:
        """分析单帧姿态"""
        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        timestamp_ms = int(timestamp * 1000)
        if timestamp_ms <= self._timestamp_ms:
            timestamp_ms = self._timestamp_ms + 1
        self._timestamp_ms = timestamp_ms

        result = self._landmarker.detect_for_video(mp_image, timestamp_ms)

        annotated = frame_bgr.copy()
        landmarks_arr = None

        if result.pose_landmarks:
            lms = result.pose_landmarks[0]
            landmarks_arr = np.array([[p.x, p.y, p.visibility] for p in lms])
            annotated = self._draw_landmarks(frame_bgr, lms)

        movement = compute_movement(self._prev_landmarks, landmarks_arr) if landmarks_arr is not None else 0.0
        if landmarks_arr is not None:
            self._prev_landmarks = landmarks_arr.copy()

        pose_frame = PoseFrame(
            landmarks=landmarks_arr,
            timestamp=timestamp,
            movement_score=movement,
            torso_angle=compute_torso_angle(landmarks_arr) if landmarks_arr is not None else 0.0,
            center_y=compute_center_y(landmarks_arr) if landmarks_arr is not None else 0.5,
        )
        return pose_frame, annotated

    def reset(self) -> None:
        self._prev_landmarks = None
        self._timestamp_ms = 0

"""Step 2: 人体检测与 ROI 裁剪"""

from __future__ import annotations

import cv2
import numpy as np

# 使用 HOG 人体检测作为轻量 fallback（无需额外模型文件）
_hog = cv2.HOGDescriptor()
_hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())


def detect_person(frame: np.ndarray) -> tuple[bool, tuple[int, int, int, int] | None]:
    """
    检测画面中是否有人体。

    Returns:
        (detected, bbox)  bbox = (x, y, w, h)
    """
    h, w = frame.shape[:2]
    scale = 640 / max(w, h)
    if scale < 1.0:
        small = cv2.resize(frame, (int(w * scale), int(h * scale)))
    else:
        small = frame
        scale = 1.0

    rects, weights = _hog.detectMultiScale(
        small,
        winStride=(8, 8),
        padding=(8, 8),
        scale=1.05,
    )

    if len(rects) == 0:
        return False, None

    best_idx = int(np.argmax(weights))
    x, y, bw, bh = rects[best_idx]
    x, y, bw, bh = int(x / scale), int(y / scale), int(bw / scale), int(bh / scale)
    return True, (x, y, bw, bh)


def crop_roi(frame: np.ndarray, bbox: tuple[int, int, int, int] | None) -> np.ndarray:
    """按检测框裁剪 ROI，无检测时返回原图"""
    if bbox is None:
        return frame
    x, y, w, h = bbox
    h_img, w_img = frame.shape[:2]
    x1 = max(0, x)
    y1 = max(0, y)
    x2 = min(w_img, x + w)
    y2 = min(h_img, y + h)
    return frame[y1:y2, x1:x2]

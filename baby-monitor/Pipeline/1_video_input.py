"""Step 1: 视频/摄像头输入"""

from __future__ import annotations

from pathlib import Path
from typing import Generator

import cv2
import numpy as np

from config import DEFAULT_FPS, FRAME_SKIP


def open_video(source: str | int) -> cv2.VideoCapture:
    """打开视频文件或摄像头"""
    if isinstance(source, str) and source.isdigit():
        source = int(source)
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        raise ValueError(f"无法打开视频源: {source}")
    return cap


def iter_frames(
    source: str | int | Path,
    max_frames: int | None = None,
    frame_skip: int = FRAME_SKIP,
) -> Generator[tuple[int, np.ndarray, float], None, None]:
    """
    逐帧读取视频。

    Yields:
        (frame_index, bgr_frame, timestamp_seconds)
    """
    cap = open_video(source)
    fps = cap.get(cv2.CAP_PROP_FPS) or DEFAULT_FPS
    idx = 0
    yielded = 0

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            if idx % (frame_skip + 1) == 0:
                timestamp = idx / fps
                yield idx, frame, timestamp
                yielded += 1
                if max_frames and yielded >= max_frames:
                    break
            idx += 1
    finally:
        cap.release()


def load_single_frame(source: str | Path) -> np.ndarray:
    """从图片文件加载单帧"""
    frame = cv2.imread(str(source))
    if frame is None:
        raise ValueError(f"无法读取图片: {source}")
    return frame

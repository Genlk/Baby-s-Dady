#!/usr/bin/env bash
# 下载 MediaPipe 姿态模型
set -e
ASSETS_DIR="$(dirname "$0")/models/assets"
mkdir -p "$ASSETS_DIR"

LITE_URL="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"
FULL_URL="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task"

if [ ! -f "$ASSETS_DIR/pose_landmarker_lite.task" ]; then
  echo "下载 pose_landmarker_lite.task ..."
  curl -L -o "$ASSETS_DIR/pose_landmarker_lite.task" "$LITE_URL"
fi

echo "模型已就绪: $ASSETS_DIR"

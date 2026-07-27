"""宝宝智能监控 - Gradio Web 界面"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import cv2
import gradio as gr
import numpy as np

_ROOT = Path(__file__).resolve().parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

import importlib.util

_spec = importlib.util.spec_from_file_location("pipeline", _ROOT / "Pipeline" / "0_pipeline.py")
_pipeline_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_pipeline_mod)
BabyMonitorPipeline = _pipeline_mod.BabyMonitorPipeline

from config import BEHAVIOR_LABELS

_pipeline: BabyMonitorPipeline | None = None


def _get_pipeline() -> BabyMonitorPipeline:
    global _pipeline
    if _pipeline is None:
        _pipeline = BabyMonitorPipeline()
    return _pipeline


def analyze_image(image: np.ndarray) -> tuple[np.ndarray, str]:
    """分析单张图片"""
    if image is None:
        return None, "请上传图片"

    pipeline = _get_pipeline()
    pipeline.reset()
    bgr = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
    result = pipeline.process_frame(bgr)

    out_rgb = cv2.cvtColor(result["frame"], cv2.COLOR_BGR2RGB)
    status = _format_status(result)
    return out_rgb, status


def analyze_video(video_path: str, max_frames: int) -> tuple[str | None, np.ndarray | None, str]:
    """分析上传的视频"""
    if not video_path:
        return None, None, "请上传视频文件"

    pipeline = _get_pipeline()
    report = pipeline.process_video(video_path, max_frames=max_frames, save_output=True)

    summary = report["summary"]
    lines = [
        f"**处理帧数**: {report['frames_processed']}",
        f"**当前/末帧行为**: {report['last_behavior']}",
        f"**主要行为**: {summary.get('dominant', '未知')}",
        "",
        "**行为分布**:",
    ]
    for label, pct in summary.get("distribution", {}).items():
        lines.append(f"- {label}: {pct}%")
    if summary.get("alerts", 0) > 0:
        lines.append(f"\n⚠️ **告警次数**: {summary['alerts']}")

    status = "\n".join(lines)
    last_frame = report.get("last_frame")
    if last_frame is not None:
        last_frame = cv2.cvtColor(last_frame, cv2.COLOR_BGR2RGB)

    return report.get("output_video"), last_frame, status


def _format_status(result: dict) -> str:
    alert_line = f"\n\n⚠️ **{result['alert_message']}**" if result["alert"] else ""
    return (
        f"**当前行为**: {result['behavior_cn']}\n\n"
        f"**置信度**: {result['confidence']:.0%}\n\n"
        f"**活动度**: {result['movement']:.3f}\n\n"
        f"**躯干角度**: {result['torso_angle']:.0f}°"
        f"{alert_line}"
    )


BEHAVIOR_DESC = "\n".join(f"- **{cn}** (`{en}`)" for en, cn in BEHAVIOR_LABELS.items())

with gr.Blocks(title="宝宝智能监控", theme=gr.themes.Soft()) as demo:
    gr.Markdown(
        """
# 👶 宝宝智能监控

基于计算机视觉的宝宝行为分析系统，可从监控画面或上传视频中识别以下行为：

"""
        + BEHAVIOR_DESC
        + """

> 技术栈：MediaPipe 姿态估计 + 规则行为分类。支持跌倒检测与无人看护告警。
"""
    )

    with gr.Tabs():
        with gr.Tab("📷 图片分析"):
            with gr.Row():
                img_in = gr.Image(label="上传监控截图", type="numpy")
                img_out = gr.Image(label="分析结果")
            img_status = gr.Markdown()
            img_btn = gr.Button("开始分析", variant="primary")
            img_btn.click(analyze_image, inputs=img_in, outputs=[img_out, img_status])

        with gr.Tab("🎬 视频分析"):
            with gr.Row():
                with gr.Column():
                    vid_in = gr.Video(label="上传监控视频")
                    max_frames = gr.Slider(30, 600, value=150, step=30, label="最大分析帧数")
                    vid_btn = gr.Button("开始分析", variant="primary")
                with gr.Column():
                    vid_out = gr.Video(label="标注输出视频")
                    vid_frame = gr.Image(label="末帧预览")
            vid_status = gr.Markdown()
            vid_btn.click(
                analyze_video,
                inputs=[vid_in, max_frames],
                outputs=[vid_out, vid_frame, vid_status],
            )

    gr.Markdown(
        """
---
### 命令行使用

```bash
cd baby-monitor
python Pipeline/0_pipeline.py /path/to/video.mp4
python Pipeline/0_pipeline.py 0   # 使用摄像头
```
"""
    )


if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)

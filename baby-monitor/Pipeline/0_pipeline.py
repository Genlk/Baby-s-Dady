"""总控：编排视频分析 Pipeline"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import cv2
import numpy as np

_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from config import BEHAVIOR_LABELS, FRAME_SKIP, OUTPUT_DIR
from models.behaviors import BehaviorState


def _load_step(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, _ROOT / "Pipeline" / filename)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_step1 = _load_step("video_input", "1_video_input.py")
_step2 = _load_step("detection", "2_detection.py")
_step3 = _load_step("pose_analysis", "3_pose_analysis.py")
_step4 = _load_step("behavior_classify", "4_behavior_classify.py")


class BabyMonitorPipeline:
    """宝宝行为监控分析管线"""

    def __init__(self) -> None:
        self.pose_analyzer = _step3.PoseAnalyzer()
        self.state = BehaviorState()

    def close(self) -> None:
        self.pose_analyzer.close()

    def reset(self) -> None:
        self.pose_analyzer.reset()
        self.state = BehaviorState()

    def process_frame(self, frame_bgr: np.ndarray, timestamp: float = 0.0) -> dict:
        """处理单帧，返回分析结果"""
        person_detected, bbox = _step2.detect_person(frame_bgr)
        roi = _step2.crop_roi(frame_bgr, bbox)
        pose_frame, pose_vis = self.pose_analyzer.analyze(roi, timestamp)

        has_pose = pose_frame.landmarks is not None
        detected = person_detected or has_pose

        vis_frame = pose_vis if has_pose else frame_bgr
        self.state, annotated = _step4.analyze_frame(
            vis_frame,
            pose_frame,
            self.state,
            detected,
            bbox,
        )

        behavior = self.state.current.value
        return {
            "frame": annotated,
            "behavior": behavior,
            "behavior_cn": BEHAVIOR_LABELS.get(behavior, "未知"),
            "confidence": self.state.confidence,
            "alert": self.state.alert,
            "alert_message": self.state.alert_message,
            "movement": pose_frame.movement_score,
            "torso_angle": pose_frame.torso_angle,
        }

    def process_video(
        self,
        source: str | int,
        max_frames: int | None = 300,
        frame_skip: int = FRAME_SKIP,
        save_output: bool = True,
    ) -> dict:
        """处理完整视频，返回汇总报告与输出路径"""
        self.reset()
        output_path = OUTPUT_DIR / "analysis_output.mp4"
        writer = None
        last_result = None
        frames_processed = 0

        for _idx, frame, ts in _step1.iter_frames(source, max_frames=max_frames, frame_skip=frame_skip):
            result = self.process_frame(frame, ts)
            last_result = result
            frames_processed += 1

            if save_output:
                if writer is None:
                    h, w = result["frame"].shape[:2]
                    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
                    writer = cv2.VideoWriter(str(output_path), fourcc, 10, (w, h))
                writer.write(result["frame"])

        if writer:
            writer.release()

        summary = _step4.summarize_session(self.state)
        return {
            "frames_processed": frames_processed,
            "summary": summary,
            "last_behavior": last_result["behavior_cn"] if last_result else "无",
            "output_video": str(output_path) if save_output and frames_processed > 0 else None,
            "last_frame": last_result["frame"] if last_result else None,
        }


def run_cli() -> None:
    """命令行入口"""
    import argparse

    parser = argparse.ArgumentParser(description="宝宝智能监控 - 行为分析")
    parser.add_argument("source", help="视频路径或摄像头编号（如 0）")
    parser.add_argument("--max-frames", type=int, default=300, help="最大分析帧数")
    parser.add_argument("--no-save", action="store_true", help="不保存输出视频")
    args = parser.parse_args()

    source: str | int = args.source
    if str(source).isdigit():
        source = int(source)

    pipeline = BabyMonitorPipeline()
    try:
        report = pipeline.process_video(source, max_frames=args.max_frames, save_output=not args.no_save)
        print("\n=== 分析完成 ===")
        print(f"处理帧数: {report['frames_processed']}")
        print(f"主要行为: {report['summary'].get('dominant', '未知')}")
        print(f"行为分布: {report['summary'].get('distribution', {})}")
        if report["output_video"]:
            print(f"输出视频: {report['output_video']}")
    finally:
        pipeline.close()


if __name__ == "__main__":
    run_cli()

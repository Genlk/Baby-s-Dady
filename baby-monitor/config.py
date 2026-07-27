"""宝宝智能监控 - 全局配置"""

from pathlib import Path

PROJECT_ROOT = Path(__file__).parent
OUTPUT_DIR = PROJECT_ROOT / "outputs"
OUTPUT_DIR.mkdir(exist_ok=True)

# 视频输入
DEFAULT_FPS = 15
FRAME_SKIP = 2  # 每隔 N 帧分析一次，降低算力消耗

# MediaPipe 姿态检测
POSE_MIN_DETECTION_CONFIDENCE = 0.5
POSE_MIN_TRACKING_CONFIDENCE = 0.5
POSE_MODEL_COMPLEXITY = 1  # 0=轻量, 1=平衡, 2=精确

# 行为判定阈值
MOVEMENT_THRESHOLD = 0.02       # 关键点位移比例，超过视为活跃
STILL_FRAMES_FOR_SLEEP = 30     # 连续静止帧数判定为睡眠
CRAWL_ANGLE_THRESHOLD = 35      # 躯干与地面夹角（度），低于此值视为趴/爬
STAND_ANGLE_THRESHOLD = 65      # 躯干与地面夹角，高于此值视为站立/坐立
FALL_VELOCITY_THRESHOLD = 0.08  # 躯干中心突然下降速度
UNATTENDED_SECONDS = 10         # 未检测到宝宝超过此秒数触发告警

# 支持识别的行为类型
BEHAVIOR_LABELS = {
    "sleeping": "睡眠中",
    "lying": "平躺",
    "crawling": "爬行/趴卧",
    "sitting": "坐立",
    "standing": "站立",
    "playing": "玩耍/活跃",
    "falling": "疑似跌倒",
    "unattended": "无人看护",
    "unknown": "未知",
}

# 需要告警的行为
ALERT_BEHAVIORS = {"falling", "unattended"}

# 宝宝智能监控 (Baby Behavior Monitor)

基于计算机视觉的宝宝行为分析系统，可从监控画面或视频中自动识别宝宝当前行为，并在异常情况下发出告警。

## 功能特性

| 行为 | 说明 |
|------|------|
| 睡眠中 | 长时间静止且平躺 |
| 平躺 | 躯干接近水平、活动度低 |
| 爬行/趴卧 | 躯干水平且有肢体活动 |
| 坐立 | 躯干呈中等角度 |
| 站立 | 躯干接近垂直 |
| 玩耍/活跃 | 站立姿态且活动度高 |
| 疑似跌倒 | 躯干突然快速下降 |
| 无人看护 | 画面中未检测到人体 |

## 移动端 App（Android / iOS / 鸿蒙）

支持以 App 模式发布到手机平台，详见 [docs/MOBILE.md](./docs/MOBILE.md)。

```bash
# 1. 启动分析服务器
uvicorn api.server:app --host 0.0.0.0 --port 8000

# 2. 运行 Flutter App
cd mobile && flutter pub get && flutter run

# 3. 打包发布
flutter build apk --release      # Android APK
flutter build appbundle --release # Google Play
flutter build ios --release       # iOS（需 macOS）
```

```text
baby-monitor/
├── api/server.py       # FastAPI 后端（供手机 App 调用）
├── mobile/             # Flutter 跨端 App
├── harmonyos/          # 鸿蒙 ArkTS API 参考
└── docs/MOBILE.md      # 完整发布指南
```

## 项目结构

```text
baby-monitor/
├── app.py                  # Gradio Web 界面
├── api/server.py           # 移动端 API 服务
├── mobile/                 # Flutter App（Android/iOS/鸿蒙）
├── config.py               # 全局配置与阈值
├── requirements.txt
├── models/
│   └── behaviors.py        # 行为定义与分类规则
└── Pipeline/
    ├── 0_pipeline.py       # 总控编排
    ├── 1_video_input.py    # 视频/摄像头输入
    ├── 2_detection.py      # 人体检测
    ├── 3_pose_analysis.py  # MediaPipe 姿态估计
    └── 4_behavior_classify.py  # 行为分类与可视化
```

## 快速开始

### 安装依赖

```bash
cd baby-monitor
pip install -r requirements.txt

# 下载姿态估计模型（约 5.6 MB）
bash scripts/download_models.sh
```

Linux 环境如遇到 `libEGL.so.1` 缺失，请安装：

```bash
sudo apt-get install -y libegl1 libgl1
```

### 启动 Web 界面

```bash
python app.py
```

浏览器访问 `http://localhost:7860`，上传监控截图或视频即可分析。

### 命令行分析

```bash
# 分析视频文件
python Pipeline/0_pipeline.py /path/to/baby_video.mp4

# 使用摄像头（编号 0）
python Pipeline/0_pipeline.py 0

# 限制分析帧数、不保存输出
python Pipeline/0_pipeline.py video.mp4 --max-frames 100 --no-save
```

## 工作原理

```mermaid
flowchart LR
    A[视频/图片输入] --> B[人体检测 HOG]
    B --> C[姿态估计 MediaPipe]
    C --> D[特征提取]
    D --> E[行为规则分类]
    E --> F[可视化 + 告警]
```

1. **人体检测**：OpenCV HOG 检测画面中是否有人
2. **姿态估计**：MediaPipe Pose 提取 33 个关键点
3. **特征计算**：躯干角度、活动度、中心位移
4. **行为分类**：基于规则引擎判定当前行为
5. **告警**：跌倒、无人看护等异常行为触发红色提示

## 配置调优

在 `config.py` 中可调整：

- `MOVEMENT_THRESHOLD` — 活动度灵敏度
- `STILL_FRAMES_FOR_SLEEP` — 判定睡眠所需的静止帧数
- `FALL_VELOCITY_THRESHOLD` — 跌倒检测灵敏度
- `FRAME_SKIP` — 跳帧数，越大越快但精度降低

## 注意事项

- 建议在光线充足、宝宝全身可见的监控角度使用
- 当前为规则分类方案，复杂场景可替换为训练好的行为识别模型
- 跌倒检测为辅助提示，不能替代人工监护

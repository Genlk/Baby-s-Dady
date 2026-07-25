# Baby's Dady

家庭向 Flutter 应用（**iOS / Android / Web**）：老婆的衣橱 + 宝宝的记录。

## 核心能力

1. **本地落盘**：衣橱、日常护理、里程碑、成长数据写入手机 Documents（`baby_s_dady/app_snapshot.json` + `photos/`）。
2. **Wi‑Fi 云同步**：检测到 Wi‑Fi（或以太网）后，自动把待同步数据上传到云端存储空间。
3. **云端配置**：首页云朵图标可配置 HTTP 云端地址；留空则同步到本机「云端镜像」目录（便于开发验证）。

## 运行

```bash
flutter pub get
flutter test
flutter run          # 真机 / 模拟器
flutter run -d chrome
```

iOS 需在 **macOS + Xcode** 上构建：`flutter build ipa` 或打开 `ios/Runner.xcworkspace`。

## 同步说明

| 场景 | 行为 |
|------|------|
| 离线 / 蜂窝网络 | 只写本地，状态显示「等待 Wi‑Fi 后同步到云端」 |
| 连上 Wi‑Fi | 自动上传快照与照片 |
| 配置了 `https://…` 端点 | `PUT {base}/app_snapshot.json` 与 `PUT {base}/photos/{file}` |
| 未配置端点 | 写入本机 `baby_s_dady_cloud_mirror/` 镜像目录 |

# 移动端发布指南

宝宝智能监控支持以 **App 模式** 发布到 Android、iOS 和鸿蒙（HarmonyOS）平台。

## 架构

```text
┌─────────────────────────────────────────────┐
│  手机 App（Flutter）                          │
│  Android / iOS / 鸿蒙                         │
│  ├── 实时监控（摄像头拍照分析）                  │
│  ├── 相册分析（图片/视频上传）                   │
│  └── 告警展示                                 │
└──────────────────┬──────────────────────────┘
                   │ HTTP REST API
┌──────────────────▼──────────────────────────┐
│  分析服务器（FastAPI + Python Pipeline）       │
│  ├── POST /api/v1/analyze/image              │
│  ├── POST /api/v1/analyze/video              │
│  └── POST /api/v1/analyze/frame              │
└─────────────────────────────────────────────┘
```

手机端负责采集画面与展示结果，**AI 分析在服务端完成**（也可后续改为端侧推理）。

---

## 一、启动分析服务器

在电脑或云服务器上运行：

```bash
cd baby-monitor
pip install -r requirements.txt
bash scripts/download_models.sh
uvicorn api.server:app --host 0.0.0.0 --port 8000
```

验证：浏览器访问 `http://<服务器IP>:8000/docs` 查看 API 文档。

---

## 二、Android 发布

### 开发调试

```bash
cd baby-monitor/mobile
flutter pub get
flutter run   # 连接 Android 真机或模拟器
```

### 打包 APK（测试分发）

```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### 上架 Google Play

```bash
# 1. 配置签名（android/app/build.gradle 中 signingConfigs）
# 2. 构建 App Bundle
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab
```

上传到 [Google Play Console](https://play.google.com/console) 即可。

---

## 三、iOS 发布

### 开发调试

```bash
cd baby-monitor/mobile
flutter pub get
flutter run -d ios   # 需 macOS + Xcode
```

### 打包上架 App Store

```bash
# 1. 在 Xcode 中配置 Bundle ID、签名证书
# 2. 构建
flutter build ios --release
# 3. 用 Xcode Archive 并上传到 App Store Connect
```

或使用：

```bash
flutter build ipa --release
```

---

## 四、鸿蒙（HarmonyOS）发布

鸿蒙目前有两种接入方式：

### 方案 A：Flutter for OpenHarmony（推荐，一套代码三端）

华为开源了 Flutter 鸿蒙适配版，可用同一套 Flutter 代码编译鸿蒙应用。

1. 安装 OpenHarmony Flutter SDK：
   - 仓库：https://gitcode.com/openharmony-sig/flutter_flutter
   - 文档：https://gitee.com/openharmony-sig/flutter_flutter

2. 在鸿蒙工程目录执行：

```bash
cd baby-monitor/mobile
# 使用鸿蒙版 Flutter 工具链
flutter build hap --release
```

3. 使用 DevEco Studio 签名并发布到华为应用市场。

### 方案 B：原生 ArkTS App（调用同一套 API）

若需纯鸿蒙原生体验，可用 ArkTS 开发壳应用，调用相同 REST API：

```text
harmonyos/
└── entry/src/main/ets/
    ├── pages/Index.ets       # 主界面
    └── services/ApiService.ets  # HTTP 调用 api/server.py
```

核心 API 与 Android/iOS 完全一致，参考 `mobile/lib/services/api_service.dart` 的逻辑用 ArkTS 重写即可。

鸿蒙应用发布流程：
1. 注册 [华为开发者账号](https://developer.huawei.com/)
2. 使用 DevEco Studio 创建 HarmonyOS 工程
3. 配置 `module.json5` 网络与摄像头权限
4. 签名打包 `.hap` / `.app`
5. 提交 [华为应用市场](https://developer.huawei.com/consumer/cn/appgallery/)

---

## 五、App 功能说明

| 页面 | 功能 |
|------|------|
| 实时监控 | 调用摄像头拍照，发送到服务器分析，支持每 3 秒自动分析 |
| 相册分析 | 从相册选择监控截图或录像进行分析 |
| 设置 | 配置服务器地址、测试连接 |

### 服务器地址配置

| 场景 | 地址 |
|------|------|
| Android 模拟器 | `http://10.0.2.2:8000` |
| iOS 模拟器 | `http://localhost:8000` |
| 真机（同一 WiFi） | `http://<电脑局域网IP>:8000` |
| 云服务器 | `http://<公网IP或域名>:8000` |

---

## 六、生产部署建议

1. **HTTPS**：生产环境用 Nginx 反向代理 + SSL 证书
2. **鉴权**：API 增加 Token 认证，防止未授权访问
3. **推送告警**：接入 Firebase（Android/iOS）或华为 Push Kit（鸿蒙）实现跌倒告警推送
4. **端侧推理**（可选）：后续可将 MediaPipe 模型嵌入手机端，实现离线分析、降低延迟

---

## 七、目录结构

```text
baby-monitor/
├── api/server.py          # FastAPI 后端
├── mobile/                # Flutter 跨端 App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/       # 页面
│   │   ├── services/      # API 客户端
│   │   └── models/        # 数据模型
│   ├── android/           # Android 工程
│   └── ios/               # iOS 工程
└── harmonyos/             # 鸿蒙接入说明与 API 参考
```

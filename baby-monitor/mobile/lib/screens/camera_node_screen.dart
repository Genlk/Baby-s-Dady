import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/camera_node.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import 'mode_select_screen.dart';

/// 闲置手机专用：固定在房间，定时上传画面
class CameraNodeScreen extends StatefulWidget {
  const CameraNodeScreen({super.key});

  @override
  State<CameraNodeScreen> createState() => _CameraNodeScreenState();
}

class _CameraNodeScreenState extends State<CameraNodeScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _running = false;
  bool _dimScreen = true;
  String _deviceName = '儿童房监控';
  CameraNodeStatus? _lastStatus;
  String? _error;
  Timer? _uploadTimer;
  int _uploadCount = 0;
  DateTime? _lastUpload;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  Future<void> _init() async {
    await WakelockPlus.enable();
    final device = context.read<DeviceService>();
    _deviceName = await device.getDeviceName();
    await _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '摄像头初始化失败: $e';
          _initializing = false;
        });
      }
    }
  }

  void _toggleMonitoring() {
    if (_running) {
      _stopMonitoring();
    } else {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    setState(() => _running = true);
    _uploadTimer = Timer.periodic(const Duration(seconds: 5), (_) => _uploadFrame());
    _uploadFrame();
  }

  void _stopMonitoring() {
    _uploadTimer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _uploadFrame() async {
    if (_controller == null || !_controller!.value.isInitialized || !mounted) return;

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final device = context.read<DeviceService>();
      final api = context.read<ApiService>();
      final deviceId = await device.getDeviceId();

      final status = await api.reportFromNode(
        deviceId: deviceId,
        deviceName: _deviceName,
        jpegBytes: bytes,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000,
      );

      if (mounted) {
        setState(() {
          _lastStatus = status;
          _uploadCount++;
          _lastUpload = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('监控点名称'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '如：儿童房、客厅'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('保存')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await context.read<DeviceService>().setDeviceName(name.trim());
      setState(() => _deviceName = name.trim());
    }
  }

  Future<void> _switchMode() async {
    _stopMonitoring();
    await context.read<DeviceService>().setAppMode('');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
    );
  }

  @override
  void dispose() {
    _stopMonitoring();
    WakelockPlus.disable();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('监控端')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!_dimScreen || !_running) CameraPreview(_controller!),
          if (_dimScreen && _running)
            Container(color: Colors.black87),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  deviceName: _deviceName,
                  running: _running,
                  onEditName: _editName,
                  onSwitchMode: _switchMode,
                ),
                const Spacer(),
                if (_lastStatus?.alert == true) _AlertBar(status: _lastStatus!),
                _StatusBar(
                  status: _lastStatus,
                  uploadCount: _uploadCount,
                  lastUpload: _lastUpload,
                  running: _running,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _dimScreen = !_dimScreen),
                        icon: Icon(
                          _dimScreen ? Icons.brightness_2 : Icons.brightness_7,
                          color: Colors.white70,
                        ),
                        tooltip: _dimScreen ? '显示画面' : '息屏省电',
                      ),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleMonitoring,
                          icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                          label: Text(_running ? '停止监控' : '开始监控'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _running ? Colors.red.shade700 : const Color(0xFF6B9BD2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String deviceName;
  final bool running;
  final VoidCallback onEditName;
  final VoidCallback onSwitchMode;

  const _TopBar({
    required this.deviceName,
    required this.running,
    required this.onEditName,
    required this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: running ? Colors.red : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              running ? '● 监控中' : '已停止',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onEditName,
              child: Text(
                deviceName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            onPressed: onSwitchMode,
            icon: const Icon(Icons.swap_horiz, color: Colors.white70),
            tooltip: '切换模式',
          ),
        ],
      ),
    );
  }
}

class _AlertBar extends StatelessWidget {
  final CameraNodeStatus status;
  const _AlertBar({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.alertMessage.isNotEmpty ? status.alertMessage : '检测到异常',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final CameraNodeStatus? status;
  final int uploadCount;
  final DateTime? lastUpload;
  final bool running;

  const _StatusBar({
    this.status,
    required this.uploadCount,
    this.lastUpload,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (status != null)
            Row(
              children: [
                Text(
                  status!.behaviorCn,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(status!.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            )
          else
            const Text('等待首次分析...', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            running
                ? '已上传 $uploadCount 帧${lastUpload != null ? ' · ${_formatTime(lastUpload!)}' : ''}'
                : '插电并点击「开始监控」',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}

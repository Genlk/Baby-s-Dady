import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';

class MonitorScreen extends StatefulWidget {
  final bool serverOk;
  const MonitorScreen({super.key, required this.serverOk});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _initializing = true;
  bool _analyzing = false;
  bool _autoMode = false;
  AnalysisResult? _lastResult;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = '未找到摄像头';
          _initializing = false;
        });
        return;
      }
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
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

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _toggleAutoMode(bool value) {
    setState(() => _autoMode = value);
    _timer?.cancel();
    if (value && widget.serverOk) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _captureAndAnalyze());
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_analyzing || _controller == null || !_controller!.value.isInitialized) return;
    if (!widget.serverOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先连接分析服务器（设置页配置）')),
      );
      return;
    }

    setState(() => _analyzing = true);
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final api = context.read<ApiService>();
      final result = await api.analyzeImage(bytes);
      if (mounted) setState(() => _lastResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              if (_analyzing)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              if (_lastResult?.alert == true)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _AlertBanner(result: _lastResult!),
                ),
            ],
          ),
        ),
        _ResultPanel(result: _lastResult, analyzing: _analyzing),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _analyzing ? null : _captureAndAnalyze,
                  icon: const Icon(Icons.camera),
                  label: const Text('拍照分析'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B9BD2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text('自动监控', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _autoMode,
                    onChanged: widget.serverOk ? _toggleAutoMode : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final AnalysisResult result;
  const _AlertBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.alertMessage.isNotEmpty ? result.alertMessage : '检测到异常行为',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final AnalysisResult? result;
  final bool analyzing;
  const _ResultPanel({this.result, required this.analyzing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: result == null
          ? Text(
              analyzing ? '正在分析...' : '点击「拍照分析」或开启自动监控',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Row(
              children: [
                _BehaviorChip(label: result!.behaviorCn, alert: result!.alert),
                const SizedBox(width: 12),
                Text('置信度 ${(result!.confidence * 100).toStringAsFixed(0)}%'),
                const Spacer(),
                Text('活动 ${result!.movement.toStringAsFixed(2)}'),
              ],
            ),
    );
  }
}

class _BehaviorChip extends StatelessWidget {
  final String label;
  final bool alert;
  const _BehaviorChip({required this.label, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: alert ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: alert ? Colors.red.shade800 : Colors.green.shade800,
        ),
      ),
    );
  }
}

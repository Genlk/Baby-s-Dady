import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _picker = ImagePicker();
  bool _loading = false;
  AnalysisResult? _imageResult;
  VideoSummary? _videoSummary;
  Uint8List? _annotatedBytes;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _analyzeImage(await file.readAsBytes());
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _loading = true;
      _imageResult = null;
      _videoSummary = null;
      _annotatedBytes = null;
    });

    try {
      if (!mounted) return;
      final api = context.read<ApiService>();
      final summary = await api.analyzeVideo(
        await file.readAsBytes(),
        filename: file.name,
      );
      if (mounted) setState(() => _videoSummary = summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('视频分析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _analyzeImage(Uint8List bytes) async {
    setState(() {
      _loading = true;
      _imageResult = null;
      _videoSummary = null;
      _annotatedBytes = null;
    });

    try {
      final api = context.read<ApiService>();
      final result = await api.analyzeImage(bytes);
      Uint8List? annotated;
      if (result.annotatedImageB64 != null) {
        annotated = base64Decode(result.annotatedImageB64!);
      }
      if (mounted) {
        setState(() {
          _imageResult = result;
          _annotatedBytes = annotated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片分析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('选择图片'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B9BD2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickVideo,
                  icon: const Icon(Icons.movie),
                  label: const Text('选择视频'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_annotatedBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_annotatedBytes!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
          ],
          if (_imageResult != null) _ImageResultCard(result: _imageResult!),
          if (_videoSummary != null) _VideoResultCard(summary: _videoSummary!),
          if (!_loading && _imageResult == null && _videoSummary == null)
            _EmptyHint(),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '从相册选择监控截图或录像进行分析',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ImageResultCard extends StatelessWidget {
  final AnalysisResult result;
  const _ImageResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('识别结果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row('行为', result.behaviorCn, highlight: result.alert),
            _row('置信度', '${(result.confidence * 100).toStringAsFixed(0)}%'),
            _row('活动度', result.movement.toStringAsFixed(3)),
            _row('躯干角度', '${result.torsoAngle.toStringAsFixed(0)}°'),
            if (result.alert) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.alertMessage,
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  final VideoSummary summary;
  const _VideoResultCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('视频分析摘要', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row('处理帧数', '${summary.framesProcessed}'),
            _row('主要行为', summary.dominantBehavior),
            _row('末帧行为', summary.lastBehavior),
            if (summary.alertCount > 0)
              _row('告警次数', '${summary.alertCount}', highlight: true),
            const SizedBox(height: 8),
            const Text('行为分布', style: TextStyle(color: Colors.grey)),
            ...summary.distribution.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Text('${e.value}%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/device_service.dart';
import 'camera_node_screen.dart';
import 'home_screen.dart';

/// 首次启动选择：闲置手机做监控端，主力手机做家长端
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  Future<void> _select(BuildContext context, String mode) async {
    final device = context.read<DeviceService>();
    await device.setAppMode(mode);

    if (!context.mounted) return;
    if (mode == 'camera') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CameraNodeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.baby_changing_station, size: 72, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              Text(
                '选择使用方式',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '充分利用家中闲置手机，搭建宝宝监控系统',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _ModeCard(
                icon: Icons.phone_android,
                title: '闲置手机 · 监控端',
                subtitle: '固定在宝宝房间，插电常亮，自动拍摄并上传画面',
                color: const Color(0xFF6B9BD2),
                onTap: () => _select(context, 'camera'),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.smartphone,
                title: '主力手机 · 家长端',
                subtitle: '随时查看各房间监控状态，接收行为分析与告警',
                color: const Color(0xFF7BC67E),
                onTap: () => _select(context, 'parent'),
              ),
              const Spacer(),
              Text(
                '可在设置中随时切换模式',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

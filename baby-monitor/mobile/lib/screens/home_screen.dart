import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/device_service.dart';
import 'analyze_screen.dart';
import 'mode_select_screen.dart';
import 'monitor_screen.dart';
import 'parent_dashboard_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _serverOk = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final api = context.read<ApiService>();
    await api.loadConfig();
    final ok = await api.checkHealth();
    if (mounted) setState(() => _serverOk = ok);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ParentDashboardScreen(),
      MonitorScreen(serverOk: _serverOk),
      const AnalyzeScreen(),
      SettingsScreen(onSaved: _checkServer, onModeSwitch: _switchMode),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('宝宝智能监控'),
        backgroundColor: const Color(0xFF6B9BD2),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(
                  _serverOk ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: _serverOk ? Colors.lightGreenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  _serverOk ? '已连接' : '未连接',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: '家中监控'),
          NavigationDestination(icon: Icon(Icons.videocam), label: '本机拍摄'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: '相册分析'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  Future<void> _switchMode() async {
    await context.read<DeviceService>().setAppMode('');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
    );
  }
}

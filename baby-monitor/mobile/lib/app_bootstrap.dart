import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/camera_node_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mode_select_screen.dart';
import 'services/api_service.dart';
import 'services/device_service.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _loading = true;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _resolveHome();
  }

  Future<void> _resolveHome() async {
    final device = context.read<DeviceService>();
    final api = context.read<ApiService>();
    await api.loadConfig();
    final mode = await device.getAppMode();

    Widget home;
    if (mode == 'camera') {
      home = const CameraNodeScreen();
    } else if (mode == 'parent') {
      home = const HomeScreen();
    } else {
      home = const ModeSelectScreen();
    }

    if (mounted) {
      setState(() {
        _home = home;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _home!;
  }
}

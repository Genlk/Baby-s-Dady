import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_bootstrap.dart';
import 'services/api_service.dart';
import 'services/device_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => DeviceService()),
      ],
      child: const BabyMonitorApp(),
    ),
  );
}

class BabyMonitorApp extends StatelessWidget {
  const BabyMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宝宝智能监控',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B9BD2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const AppBootstrap(),
    );
  }
}

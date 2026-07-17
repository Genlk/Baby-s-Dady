import 'package:flutter/material.dart';

import 'baby_record_page.dart';
import 'debug_page.dart';
import 'wardrobe_page.dart';

void main() {
  runApp(const BabyCareApp());
}

class BabyCareApp extends StatelessWidget {
  const BabyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Baby's Dady",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B8DEF),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// 入口首页：两个按钮 —— “老婆的衣橱” 与 “宝宝的记录”。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baby's Dady"),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            key: const Key('btn-debug'),
            tooltip: '调试页面',
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DebugPage()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _HomeButton(
                key: const Key('btn-wardrobe'),
                icon: Icons.checkroom,
                label: '老婆的衣橱',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WardrobePage(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _HomeButton(
                key: const Key('btn-baby-record'),
                icon: Icons.child_care,
                label: '宝宝的记录',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BabyRecordPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 96,
      child: FilledButton.tonal(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}

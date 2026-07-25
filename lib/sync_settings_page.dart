import 'package:flutter/material.dart';

import 'storage/app_scope.dart';

/// 配置云端 HTTP 端点；留空则使用本机云端镜像目录。
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final TextEditingController _controller = TextEditingController();
  String? _localPath;
  String? _cloudPath;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = AppScope.of(context).store;
    _controller.text = store.snapshot.cloudEndpoint ?? '';
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    final store = AppScope.of(context).store;
    final path = await store.rootPath();
    if (!mounted) return;
    setState(() {
      _localPath = path;
      // 与 MirrorCloudStorage 约定的云端镜像目录名保持一致。
      _cloudPath = path.contains('baby_s_dady')
          ? path.replaceFirst('baby_s_dady', 'baby_s_dady_cloud_mirror')
          : '$path/../baby_s_dady_cloud_mirror';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    await scope.store.setCloudEndpoint(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('云端配置已保存')));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return Scaffold(
      appBar: AppBar(title: const Text('同步与云端')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            '数据会先落盘保存到手机本地。连接 Wi‑Fi 后，自动同步到云端存储空间。',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('field-cloud-endpoint'),
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '云端 HTTP 地址（可选）',
              hintText: 'https://example.com/baby-sync',
              helperText: '留空：同步到本机云端镜像目录；填写后 PUT 到该地址',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('btn-save-cloud-endpoint'),
            onPressed: _save,
            child: const Text('保存配置'),
          ),
          const SizedBox(height: 24),
          Text('本地目录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(_localPath ?? '…', key: const Key('label-local-path')),
          const SizedBox(height: 12),
          Text('默认云端镜像', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(
            _cloudPath ?? '…',
            key: const Key('label-cloud-path'),
          ),
          const SizedBox(height: 12),
          Text(
            '上次同步：${store.snapshot.lastSyncedAt?.toLocal() ?? '尚未同步'}',
            key: const Key('label-last-synced'),
          ),
        ],
      ),
    );
  }
}

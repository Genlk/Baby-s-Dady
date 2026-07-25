import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'weather.dart';

/// 调试页面：查看运行环境、实时调试天气 API、查看操作日志。
class DebugPage extends StatefulWidget {
  const DebugPage({super.key, this.weatherService});

  /// 允许测试注入 fake，默认使用真实的 Open-Meteo 服务。
  final WeatherService? weatherService;

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late final WeatherService _weather = widget.weatherService ?? WeatherService();
  final TextEditingController _cityController = TextEditingController(text: '北京');
  final List<String> _logs = <String>[];

  bool _loading = false;
  WeatherInfo? _result;
  String? _error;
  int? _elapsedMs;

  String _buildMode() {
    if (kDebugMode) return 'debug';
    if (kProfileMode) return 'profile';
    return 'release';
  }

  void _log(String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() => _logs.insert(0, '[$ts] $message'));
  }

  Future<void> _testWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
      _elapsedMs = null;
    });
    _log('请求天气：$city');
    final sw = Stopwatch()..start();
    final info = await _weather.fetchByCity(city);
    sw.stop();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _elapsedMs = sw.elapsedMilliseconds;
      if (info == null) {
        _error = '请求失败或无结果（检查网络/城市名）';
        _log('天气请求失败：$city（${sw.elapsedMilliseconds}ms）');
      } else {
        _result = info;
        _log('天气成功：${info.city} ${info.temperature}°C code=${info.weatherCode}'
            '（${sw.elapsedMilliseconds}ms）');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('调试页面')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _section('运行环境'),
          Card(
            key: const Key('debug-env-card'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _kv('构建模式', _buildMode()),
                  _kv('是否 Web (kIsWeb)', '$kIsWeb'),
                  _kv('目标平台', defaultTargetPlatform.name),
                  _kv('屏幕尺寸',
                      '${media.size.width.toStringAsFixed(0)} × ${media.size.height.toStringAsFixed(0)}'),
                  _kv('像素比', media.devicePixelRatio.toStringAsFixed(2)),
                  _kv('语言', '${Localizations.localeOf(context)}'),
                  _kv('当前时间', DateTime.now().toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section('天气 API 调试'),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('debug-city-field'),
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: '城市名',
                    hintText: '例如：上海 / Tokyo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('debug-fetch-btn'),
                onPressed: _loading ? null : _testWeather,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('请求'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Card(
              key: const Key('debug-weather-error'),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          if (_result != null)
            Card(
              key: const Key('debug-weather-result'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('原始返回',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    _kv('城市', _result!.city),
                    _kv('温度', '${_result!.temperature} °C'),
                    _kv('天气代码', '${_result!.weatherCode}'),
                    const Divider(),
                    Text('计算结果',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    _kv('天气', _result!.condition),
                    _kv('是否下雨', '${_result!.isRainy}'),
                    _kv('是否下雪', '${_result!.isSnowy}'),
                    _kv('推荐季节', _result!.recommendedSeason),
                    _kv('穿衣建议', _result!.advice),
                    if (_elapsedMs != null) _kv('耗时', '$_elapsedMs ms'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _section('操作日志'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _logs.isEmpty
                  ? const Text('暂无日志', key: Key('debug-log-empty'))
                  : Column(
                      key: const Key('debug-log-list'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final line in _logs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(line,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 12)),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: Text(k, style: const TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

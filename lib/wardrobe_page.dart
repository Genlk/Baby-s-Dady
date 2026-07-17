import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'weather.dart';

class ClothingItem {
  const ClothingItem({
    required this.name,
    required this.category,
    required this.season,
    this.note,
    this.photo,
  });

  final String name;
  final String category;
  final String season; // 四季 / 春秋 / 夏 / 冬
  final String? note;
  final Uint8List? photo;
}

/// 老婆的衣橱：按类型统计存放、可拍照备注，并根据当地天气推荐穿搭。
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key, this.weatherService, this.defaultCity = '北京'});

  /// 允许在测试中注入 fake，默认使用真实的 Open-Meteo 服务。
  final WeatherService? weatherService;
  final String defaultCity;

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  static const List<String> categories = <String>[
    '上衣',
    '外套',
    '裤子',
    '裙子',
    '鞋子',
    '包包',
  ];
  static const List<String> seasons = <String>['四季', '春秋', '夏', '冬'];

  late final WeatherService _weather = widget.weatherService ?? WeatherService();
  final ImagePicker _picker = ImagePicker();

  final List<ClothingItem> _items = <ClothingItem>[];
  String _filter = '全部';
  String _city = '北京';

  WeatherInfo? _weatherInfo;
  bool _weatherLoading = false;
  bool _weatherFailed = false;

  @override
  void initState() {
    super.initState();
    _city = widget.defaultCity;
    // 每次进入衣橱都会拉取当地天气。
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherFailed = false;
    });
    final info = await _weather.fetchByCity(_city);
    if (!mounted) return;
    setState(() {
      _weatherLoading = false;
      _weatherInfo = info;
      _weatherFailed = info == null;
    });
  }

  Future<void> _changeCity() async {
    final controller = TextEditingController(text: _city);
    final city = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('切换城市'),
        content: TextField(
          key: const Key('field-city'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '城市名', hintText: '例如：上海'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('city-confirm'),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (city != null && city.isNotEmpty) {
      setState(() => _city = city);
      await _loadWeather();
    }
  }

  Future<void> _addItem() async {
    final nameC = TextEditingController();
    final noteC = TextEditingController();
    String category = categories.first;
    String season = seasons.first;
    Uint8List? photo;

    final result = await showDialog<ClothingItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pick(ImageSource source) async {
              final x = await _picker.pickImage(source: source, maxWidth: 1024);
              if (x != null) {
                final bytes = await x.readAsBytes();
                setDialogState(() => photo = bytes);
              }
            }

            return AlertDialog(
              title: const Text('添加衣物'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (photo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(photo!,
                              height: 120, width: 120, fit: BoxFit.cover),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextButton.icon(
                          key: const Key('btn-take-photo'),
                          onPressed: () => pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('拍照'),
                        ),
                        TextButton.icon(
                          key: const Key('btn-pick-photo'),
                          onPressed: () => pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('相册'),
                        ),
                      ],
                    ),
                    TextField(
                      key: const Key('field-clothing-name'),
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        hintText: '例如：白色连衣裙',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('dropdown-category'),
                            value: category,
                            decoration: const InputDecoration(labelText: '类型'),
                            items: <DropdownMenuItem<String>>[
                              for (final c in categories)
                                DropdownMenuItem<String>(
                                    value: c, child: Text(c)),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialogState(() => category = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('dropdown-season'),
                            value: season,
                            decoration: const InputDecoration(labelText: '季节'),
                            items: <DropdownMenuItem<String>>[
                              for (final s in seasons)
                                DropdownMenuItem<String>(
                                    value: s, child: Text(s)),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialogState(() => season = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('field-clothing-note'),
                      controller: noteC,
                      decoration: const InputDecoration(
                        labelText: '备注说明（可选）',
                        hintText: '例如：生日礼物 / 只在正式场合穿',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: const Key('dialog-save'),
                  onPressed: () {
                    final name = nameC.text.trim();
                    if (name.isEmpty) return;
                    final note = noteC.text.trim();
                    Navigator.of(context).pop(
                      ClothingItem(
                        name: name,
                        category: category,
                        season: season,
                        note: note.isEmpty ? null : note,
                        photo: photo,
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _items.insert(0, result));
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case '外套':
        return Icons.ac_unit;
      case '裤子':
        return Icons.dry_cleaning;
      case '裙子':
        return Icons.woman;
      case '鞋子':
        return Icons.ice_skating;
      case '包包':
        return Icons.shopping_bag;
      default:
        return Icons.checkroom;
    }
  }

  List<ClothingItem> get _visibleItems => _filter == '全部'
      ? _items
      : _items.where((e) => e.category == _filter).toList();

  List<ClothingItem> get _recommended {
    final info = _weatherInfo;
    if (info == null) return const <ClothingItem>[];
    final target = info.recommendedSeason;
    return _items
        .where((e) => e.season == target || e.season == '四季')
        .toList();
  }

  Widget _photoOrIcon(ClothingItem item, {double size = 44}) {
    if (item.photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(item.photo!,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      child: Icon(_iconFor(item.category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('老婆的衣橱'),
        actions: <Widget>[
          IconButton(
            key: const Key('btn-refresh-weather'),
            tooltip: '刷新天气',
            onPressed: _loadWeather,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-add-clothing'),
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('添加衣物'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildWeatherCard(),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              key: Key('wardrobe-empty'),
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('衣橱还是空的，点击右下角添加衣物吧～')),
            )
          else
            Column(
              key: const Key('wardrobe-list'),
              children: <Widget>[
                for (final item in _visibleItems)
                  Card(
                    child: ListTile(
                      leading: _photoOrIcon(item),
                      title: Text(item.name),
                      subtitle: Text(
                        item.note == null
                            ? '${item.category} · ${item.season}'
                            : '${item.category} · ${item.season}\n${item.note}',
                      ),
                      isThreeLine: item.note != null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      key: const Key('weather-card'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.wb_sunny),
                const SizedBox(width: 8),
                Text('今日天气 · $_city',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  key: const Key('btn-change-city'),
                  onPressed: _changeCity,
                  child: const Text('切换城市'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_weatherLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('正在获取天气…'),
              )
            else if (_weatherFailed || _weatherInfo == null)
              const Text('天气获取失败，点击右上角刷新重试。')
            else ...<Widget>[
              Text(
                '${_weatherInfo!.condition}  ${_weatherInfo!.temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text('穿衣建议：${_weatherInfo!.advice}'),
              const SizedBox(height: 12),
              Text('为你从衣橱推荐（${_weatherInfo!.recommendedSeason}季）',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              if (_recommended.isEmpty)
                Text(
                  key: const Key('recommend-empty'),
                  '衣橱里还没有适合「${_weatherInfo!.recommendedSeason}」的衣服，快去添加吧～',
                )
              else
                SizedBox(
                  height: 96,
                  child: ListView(
                    key: const Key('recommend-list'),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final item in _recommended)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: <Widget>[
                              _photoOrIcon(item, size: 56),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final counts = <String, int>{for (final c in categories) c: 0};
    for (final item in _items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return Card(
      key: const Key('stats-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('衣橱统计 · 共 ${_items.length} 件',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final c in categories)
                  Chip(
                    avatar: Icon(_iconFor(c), size: 18),
                    label: Text('$c ${counts[c]}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final options = <String>['全部', ...categories];
    return Wrap(
      spacing: 8,
      children: <Widget>[
        for (final o in options)
          ChoiceChip(
            key: Key('filter-$o'),
            label: Text(o),
            selected: _filter == o,
            onSelected: (_) => setState(() => _filter = o),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

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

// ===========================================================================
// 老婆的衣橱 (Wife's Wardrobe)
// ===========================================================================

class ClothingItem {
  const ClothingItem(this.name, this.category);
  final String name;
  final String category;
}

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  static const List<String> _categories = <String>['上衣', '裤子', '裙子', '鞋子', '包包'];

  final List<ClothingItem> _items = <ClothingItem>[];

  Future<void> _addItem() async {
    final controller = TextEditingController();
    String category = _categories.first;

    final result = await showDialog<ClothingItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加衣物'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    key: const Key('field-clothing-name'),
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      hintText: '例如：白色连衣裙',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    key: const Key('dropdown-category'),
                    value: category,
                    isExpanded: true,
                    items: <DropdownMenuItem<String>>[
                      for (final c in _categories)
                        DropdownMenuItem<String>(value: c, child: Text(c)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: const Key('dialog-save'),
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(context).pop(ClothingItem(name, category));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('老婆的衣橱')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-add-clothing'),
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('添加衣物'),
      ),
      body: _items.isEmpty
          ? const Center(
              key: Key('wardrobe-empty'),
              child: Text('衣橱还是空的，点击右下角添加衣物吧～'),
            )
          : ListView.separated(
              key: const Key('wardrobe-list'),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Icon(_iconFor(item.category)),
                  title: Text(item.name),
                  subtitle: Text(item.category),
                );
              },
            ),
    );
  }
}

// ===========================================================================
// 宝宝的记录 (Baby's Record) —— 护理记录
// ===========================================================================

enum CareType { feeding, diaper, sleep }

extension CareTypeInfo on CareType {
  String get label {
    switch (this) {
      case CareType.feeding:
        return '喂奶';
      case CareType.diaper:
        return '换尿布';
      case CareType.sleep:
        return '睡觉';
    }
  }

  IconData get icon {
    switch (this) {
      case CareType.feeding:
        return Icons.local_drink;
      case CareType.diaper:
        return Icons.baby_changing_station;
      case CareType.sleep:
        return Icons.bedtime;
    }
  }
}

class CareEvent {
  const CareEvent(this.type, this.time);
  final CareType type;
  final DateTime time;
}

class BabyRecordPage extends StatefulWidget {
  const BabyRecordPage({super.key});

  @override
  State<BabyRecordPage> createState() => _BabyRecordPageState();
}

class _BabyRecordPageState extends State<BabyRecordPage> {
  final List<CareEvent> _events = <CareEvent>[];

  void _logEvent(CareType type) {
    setState(() {
      _events.insert(0, CareEvent(type, DateTime.now()));
    });
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝宝的记录')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _StatTile(
                      key: const Key('stat-feeding'),
                      label: '喂奶',
                      count: _events
                          .where((e) => e.type == CareType.feeding)
                          .length,
                    ),
                    _StatTile(
                      key: const Key('stat-diaper'),
                      label: '换尿布',
                      count: _events
                          .where((e) => e.type == CareType.diaper)
                          .length,
                    ),
                    _StatTile(
                      key: const Key('stat-sleep'),
                      label: '睡觉',
                      count: _events
                          .where((e) => e.type == CareType.sleep)
                          .length,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                for (final type in CareType.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton.tonalIcon(
                        key: Key('add-${type.name}'),
                        onPressed: () => _logEvent(type),
                        icon: Icon(type.icon, size: 18),
                        label: Text(type.label),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _events.isEmpty
                ? const Center(
                    key: Key('empty-state'),
                    child: Text('还没有记录，点上面的按钮记一笔吧。'),
                  )
                : ListView.builder(
                    key: const Key('event-list'),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final e = _events[index];
                      return ListTile(
                        leading: Icon(e.type.icon),
                        title: Text(e.type.label),
                        trailing: Text(_formatTime(e.time)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('$count', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

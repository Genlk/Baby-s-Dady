import 'package:flutter/material.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

String formatDate(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

/// 宝宝的记录：日常 / 里程碑 / 成长 三个标签页。
class BabyRecordPage extends StatelessWidget {
  const BabyRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('宝宝的记录'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(key: Key('tab-daily'), icon: Icon(Icons.today), text: '日常'),
              Tab(
                key: Key('tab-milestone'),
                icon: Icon(Icons.emoji_events),
                text: '里程碑',
              ),
              Tab(
                key: Key('tab-growth'),
                icon: Icon(Icons.straighten),
                text: '成长',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            DailyCareTab(),
            MilestoneTab(),
            GrowthTab(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 日常 (Daily care) —— 喂奶 / 换尿布 / 睡觉
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

class DailyCareTab extends StatefulWidget {
  const DailyCareTab({super.key});

  @override
  State<DailyCareTab> createState() => _DailyCareTabState();
}

class _DailyCareTabState extends State<DailyCareTab>
    with AutomaticKeepAliveClientMixin {
  final List<CareEvent> _events = <CareEvent>[];

  @override
  bool get wantKeepAlive => true;

  void _logEvent(CareType type) {
    setState(() => _events.insert(0, CareEvent(type, DateTime.now())));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
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
                    count:
                        _events.where((e) => e.type == CareType.feeding).length,
                  ),
                  _StatTile(
                    key: const Key('stat-diaper'),
                    label: '换尿布',
                    count:
                        _events.where((e) => e.type == CareType.diaper).length,
                  ),
                  _StatTile(
                    key: const Key('stat-sleep'),
                    label: '睡觉',
                    count:
                        _events.where((e) => e.type == CareType.sleep).length,
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
                      trailing: Text(formatTime(e.time)),
                    );
                  },
                ),
        ),
      ],
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

// ===========================================================================
// 里程碑 (Milestones / 关键时刻)
// ===========================================================================

/// 预设里程碑分类，参考 CDC / WHO / UNICEF 及主流宝宝记录 App 的发育里程碑清单。
const Map<String, List<String>> kMilestonePresets = <String, List<String>>{
  '珍贵瞬间': <String>['满月', '百天', '周岁', '第一次微笑', '第一颗牙', '第一次理发', '第一次抓周'],
  '大动作': <String>['抬头', '翻身', '独坐', '爬行', '扶站', '独走'],
  '精细动作': <String>['抓握玩具', '拇指食指捏取', '涂鸦'],
  '语言沟通': <String>['咯咯笑', '发出 baba/mama 音', '有意识叫爸爸妈妈', '说第一个词'],
  '社交认知': <String>['对视微笑', '认生', '拍手/再见', '模仿动作'],
};

class Milestone {
  const Milestone(this.title, this.category, this.date, {this.note});
  final String title;
  final String category;
  final DateTime date;
  final String? note;
}

class MilestoneTab extends StatefulWidget {
  const MilestoneTab({super.key});

  @override
  State<MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<MilestoneTab>
    with AutomaticKeepAliveClientMixin {
  final List<Milestone> _records = <Milestone>[];

  @override
  bool get wantKeepAlive => true;

  void _add(Milestone m) {
    setState(() {
      _records.insert(0, m);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('已记录里程碑：${m.title}'), duration: const Duration(seconds: 1)),
      );
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    String category = kMilestonePresets.keys.first;

    final result = await showDialog<Milestone>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('自定义关键时刻'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      key: const Key('field-milestone-title'),
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '关键时刻',
                        hintText: '例如：第一次喊爷爷',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      key: const Key('dropdown-milestone-category'),
                      value: category,
                      isExpanded: true,
                      items: <DropdownMenuItem<String>>[
                        for (final c in kMilestonePresets.keys)
                          DropdownMenuItem<String>(value: c, child: Text(c)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('field-milestone-note'),
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: '备注（可选）',
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
                  key: const Key('milestone-save'),
                  onPressed: () {
                    final title = controller.text.trim();
                    if (title.isEmpty) return;
                    final note = noteController.text.trim();
                    Navigator.of(context).pop(
                      Milestone(
                        title,
                        category,
                        DateTime.now(),
                        note: note.isEmpty ? null : note,
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

    if (result != null) _add(result);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-add-milestone'),
        onPressed: _addCustom,
        icon: const Icon(Icons.add),
        label: const Text('自定义'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('点一下快速记录关键时刻', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 148,
            child: ListView(
              key: const Key('milestone-presets'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                for (final entry in kMilestonePresets.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(entry.key,
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: <Widget>[
                            for (final name in entry.value)
                              ActionChip(
                                key: Key('milestone-chip-$name'),
                                label: Text(name),
                                onPressed: () => _add(
                                  Milestone(name, entry.key, DateTime.now()),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    key: Key('milestone-empty'),
                    child: Text('还没有里程碑，选一个关键时刻记录下来吧～'),
                  )
                : ListView.builder(
                    key: const Key('milestone-list'),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final m = _records[index];
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(m.title),
                        subtitle: Text(
                          m.note == null
                              ? '${m.category} · ${formatDate(m.date)}'
                              : '${m.category} · ${formatDate(m.date)}\n${m.note}',
                        ),
                        isThreeLine: m.note != null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 成长 (Growth) —— 身高 / 体重 / 头围
// ===========================================================================

class GrowthEntry {
  const GrowthEntry(this.date, this.heightCm, this.weightKg, this.headCm);
  final DateTime date;
  final double? heightCm;
  final double? weightKg;
  final double? headCm;
}

class GrowthTab extends StatefulWidget {
  const GrowthTab({super.key});

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab>
    with AutomaticKeepAliveClientMixin {
  final List<GrowthEntry> _entries = <GrowthEntry>[];

  @override
  bool get wantKeepAlive => true;

  Future<void> _addEntry() async {
    final heightC = TextEditingController();
    final weightC = TextEditingController();
    final headC = TextEditingController();

    final result = await showDialog<GrowthEntry>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('记录成长数据'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  key: const Key('field-height'),
                  controller: heightC,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '身高 (cm)'),
                ),
                TextField(
                  key: const Key('field-weight'),
                  controller: weightC,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '体重 (kg)'),
                ),
                TextField(
                  key: const Key('field-head'),
                  controller: headC,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '头围 (cm，可选)'),
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
              key: const Key('growth-save'),
              onPressed: () {
                final h = double.tryParse(heightC.text.trim());
                final w = double.tryParse(weightC.text.trim());
                final hc = double.tryParse(headC.text.trim());
                if (h == null && w == null && hc == null) return;
                Navigator.of(context).pop(
                  GrowthEntry(DateTime.now(), h, w, hc),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _entries.insert(0, result));
    }
  }

  String _describe(GrowthEntry e) {
    final parts = <String>[];
    if (e.heightCm != null) parts.add('身高 ${e.heightCm} cm');
    if (e.weightKg != null) parts.add('体重 ${e.weightKg} kg');
    if (e.headCm != null) parts.add('头围 ${e.headCm} cm');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-add-growth'),
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('记录数据'),
      ),
      body: _entries.isEmpty
          ? const Center(
              key: Key('growth-empty'),
              child: Text('还没有成长数据，记录一次身高体重吧～'),
            )
          : ListView.separated(
              key: const Key('growth-list'),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = _entries[index];
                return ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(_describe(e)),
                  subtitle: Text(formatDate(e.date)),
                );
              },
            ),
    );
  }
}

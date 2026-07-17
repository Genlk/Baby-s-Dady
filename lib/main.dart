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
      home: const CareHomePage(),
    );
  }
}

enum CareType { feeding, diaper, sleep }

extension CareTypeInfo on CareType {
  String get label {
    switch (this) {
      case CareType.feeding:
        return 'Feeding';
      case CareType.diaper:
        return 'Diaper';
      case CareType.sleep:
        return 'Sleep';
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

class CareHomePage extends StatefulWidget {
  const CareHomePage({super.key});

  @override
  State<CareHomePage> createState() => _CareHomePageState();
}

class _CareHomePageState extends State<CareHomePage> {
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
      appBar: AppBar(
        title: const Text("Baby's Dady \u2022 Care Tracker"),
        centerTitle: true,
      ),
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
                      label: 'Feeding',
                      count: _events
                          .where((e) => e.type == CareType.feeding)
                          .length,
                    ),
                    _StatTile(
                      key: const Key('stat-diaper'),
                      label: 'Diaper',
                      count: _events
                          .where((e) => e.type == CareType.diaper)
                          .length,
                    ),
                    _StatTile(
                      key: const Key('stat-sleep'),
                      label: 'Sleep',
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
                    child: Text('No events yet. Tap a button to log one.'),
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

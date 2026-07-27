import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baby_monitor_app/main.dart';
import 'package:baby_monitor_app/services/api_service.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider(
        create: (_) => ApiService(),
        child: const BabyMonitorApp(),
      ),
    );
    expect(find.text('宝宝智能监控'), findsOneWidget);
  });
}

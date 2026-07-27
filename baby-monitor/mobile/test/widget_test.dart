import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baby_monitor_app/app_bootstrap.dart';
import 'package:baby_monitor_app/services/api_service.dart';
import 'package:baby_monitor_app/services/device_service.dart';

void main() {
  testWidgets('App bootstrap loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => ApiService()),
          Provider(create: (_) => DeviceService()),
        ],
        child: const MaterialApp(home: AppBootstrap()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

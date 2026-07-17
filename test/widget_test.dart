import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/main.dart';

void main() {
  testWidgets('Logging a feeding event updates the counter and list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    // Initially the empty state is shown and the feeding stat is 0.
    expect(find.byKey(const Key('empty-state')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-feeding')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    // Tap the "Feeding" action button.
    await tester.tap(find.byKey(const Key('add-feeding')));
    await tester.pump();

    // The list now has an entry and the feeding stat shows 1.
    expect(find.byKey(const Key('empty-state')), findsNothing);
    expect(find.byKey(const Key('event-list')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('stat-feeding')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });
}

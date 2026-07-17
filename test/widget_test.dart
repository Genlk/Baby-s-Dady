import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/main.dart';

void main() {
  testWidgets('Home page shows the two entry buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    expect(find.text('老婆的衣橱'), findsOneWidget);
    expect(find.text('宝宝的记录'), findsOneWidget);
    expect(find.byKey(const Key('btn-wardrobe')), findsOneWidget);
    expect(find.byKey(const Key('btn-baby-record')), findsOneWidget);
  });

  testWidgets('Wardrobe: tapping the first button opens it and can add an item',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    await tester.tap(find.byKey(const Key('btn-wardrobe')));
    await tester.pumpAndSettle();

    // Wardrobe opens in its empty state.
    expect(find.byKey(const Key('wardrobe-empty')), findsOneWidget);

    // Add a clothing item.
    await tester.tap(find.byKey(const Key('fab-add-clothing')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('field-clothing-name')), '白色连衣裙');
    await tester.tap(find.byKey(const Key('dialog-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wardrobe-list')), findsOneWidget);
    expect(find.text('白色连衣裙'), findsOneWidget);
  });

  testWidgets('Baby record: second button opens tracker and logs an event',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    await tester.tap(find.byKey(const Key('btn-baby-record')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-feeding')));
    await tester.pump();

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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/main.dart';

void main() {
  testWidgets('Home page shows the two entry buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    expect(find.text('老婆的衣橱'), findsOneWidget);
    expect(find.text('宝宝的记录'), findsOneWidget);
  });

  testWidgets('Wardrobe: tapping the first button opens it and can add an item',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    await tester.tap(find.byKey(const Key('btn-wardrobe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wardrobe-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fab-add-clothing')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('field-clothing-name')), '白色连衣裙');
    await tester.tap(find.byKey(const Key('dialog-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wardrobe-list')), findsOneWidget);
    expect(find.text('白色连衣裙'), findsOneWidget);
  });

  testWidgets('Baby record daily tab logs a care event',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    await tester.tap(find.byKey(const Key('btn-baby-record')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-state')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-feeding')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('stat-feeding')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Milestone tab: quick-add a preset key moment',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());
    await tester.tap(find.byKey(const Key('btn-baby-record')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-milestone')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('milestone-empty')), findsOneWidget);

    // Tap the preset chip "第一次微笑".
    await tester.tap(find.byKey(const Key('milestone-chip-第一次微笑')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('milestone-list')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('milestone-list')),
        matching: find.text('第一次微笑'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Growth tab: record a height/weight entry',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());
    await tester.tap(find.byKey(const Key('btn-baby-record')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-growth')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('growth-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fab-add-growth')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-height')), '60');
    await tester.enterText(find.byKey(const Key('field-weight')), '6.2');
    await tester.tap(find.byKey(const Key('growth-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('growth-list')), findsOneWidget);
    expect(find.textContaining('身高 60.0 cm'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/main.dart';
import 'package:baby_s_dady/wardrobe_page.dart';
import 'package:baby_s_dady/weather.dart';

/// 返回固定天气，避免测试依赖网络。
class FakeWeatherService extends WeatherService {
  FakeWeatherService(this._info);
  final WeatherInfo _info;

  @override
  Future<WeatherInfo?> fetchByCity(String city) async => _info;
}

void main() {
  testWidgets('Home page shows the two entry buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BabyCareApp());

    expect(find.text('老婆的衣橱'), findsOneWidget);
    expect(find.text('宝宝的记录'), findsOneWidget);
  });

  testWidgets('Wardrobe shows weather advice and adds a categorized item',
      (WidgetTester tester) async {
    final fake = FakeWeatherService(
      const WeatherInfo(city: '北京', temperature: 30.0, weatherCode: 0),
    );
    await tester.pumpWidget(MaterialApp(home: WardrobePage(weatherService: fake)));
    await tester.pumpAndSettle();

    // 天气卡片显示建议，并因高温推荐“夏”季。
    expect(find.byKey(const Key('weather-card')), findsOneWidget);
    expect(find.textContaining('穿衣建议'), findsOneWidget);
    expect(find.textContaining('夏季'), findsOneWidget);
    // 暂无夏季衣物时给出提示。
    expect(find.byKey(const Key('recommend-empty')), findsOneWidget);

    // 添加一件夏季衣物（带备注）。
    await tester.tap(find.byKey(const Key('fab-add-clothing')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('field-clothing-name')), '碎花连衣裙');
    await tester.enterText(
        find.byKey(const Key('field-clothing-note')), '夏天最爱');
    // 默认类型“上衣”改为“裙子”。
    await tester.tap(find.byKey(const Key('dropdown-season')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('夏').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-save')));
    await tester.pumpAndSettle();

    // 列表出现该衣物，统计与推荐更新。
    expect(find.byKey(const Key('wardrobe-list')), findsOneWidget);
    expect(find.text('碎花连衣裙'), findsWidgets);
    expect(find.byKey(const Key('recommend-list')), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('milestone-chip-第一次微笑')));
    await tester.pumpAndSettle();

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

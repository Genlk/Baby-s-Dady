import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/debug_page.dart';
import 'package:baby_s_dady/main.dart';
import 'package:baby_s_dady/storage/cloud_storage.dart';
import 'package:baby_s_dady/storage/fs_bridge_memory.dart';
import 'package:baby_s_dady/storage/local_store.dart';
import 'package:baby_s_dady/storage/sync_service.dart';
import 'package:baby_s_dady/wardrobe_page.dart';
import 'package:baby_s_dady/weather.dart';

/// 返回固定天气，避免测试依赖网络。
class FakeWeatherService extends WeatherService {
  FakeWeatherService(this._info);
  final WeatherInfo _info;

  @override
  Future<WeatherInfo?> fetchByCity(String city) async => _info;
}

Future<({LocalStore store, SyncService sync, FakeNetworkProbe network})>
    createTestBackend({bool wifi = true, FakeCloudStorage? cloud}) async {
  final store = LocalStore(fs: createFsBridge());
  await store.init();
  final network = FakeNetworkProbe(wifi: wifi);
  final sync = SyncService(
    store: store,
    network: network,
    cloudOverride: cloud ?? FakeCloudStorage(),
  );
  return (store: store, sync: sync, network: network);
}

Future<void> pumpTestApp(
  WidgetTester tester, {
  required LocalStore store,
  required SyncService sync,
}) async {
  await tester.pumpWidget(BabyCareApp(store: store, sync: sync));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home page shows the two entry buttons and sync bar',
      (WidgetTester tester) async {
    final backend = await createTestBackend();
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);

    expect(find.text('老婆的衣橱'), findsOneWidget);
    expect(find.text('宝宝的记录'), findsOneWidget);
    expect(find.byKey(const Key('sync-status-bar')), findsOneWidget);
  });

  testWidgets('Wardrobe shows weather advice and persists a clothing item',
      (WidgetTester tester) async {
    final backend = await createTestBackend(wifi: false);
    final fake = FakeWeatherService(
      const WeatherInfo(city: '北京', temperature: 30.0, weatherCode: 0),
    );
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);
    final ctx = tester.element(find.byType(HomePage));
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => WardrobePage(weatherService: fake),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weather-card')), findsOneWidget);
    expect(find.textContaining('穿衣建议'), findsOneWidget);
    expect(find.textContaining('夏季'), findsOneWidget);
    expect(find.byKey(const Key('recommend-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fab-add-clothing')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('field-clothing-name')), '碎花连衣裙');
    await tester.enterText(
        find.byKey(const Key('field-clothing-note')), '夏天最爱');
    await tester.tap(find.byKey(const Key('dropdown-season')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('夏').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wardrobe-list')), findsOneWidget);
    expect(find.text('碎花连衣裙'), findsWidgets);
    expect(find.byKey(const Key('recommend-list')), findsOneWidget);
    expect(backend.store.snapshot.wardrobeItems, hasLength(1));
    expect(backend.store.pendingSync, isTrue);
  });

  testWidgets('Debug page: opens from home and tests the weather API',
      (WidgetTester tester) async {
    final backend = await createTestBackend();
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);
    expect(find.byKey(const Key('btn-debug')), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeWeatherService(
      const WeatherInfo(city: '上海', temperature: 5.0, weatherCode: 71),
    );
    final ctx = tester.element(find.byType(HomePage));
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => DebugPage(weatherService: fake),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug-env-card')), findsOneWidget);
    expect(find.byKey(const Key('debug-log-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('debug-fetch-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug-weather-result')), findsOneWidget);
    expect(find.textContaining('下雪'), findsWidgets);
    expect(find.text('冬'), findsWidgets);
    expect(find.byKey(const Key('debug-log-list')), findsOneWidget);
  });

  testWidgets('Baby record daily tab logs a care event to disk',
      (WidgetTester tester) async {
    final backend = await createTestBackend(wifi: false);
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);
    await tester.tap(find.byKey(const Key('btn-baby-record')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-state')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-feeding')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('stat-feeding')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(backend.store.snapshot.careEvents, hasLength(1));
    expect(backend.store.pendingSync, isTrue);
  });

  testWidgets('Milestone tab: quick-add a preset key moment',
      (WidgetTester tester) async {
    final backend = await createTestBackend();
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);
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
    final backend = await createTestBackend();
    await pumpTestApp(tester, store: backend.store, sync: backend.sync);
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

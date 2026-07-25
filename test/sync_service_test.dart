import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:baby_s_dady/storage/app_models.dart';
import 'package:baby_s_dady/storage/cloud_storage.dart';
import 'package:baby_s_dady/storage/fs_bridge_memory.dart';
import 'package:baby_s_dady/storage/local_store.dart';
import 'package:baby_s_dady/storage/sync_service.dart';

void main() {
  test('LocalStore persists snapshot across reload', () async {
    final fs = createFsBridge(rootOverride: '/test-root-a');
    final store = LocalStore(fs: fs);
    await store.init();

    await store.addCareEvent(
      CareEvent(
        id: store.newId(),
        type: CareType.feeding,
        time: DateTime(2026, 7, 25, 8, 30),
      ),
    );
    await store.upsertClothing(
      ClothingItem(
        id: 'cloth-1',
        name: '白T',
        category: '上衣',
        season: '夏',
        photo: Uint8List.fromList(<int>[1, 2, 3, 4]),
      ),
    );

    expect(store.pendingSync, isTrue);

    final reloaded = LocalStore(fs: fs);
    await reloaded.init();
    expect(reloaded.snapshot.careEvents, hasLength(1));
    expect(reloaded.snapshot.wardrobeItems.single.name, '白T');
    expect(reloaded.snapshot.wardrobeItems.single.photo, isNotNull);
    expect(reloaded.pendingSync, isTrue);
  });

  test('SyncService waits for Wi-Fi before uploading', () async {
    final store = LocalStore(fs: createFsBridge(rootOverride: '/test-root-b'));
    await store.init();
    final cloud = FakeCloudStorage();
    final network = FakeNetworkProbe(wifi: false);
    final sync = SyncService(
      store: store,
      network: network,
      cloudOverride: cloud,
    );

    await store.addMilestone(
      Milestone(
        id: 'm1',
        title: '第一次微笑',
        category: '珍贵瞬间',
        date: DateTime(2026, 1, 1),
      ),
    );

    // 给异步 trySync 一个机会。
    await Future<void>.delayed(Duration.zero);
    expect(sync.status, SyncStatus.waitingWifi);
    expect(cloud.uploadCount, 0);

    network.setWifi(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cloud.uploadCount, 1);
    expect(store.pendingSync, isFalse);
    expect(sync.status, SyncStatus.synced);
  });

  test('MirrorCloudStorage writes snapshot and photos', () async {
    final fs = createFsBridge(rootOverride: '/mirror-root');
    final store = LocalStore(fs: fs);
    await store.init();
    await store.upsertClothing(
      ClothingItem(
        id: 'p1',
        name: '外套',
        category: '外套',
        season: '冬',
        photo: Uint8List.fromList(<int>[9, 9, 9]),
      ),
    );

    final cloud = MirrorCloudStorage(fs: fs);
    final payload = await store.buildSyncPayload();
    await cloud.upload(payload);

    final root = await cloud.rootPath;
    expect(await fs.exists('$root/app_snapshot.json'), isTrue);
    expect(await fs.exists('$root/photos/p1.jpg'), isTrue);
  });
}

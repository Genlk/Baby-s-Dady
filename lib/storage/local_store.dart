import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'app_models.dart';
import 'fs_bridge.dart';
import 'fs_bridge_factory.dart';

/// 本地落盘仓库：Documents 下 JSON 快照 + photos/ 二进制照片。
class LocalStore extends ChangeNotifier {
  LocalStore({
    FsBridge? fs,
    String? rootOverride,
    Uuid? uuid,
  })  : _fs = fs ?? createFsBridge(rootOverride: rootOverride),
        _uuid = uuid ?? const Uuid();

  static const String snapshotFileName = 'app_snapshot.json';
  static const String photosDirName = 'photos';
  static const String appFolderName = 'baby_s_dady';

  final FsBridge _fs;
  final Uuid _uuid;

  String? _root;
  AppSnapshot _snapshot = AppSnapshot();
  bool _ready = false;

  AppSnapshot get snapshot => _snapshot;
  bool get isReady => _ready;
  bool get pendingSync => _snapshot.pendingSync;

  Future<String> _ensureRoot() async {
    if (_root != null) return _root!;
    _root = await _fs.resolveRoot(appFolderName);
    await _fs.ensureDirectory('$_root/$photosDirName');
    return _root!;
  }

  String get _snapshotPath => '$_root/$snapshotFileName';

  Future<void> init() async {
    final root = await _ensureRoot();
    _root = root;
    if (await _fs.exists(_snapshotPath)) {
      final raw = await _fs.readString(_snapshotPath);
      _snapshot = AppSnapshot.decode(raw);
      await _hydratePhotos();
    } else {
      _snapshot = AppSnapshot();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _hydratePhotos() async {
    final items = <ClothingItem>[];
    for (final item in _snapshot.wardrobeItems) {
      final name = item.photoFileName;
      if (name == null) {
        items.add(item);
        continue;
      }
      final path = '$_root/$photosDirName/$name';
      if (await _fs.exists(path)) {
        final bytes = await _fs.readBytes(path);
        items.add(item.copyWith(photo: Uint8List.fromList(bytes)));
      } else {
        items.add(item.copyWith(clearPhoto: true));
      }
    }
    _snapshot = _snapshot.copyWith(wardrobeItems: items);
  }

  Future<void> _persist({required bool markPendingSync}) async {
    await _ensureRoot();
    final next = _snapshot.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: markPendingSync ? true : _snapshot.pendingSync,
    );
    _snapshot = next;
    await _fs.writeString(_snapshotPath, next.encode());
    notifyListeners();
  }

  Future<String?> _writePhoto(String id, Uint8List bytes) async {
    await _ensureRoot();
    final fileName = '$id.jpg';
    await _fs.writeBytes('$_root/$photosDirName/$fileName', bytes);
    return fileName;
  }

  Future<void> setCloudEndpoint(String? endpoint) async {
    final trimmed = endpoint?.trim();
    _snapshot = _snapshot.copyWith(
      cloudEndpoint: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      clearCloudEndpoint: trimmed == null || trimmed.isEmpty,
    );
    await _persist(markPendingSync: false);
  }

  Future<void> setWardrobeCity(String city) async {
    _snapshot = _snapshot.copyWith(wardrobeCity: city);
    await _persist(markPendingSync: true);
  }

  Future<void> upsertClothing(ClothingItem item) async {
    String? photoName = item.photoFileName;
    if (item.photo != null) {
      photoName = await _writePhoto(item.id, item.photo!);
    }
    final stored = item.copyWith(photoFileName: photoName);
    final list = List<ClothingItem>.from(_snapshot.wardrobeItems);
    final idx = list.indexWhere((e) => e.id == stored.id);
    if (idx >= 0) {
      list[idx] = stored;
    } else {
      list.insert(0, stored);
    }
    _snapshot = _snapshot.copyWith(wardrobeItems: list);
    await _persist(markPendingSync: true);
  }

  Future<void> addCareEvent(CareEvent event) async {
    final list = List<CareEvent>.from(_snapshot.careEvents)..insert(0, event);
    _snapshot = _snapshot.copyWith(careEvents: list);
    await _persist(markPendingSync: true);
  }

  Future<void> addMilestone(Milestone milestone) async {
    final list = List<Milestone>.from(_snapshot.milestones)
      ..insert(0, milestone);
    _snapshot = _snapshot.copyWith(milestones: list);
    await _persist(markPendingSync: true);
  }

  Future<void> addGrowth(GrowthEntry entry) async {
    final list = List<GrowthEntry>.from(_snapshot.growthEntries)
      ..insert(0, entry);
    _snapshot = _snapshot.copyWith(growthEntries: list);
    await _persist(markPendingSync: true);
  }

  String newId() => _uuid.v4();

  /// 供云同步上传：快照 JSON + 照片字节。
  Future<SyncPayload> buildSyncPayload() async {
    await _ensureRoot();
    final photos = <String, Uint8List>{};
    for (final item in _snapshot.wardrobeItems) {
      final name = item.photoFileName;
      if (name == null) continue;
      if (item.photo != null) {
        photos[name] = item.photo!;
        continue;
      }
      final path = '$_root/$photosDirName/$name';
      if (await _fs.exists(path)) {
        photos[name] = Uint8List.fromList(await _fs.readBytes(path));
      }
    }
    final cloudSnap = _snapshot.copyWith(pendingSync: false);
    return SyncPayload(
      snapshotJson: cloudSnap.encode(),
      photos: photos,
      updatedAt: cloudSnap.updatedAt,
    );
  }

  Future<void> markSynced({DateTime? at}) async {
    _snapshot = _snapshot.copyWith(
      pendingSync: false,
      lastSyncedAt: at ?? DateTime.now(),
    );
    await _persist(markPendingSync: false);
  }

  @visibleForTesting
  Future<void> replaceSnapshotForTest(AppSnapshot snapshot) async {
    _snapshot = snapshot;
    _ready = true;
    await _ensureRoot();
    await _fs.writeString(_snapshotPath, snapshot.encode());
    notifyListeners();
  }

  Future<String> rootPath() async => _ensureRoot();
}

class SyncPayload {
  const SyncPayload({
    required this.snapshotJson,
    required this.photos,
    required this.updatedAt,
  });

  final String snapshotJson;
  final Map<String, Uint8List> photos;
  final DateTime updatedAt;

  Map<String, dynamic> get snapshotMap =>
      jsonDecode(snapshotJson) as Map<String, dynamic>;
}

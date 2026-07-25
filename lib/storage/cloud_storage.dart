import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'fs_bridge.dart';
import 'fs_bridge_factory.dart';
import 'local_store.dart';

/// 云端存储抽象：把本地快照与照片上传到“云盘”空间。
abstract class CloudStorage {
  Future<void> upload(SyncPayload payload);
}

/// 默认实现：同步到本机“云端镜像”目录（模拟云盘落点）。
///
/// 真机上该目录在 App Documents/cloud_mirror；连上 Wi‑Fi 后 SyncService
/// 会把待同步数据写到这里。若配置了 HTTP 端点，则改用 [HttpCloudStorage]。
class MirrorCloudStorage implements CloudStorage {
  MirrorCloudStorage({FsBridge? fs, String? rootOverride})
      : _fs = fs ?? createFsBridge(rootOverride: rootOverride);

  final FsBridge _fs;
  String? _root;

  Future<String> get rootPath async {
    _root ??= await _fs.resolveRoot('baby_s_dady_cloud_mirror');
    await _fs.ensureDirectory('$_root/photos');
    return _root!;
  }

  @override
  Future<void> upload(SyncPayload payload) async {
    final root = await rootPath;
    await _fs.writeString('$root/app_snapshot.json', payload.snapshotJson);
    for (final entry in payload.photos.entries) {
      await _fs.writeBytes('$root/photos/${entry.key}', entry.value);
    }
    await _fs.writeString(
      '$root/last_sync.txt',
      payload.updatedAt.toIso8601String(),
    );
  }
}

/// HTTP 云端：把快照 PUT 到 `{baseUrl}/app_snapshot.json`，
/// 照片 PUT 到 `{baseUrl}/photos/{fileName}`。
///
/// 可对接自建 NAS / 对象存储网关 / 简易同步服务。
class HttpCloudStorage implements CloudStorage {
  HttpCloudStorage({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String relative) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalized/$relative');
  }

  @override
  Future<void> upload(SyncPayload payload) async {
    final snapResp = await _client.put(
      _uri('app_snapshot.json'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: payload.snapshotJson,
    );
    if (snapResp.statusCode < 200 || snapResp.statusCode >= 300) {
      throw StateError(
        '云端快照上传失败：HTTP ${snapResp.statusCode} ${snapResp.body}',
      );
    }

    for (final entry in payload.photos.entries) {
      final resp = await _client.put(
        _uri('photos/${entry.key}'),
        headers: const <String, String>{'Content-Type': 'image/jpeg'},
        body: entry.value,
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw StateError(
          '云端照片上传失败 ${entry.key}：HTTP ${resp.statusCode}',
        );
      }
    }
  }
}

/// 按本地配置选择云端实现。
CloudStorage resolveCloudStorage({
  required String? endpoint,
  FsBridge? fs,
  String? rootOverride,
  http.Client? client,
}) {
  final trimmed = endpoint?.trim();
  if (trimmed != null &&
      trimmed.isNotEmpty &&
      (trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
    return HttpCloudStorage(baseUrl: trimmed, client: client);
  }
  return MirrorCloudStorage(fs: fs, rootOverride: rootOverride);
}

/// 测试用：记录上传次数，可选失败。
class FakeCloudStorage implements CloudStorage {
  FakeCloudStorage({this.shouldFail = false});

  bool shouldFail;
  int uploadCount = 0;
  SyncPayload? lastPayload;
  final List<Uint8List> uploadedPhotoBytes = <Uint8List>[];

  @override
  Future<void> upload(SyncPayload payload) async {
    uploadCount += 1;
    lastPayload = payload;
    uploadedPhotoBytes
      ..clear()
      ..addAll(payload.photos.values);
    if (shouldFail) {
      throw StateError('fake cloud failure');
    }
  }
}

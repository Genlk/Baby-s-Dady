import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'cloud_storage.dart';
import 'local_store.dart';

enum SyncStatus {
  idle,
  waitingWifi,
  syncing,
  synced,
  error,
}

/// 网络探测抽象，便于测试注入。
abstract class NetworkProbe {
  Future<bool> isWifi();
  Stream<bool> get onWifiChanged;
}

class ConnectivityNetworkProbe implements NetworkProbe {
  ConnectivityNetworkProbe([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _isWifi(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  @override
  Future<bool> isWifi() async {
    final current = await _connectivity.checkConnectivity();
    return _isWifi(current);
  }

  @override
  Stream<bool> get onWifiChanged =>
      _connectivity.onConnectivityChanged.map(_isWifi);
}

/// 测试用：可手动切换是否 Wi‑Fi。
class FakeNetworkProbe implements NetworkProbe {
  FakeNetworkProbe({bool wifi = false}) : _wifi = wifi;

  bool _wifi;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  void setWifi(bool value) {
    _wifi = value;
    _controller.add(value);
  }

  @override
  Future<bool> isWifi() async => _wifi;

  @override
  Stream<bool> get onWifiChanged => _controller.stream;

  Future<void> dispose() => _controller.close();
}

/// 监听网络：仅在 Wi‑Fi 下把本地待同步数据推到云端。
class SyncService extends ChangeNotifier {
  SyncService({
    required LocalStore store,
    NetworkProbe? network,
    CloudStorage? cloudOverride,
    bool autoStart = true,
  })  : _store = store,
        _network = network ?? ConnectivityNetworkProbe(),
        _cloudOverride = cloudOverride {
    _store.addListener(_onStoreChanged);
    if (autoStart) {
      unawaited(start());
    }
  }

  final LocalStore _store;
  final NetworkProbe _network;
  final CloudStorage? _cloudOverride;

  StreamSubscription<bool>? _sub;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  bool _wifi = false;
  bool _started = false;
  bool _syncing = false;

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  bool get isWifi => _wifi;
  DateTime? get lastSyncedAt => _store.snapshot.lastSyncedAt;
  bool get pendingSync => _store.pendingSync;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _wifi = await _network.isWifi();
    _sub = _network.onWifiChanged.listen((wifi) {
      final wasWifi = _wifi;
      _wifi = wifi;
      if (!wasWifi && _wifi) {
        unawaited(trySync(reason: 'wifi-connected'));
      } else {
        _refreshStatusOnly();
      }
    });
    await trySync(reason: 'start');
  }

  void _onStoreChanged() {
    if (_store.pendingSync) {
      unawaited(trySync(reason: 'local-change'));
    } else {
      _refreshStatusOnly();
    }
  }

  void _refreshStatusOnly() {
    if (_syncing) return;
    if (_store.pendingSync && !_wifi) {
      _status = SyncStatus.waitingWifi;
    } else if (_store.pendingSync) {
      _status = SyncStatus.idle;
    } else if (_lastError != null) {
      _status = SyncStatus.error;
    } else if (_store.snapshot.lastSyncedAt != null) {
      _status = SyncStatus.synced;
    } else {
      _status = SyncStatus.idle;
    }
    notifyListeners();
  }

  Future<void> trySync({String reason = 'manual'}) async {
    if (!_store.isReady) return;
    if (!_store.pendingSync) {
      _refreshStatusOnly();
      return;
    }
    if (!_wifi) {
      _status = SyncStatus.waitingWifi;
      _lastError = null;
      notifyListeners();
      return;
    }
    if (_syncing) return;

    _syncing = true;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final cloud = _cloudOverride ??
          resolveCloudStorage(endpoint: _store.snapshot.cloudEndpoint);
      final payload = await _store.buildSyncPayload();
      await cloud.upload(payload);
      await _store.markSynced();
      _status = SyncStatus.synced;
      if (kDebugMode) {
        debugPrint('SyncService: synced ($reason)');
      }
    } catch (e) {
      _lastError = e.toString();
      _status = SyncStatus.error;
      if (kDebugMode) {
        debugPrint('SyncService: error ($reason) $e');
      }
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> syncNow() => trySync(reason: 'manual');

  String get statusLabel {
    switch (_status) {
      case SyncStatus.idle:
        return pendingSync ? '待同步' : '本地已保存';
      case SyncStatus.waitingWifi:
        return '等待 Wi‑Fi 后同步到云端';
      case SyncStatus.syncing:
        return '正在同步到云端…';
      case SyncStatus.synced:
        return '已同步到云端';
      case SyncStatus.error:
        return '同步失败';
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

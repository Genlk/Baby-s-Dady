import 'package:flutter/material.dart';

import 'local_store.dart';
import 'sync_service.dart';

/// 向下传递 LocalStore / SyncService，避免全局单例难测。
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.sync,
    required super.child,
  });

  final LocalStore store;
  final SyncService sync;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return store != oldWidget.store || sync != oldWidget.sync;
  }
}

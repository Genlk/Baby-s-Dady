import 'package:flutter/material.dart';

import '../storage/app_scope.dart';
import '../storage/sync_service.dart';

/// 首页同步状态条：本地已保存 / 等待 Wi‑Fi / 同步中 / 已同步。
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  IconData _icon(SyncStatus status) {
    switch (status) {
      case SyncStatus.waitingWifi:
        return Icons.wifi_off;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.cloud_off;
      case SyncStatus.idle:
        return Icons.sd_storage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[scope.store, scope.sync]),
      builder: (context, _) {
        final sync = scope.sync;
        final theme = Theme.of(context);
        return Card(
          key: const Key('sync-status-bar'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(_icon(sync.status), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        sync.statusLabel,
                        key: const Key('sync-status-label'),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        sync.isWifi
                            ? '当前网络：Wi‑Fi'
                            : '当前网络：非 Wi‑Fi（蜂窝/无网）',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (sync.lastError != null)
                        Text(
                          sync.lastError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('btn-sync-now'),
                  onPressed: sync.status == SyncStatus.syncing
                      ? null
                      : () => sync.syncNow(),
                  child: const Text('立即同步'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

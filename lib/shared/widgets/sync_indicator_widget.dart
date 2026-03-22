import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncNotifierProvider);

    return GestureDetector(
      onTap: isOnline
          ? () => ref.read(syncNotifierProvider.notifier).syncNow()
          : null,
      child: Tooltip(
        message: _tooltip(isOnline, syncState),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildIcon(isOnline, syncState),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isOnline, SyncState syncState) {
    if (!isOnline) {
      return const Icon(
        Icons.cloud_off_outlined,
        color: AppColors.syncOffline,
        size: 22,
      );
    }

    switch (syncState.status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        );
      case SyncStatus.success:
        return const Icon(
          Icons.cloud_done_outlined,
          color: AppColors.syncOk,
          size: 22,
        );
      case SyncStatus.error:
        return const Icon(
          Icons.cloud_off_outlined,
          color: AppColors.syncError,
          size: 22,
        );
      case SyncStatus.idle:
        if (syncState.pendingCount > 0) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.syncPending,
                size: 22,
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.syncPending,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${syncState.pendingCount > 9 ? '9+' : syncState.pendingCount}',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return const Icon(
          Icons.cloud_outlined,
          color: AppColors.grey400,
          size: 22,
        );
    }
  }

  String _tooltip(bool isOnline, SyncState syncState) {
    if (!isOnline) return 'Sin conexión';
    switch (syncState.status) {
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado — ${syncState.lastSyncedCount} eventos';
      case SyncStatus.error:
        return 'Error de sincronización';
      case SyncStatus.idle:
        if (syncState.pendingCount > 0) {
          return '${syncState.pendingCount} eventos pendientes — Toca para sincronizar';
        }
        return 'Sincronizado';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final syncState = ref.watch(syncNotifierProvider);

    if (!isOnline) {
      return const Tooltip(
        message: 'Modo Offline',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(Icons.cloud_off, color: Color(0xFFEA4335)),
        ),
      );
    }

    return pendingAsync.when(
      data: (pendingCount) {
        if (syncState.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
          );
        }

        if (pendingCount > 0) {
          return Tooltip(
            message: '$pendingCount pendientes de sincronizaciÃ³n',
            child: InkWell(
              onTap: () => ref.read(syncNotifierProvider.notifier).sync(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.cloud_upload, color: Color(0xFFFF6D00)),
                    Positioned(
                      right: 0,
                      top: 8,
                      child: _Badge(count: pendingCount),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Tooltip(
          message: 'Online y Sincronizado',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.cloud_done, color: Color(0xFF34A853)),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.error, color: Colors.red),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

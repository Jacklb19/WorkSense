import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/shared/domain/usecases/sync_events_use_case.dart';
import 'package:worksense_app/shared/domain/usecases/process_sync_queue_use_case.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';

// ── Sync Use Case Provider ────────────────────────────────────────────────────

final syncEventsUseCaseProvider = Provider<SyncEventsUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ActivityRepositoryImpl(db);
  final remoteDs = ref.watch(supabaseDataSourceProvider);
  return SyncEventsUseCase(repo, remoteDs);
});

final processSyncQueueUseCaseProvider = Provider<ProcessSyncQueueUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final remoteDs = ref.watch(supabaseDataSourceProvider);
  return ProcessSyncQueueUseCase(db, remoteDs);
});

// ── Pending count stream (tiempo real desde Drift) ────────────────────────────

final pendingActivityCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingActivityCount();
});

// ── Sync Status ───────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final int lastSyncedCount;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncedCount = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? lastSyncedCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncEventsUseCase _syncEventsUseCase;
  final ProcessSyncQueueUseCase _processSyncQueueUseCase;

  SyncNotifier(this._syncEventsUseCase, this._processSyncQueueUseCase)
      : super(const SyncState());

  Future<void> syncNow() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);
    try {
      final syncedEvents = await _syncEventsUseCase();
      final syncedQueue = await _processSyncQueueUseCase();
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncedCount: syncedEvents + syncedQueue,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncEventsUseCase = ref.watch(syncEventsUseCaseProvider);
  final processSyncQueueUseCase = ref.watch(processSyncQueueUseCaseProvider);
  final notifier = SyncNotifier(syncEventsUseCase, processSyncQueueUseCase);

  // Auto-sync cuando se recupera la conexión
  ref.listen<bool>(isOnlineProvider, (wasOnline, isNow) {
    final previouslyOffline = wasOnline == null || !wasOnline;
    if (previouslyOffline && isNow) {
      notifier.syncNow();
    }
  });

  return notifier;
});

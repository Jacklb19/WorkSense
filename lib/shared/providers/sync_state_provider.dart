import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/usecases/sync_events_use_case.dart';
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

// ── Pending Sync Count ────────────────────────────────────────────────────────

final pendingEventCountProvider = StateProvider<int>((ref) => 0);

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
  final SyncEventsUseCase _syncUseCase;

  SyncNotifier(this._syncUseCase) : super(const SyncState());

  Future<void> syncNow() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);
    try {
      final synced = await _syncUseCase();
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncedCount: synced,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void updatePendingCount(int count) {
    state = state.copyWith(pendingCount: count);
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncUseCase = ref.watch(syncEventsUseCaseProvider);
  final notifier = SyncNotifier(syncUseCase);

  // Auto-sync when connectivity is restored
  ref.listen<bool>(isOnlineProvider, (wasOnline, isNow) {
    final previouslyOffline = wasOnline == null || !wasOnline;
    if (previouslyOffline && isNow) {
      notifier.syncNow();
    }
  });

  return notifier;
});

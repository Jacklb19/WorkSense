import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/sync_repository_impl.dart';
import 'package:worksense_app/shared/domain/usecases/process_sync_queue_use_case.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final syncRepositoryProvider = Provider<SyncRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncRepositoryImpl(db);
});

final processSyncQueueProvider = Provider<ProcessSyncQueueUseCase>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final remote = ref.watch(supabaseDataSourceProvider);
  return ProcessSyncQueueUseCase(syncRepo, remote);
});

final supabaseDataSourceProvider = Provider<SupabaseDataSource>((ref) {
  return SupabaseDataSource();
});

// ── Sync State Notifier ──────────────────────────────────────────────────────

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<SyncResult?>>((ref) {
  final useCase = ref.watch(processSyncQueueProvider);
  final notifier = SyncNotifier(useCase);

  // Auto-sync al recuperar conexión
  ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
    if (isOnline && (previous == null || !previous)) {
      notifier.sync();
    }
  });

  return notifier;
});

class SyncNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  final ProcessSyncQueueUseCase _useCase;

  SyncNotifier(this._useCase) : super(const AsyncValue.data(null));

  Future<void> sync() async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _useCase());
  }
}

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  return Stream<void>.periodic(const Duration(seconds: 5))
      .asyncMap((_) async {
        final pending = await syncRepo.getPending();
        return pending.length;
      });
});

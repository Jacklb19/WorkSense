import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/sync_repository_impl.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart'
    show supabaseDataSourceProvider;
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/domain/usecases/process_sync_queue_use_case.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

export 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart'
    show supabaseDataSourceProvider;

// â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final syncRepositoryProvider = Provider<SyncRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncRepositoryImpl(db);
});

final processSyncQueueProvider = Provider<ProcessSyncQueueUseCase>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final remote = ref.watch(supabaseDataSourceProvider);
  final db = ref.watch(appDatabaseProvider);
  return ProcessSyncQueueUseCase(syncRepo, remote, db);
});

// â”€â”€ Sync State Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<SyncResult?>>((ref) {
  final useCase = ref.watch(processSyncQueueProvider);
  final notifier = SyncNotifier(useCase);

  // Auto-sync al recuperar conexión (solo si está logueado)
  ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
    final currentUser = ref.read(currentUserProvider);
    final isLoggedIn = currentUser.valueOrNull?.user != null;
    if (isOnline && (previous == null || !previous) && isLoggedIn) {
      notifier.sync();
    }
  });

  // Auto-sync al detectar nuevos elementos en la cola (cada 5s según el provider)
  ref.listen<AsyncValue<int>>(pendingSyncCountProvider, (previous, next) {
    final currentUser = ref.read(currentUserProvider);
    final isLoggedIn = currentUser.valueOrNull?.user != null;
    final count = next.valueOrNull ?? 0;
    final isOnline = ref.read(isOnlineProvider);
    if (count > 0 && isOnline && isLoggedIn) {
      notifier.sync();
    }
  });

  // Auto-sync al iniciar sesión
  ref.listen<AsyncValue<CurrentUser>>(currentUserProvider, (previous, next) {
    final wasLoggedOut = previous?.valueOrNull?.user == null;
    final isNowLoggedIn = next.valueOrNull?.user != null;
    if (wasLoggedOut && isNowLoggedIn) {
      notifier.sync();
    }
  });

  // Pull periódico cada 60 s — garantiza que tareas y permisos asignados por
  // admin aparezcan en el dispositivo del empleado aunque no tenga nada pendiente.
  // SyncNotifier.sync() ya protege contra ejecuciones concurrentes internamente.
  final periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
    final isOnline = ref.read(isOnlineProvider);
    final isLoggedIn =
        ref.read(currentUserProvider).valueOrNull?.user != null;
    if (isOnline && isLoggedIn) {
      notifier.sync();
    }
  });
  ref.onDispose(() => periodicTimer.cancel());

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
  return Stream<void>.periodic(const Duration(seconds: 5)).asyncMap((_) async {
    final pending = await syncRepo.getPending();
    return pending.length;
  });
});

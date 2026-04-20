import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/features/dashboard/domain/usecases/get_recent_events_use_case.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

// ── Workstations ─────────────────────────────────────────────────────────────

final workstationsStreamProvider =
    StreamProvider<List<WorkstationRecord>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllWorkstationRecords();
});

final workstationsProvider =
    FutureProvider<List<WorkstationRecord>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getAllWorkstationRecords();
});

// Map WorkstationRecord to domain Workstation
Workstation workstationRecordToEntity(WorkstationRecord record) {
  return Workstation(
    id: record.id,
    name: record.name,
    companyId: record.companyId,
    deviceId: record.deviceId,
  );
}

// ── Activity Events ──────────────────────────────────────────────────────────

final getRecentEventsUseCaseProvider =
    Provider<GetRecentEventsUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  final repo = ActivityRepositoryImpl(db, syncRepo);
  return GetRecentEventsUseCase(repo);
});

final recentEventsStreamProvider =
    StreamProvider<List<ActivityEvent>>((ref) {
  final useCase = ref.watch(getRecentEventsUseCaseProvider);
  return useCase.watch();
});

final recentEventsProvider =
    FutureProvider<List<ActivityEvent>>((ref) async {
  final useCase = ref.watch(getRecentEventsUseCaseProvider);
  return useCase(limit: 100);
});

// ── Last Event Per Workstation ───────────────────────────────────────────────

final lastEventByWorkstationProvider =
    Provider.family<ActivityEvent?, String>((ref, workstationId) {
  final eventsAsync = ref.watch(recentEventsStreamProvider);
  return eventsAsync.when(
    data: (events) {
      final filtered =
          events.where((e) => e.workstationId == workstationId).toList();
      if (filtered.isEmpty) return null;
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filtered.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Pending Sync Count ───────────────────────────────────────────────────────

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final pending = await syncRepo.getPending();
  return pending.length;
});

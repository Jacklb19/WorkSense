import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/features/dashboard/domain/usecases/get_recent_events_use_case.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';

// â”€â”€ Workstations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Activity Events â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final getRecentEventsUseCaseProvider =
    Provider<GetRecentEventsUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ActivityRepositoryImpl(db);
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

// â”€â”€ Last Event Per Workstation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Pending Sync Count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final repo = ActivityRepositoryImpl(db);
  final pending = await repo.getPendingSync();
  return pending.length;
});


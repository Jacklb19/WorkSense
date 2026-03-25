import 'package:drift/drift.dart' show Value;
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';
import 'sync_repository_impl.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  ActivityRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<void> saveEvent(ActivityEvent event) async {
    await _db.transaction(() async {
      // 1. Guardar localmente
      await _db.insertActivityEntry(_mapToCompanion(event));

      // 2. Encolar para sincronizaciÃ³n genÃ©rica
      await _syncRepo.enqueue(
        targetTable: 'activity_events',
        operation: 'UPSERT',
        recordId: event.id,
        payload: event.toMap(),
      );
    });
  }

  @override
  Future<List<ActivityEvent>> getRecentEvents({int limit = 50}) async {
    final rows = await _db.getRecentActivityEntries(limit);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<ActivityEvent>> watchEvents() =>
      _db.watchRecentActivityEntries()
          .map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<List<ActivityEvent>> getPendingSync() async {
    final rows = await _db.getPendingSyncEntries();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> markAsSynced(String eventId) =>
      _db.markActivityEntryAsSynced(eventId);

  @override
  Future<ActivityEvent?> getLastEventForWorkstation(
      String workstationId) async {
    final row = await _db.getLastEntryForWorkstation(workstationId);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<ActivityEvent>> getEventsForEmployee(
    String employeeId, {
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) async {
    final rows = await _db.getActivityEntriesForEmployee(
      employeeId,
      from: from,
      to: to,
      limit: limit,
    );
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<ActivityEvent>> getEventsByDateRange({
    required DateTime from,
    required DateTime to,
    int limit = 2000,
  }) async {
    final rows = await _db.getAllActivityEntriesByDateRange(
      from: from,
      to: to,
      limit: limit,
    );
    return rows.map(_mapToEntity).toList();
  }

  ActivityEvent _mapToEntity(ActivityEntry row) {
    return ActivityEvent(
      id: row.id,
      employeeId: row.employeeId,
      workstationId: row.workstationId,
      state: ActivityState.values.firstWhere(
        (e) => e.name == row.state,
        orElse: () => ActivityState.ausente,
      ),
      confidence: row.confidence,
      timestamp: row.timestamp,
      synced: row.synced,
      identityConfidence: row.identityConfidence,
      identificationMethod: row.identificationMethod,
    );
  }

  ActivityEntriesCompanion _mapToCompanion(ActivityEvent event) {
    return ActivityEntriesCompanion.insert(
      id: event.id,
      employeeId: Value(event.employeeId),
      workstationId: event.workstationId,
      state: event.state.name,
      confidence: event.confidence,
      timestamp: Value(event.timestamp),
      synced: Value(event.synced),
      identityConfidence: Value(event.identityConfidence),
      identificationMethod: Value(event.identificationMethod),
    );
  }
}

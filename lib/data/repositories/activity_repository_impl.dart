import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final AppDatabase _db;

  ActivityRepositoryImpl(this._db);

  @override
  Future<void> saveEvent(ActivityEvent event) async {
    await _db.insertActivityEntry(ActivityEntriesCompanion(
      id: Value(event.id),
      employeeId: Value(event.employeeId),
      workstationId: Value(event.workstationId),
      state: Value(event.state.name),
      confidence: Value(event.confidence),
      timestamp: Value(event.timestamp),
      synced: Value(event.synced),
    ));
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
    );
  }
}

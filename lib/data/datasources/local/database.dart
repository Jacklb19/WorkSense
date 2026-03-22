import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ─── Table Definitions ────────────────────────────────────────────────────────

class CompanyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EmployeeRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get companyId => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkstationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get companyId => text()();
  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityEntries extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get workstationId => text()();
  TextColumn get state => text()();
  RealColumn get confidence => real()();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get retries =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    CompanyRecords,
    EmployeeRecords,
    WorkstationRecords,
    ActivityEntries,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'worksense_db');
  }

  // ── ActivityEntries DAO methods ───────────────────────────────────────────

  Future<void> insertActivityEntry(ActivityEntriesCompanion entry) =>
      into(activityEntries).insert(entry);

  Future<List<ActivityEntry>> getRecentActivityEntries(int limit) =>
      (select(activityEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  Stream<List<ActivityEntry>> watchRecentActivityEntries() =>
      (select(activityEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(50))
          .watch();

  Future<List<ActivityEntry>> getPendingSyncEntries() =>
      (select(activityEntries)
            ..where((t) => t.synced.equals(false)))
          .get();

  Future<void> markActivityEntryAsSynced(String entryId) =>
      (update(activityEntries)..where((t) => t.id.equals(entryId)))
          .write(const ActivityEntriesCompanion(synced: Value(true)));

  Future<ActivityEntry?> getLastEntryForWorkstation(
      String workstationId) =>
      (select(activityEntries)
            ..where((t) => t.workstationId.equals(workstationId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .getSingleOrNull();

  // ── EmployeeRecords DAO methods ───────────────────────────────────────────

  Future<void> insertEmployeeRecord(EmployeeRecordsCompanion record) =>
      into(employeeRecords).insert(record,
          mode: InsertMode.insertOrReplace);

  Future<List<EmployeeRecord>> getAllEmployeeRecords() =>
      select(employeeRecords).get();

  Stream<List<EmployeeRecord>> watchAllEmployeeRecords() =>
      select(employeeRecords).watch();

  Future<EmployeeRecord?> getEmployeeRecordById(String id) =>
      (select(employeeRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> deleteEmployeeRecord(String id) =>
      (delete(employeeRecords)..where((t) => t.id.equals(id))).go();

  // ── WorkstationRecords DAO methods ────────────────────────────────────────

  Future<List<WorkstationRecord>> getAllWorkstationRecords() =>
      select(workstationRecords).get();

  Stream<List<WorkstationRecord>> watchAllWorkstationRecords() =>
      select(workstationRecords).watch();

  Future<void> insertWorkstationRecord(
          WorkstationRecordsCompanion record) =>
      into(workstationRecords).insert(record,
          mode: InsertMode.insertOrReplace);

  // ── SyncQueueEntries methods ──────────────────────────────────────────────

  Future<void> insertSyncQueueEntry(SyncQueueEntriesCompanion entry) =>
      into(syncQueueEntries).insert(entry);

  Future<List<SyncQueueEntry>> getPendingSyncQueueEntries() =>
      select(syncQueueEntries).get();

  Future<void> deleteSyncQueueEntry(String id) =>
      (delete(syncQueueEntries)..where((t) => t.id.equals(id))).go();
}

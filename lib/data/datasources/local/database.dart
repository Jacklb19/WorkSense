import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ─── Table Definitions ────────────────────────────────────────────────────────

class CompanyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EmployeeRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get companyId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkstationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get companyId => text()();
  TextColumn get deviceId => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get geofenceRadius => real().nullable()();

  // Perfil biométrico del empleado asignado
  TextColumn get assignedEmployeeId => text().nullable()();
  TextColumn get faceEmbedding => text().nullable()();
  TextColumn get bodySignature => text().nullable()();
  DateTimeColumn get profileCapturedAt => dateTime().nullable()();
  IntColumn get profileVersion =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityEntries extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get workstationId => text()();
  TextColumn get state => text()();
  RealColumn get confidence => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  // Re-identificación
  RealColumn get identityConfidence => real().nullable()();
  TextColumn get identificationMethod => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get recordId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(workstationRecords, workstationRecords.latitude);
        await m.addColumn(workstationRecords, workstationRecords.longitude);
        await m.addColumn(workstationRecords, workstationRecords.geofenceRadius);
      }
      if (from < 3) {
        await m.createTable(syncQueueEntries); // ← FALTABA ESTO

        await customStatement(
            'ALTER TABLE workstation_records ADD COLUMN assigned_employee_id TEXT');
        await customStatement(
            'ALTER TABLE workstation_records ADD COLUMN face_embedding TEXT');
        await customStatement(
            'ALTER TABLE workstation_records ADD COLUMN body_signature TEXT');
        await customStatement(
            'ALTER TABLE workstation_records ADD COLUMN profile_captured_at INTEGER');
        await customStatement(
            'ALTER TABLE workstation_records ADD COLUMN profile_version INTEGER NOT NULL DEFAULT 0');
        await customStatement(
            'ALTER TABLE activity_entries ADD COLUMN identity_confidence REAL');
        await customStatement(
            'ALTER TABLE activity_entries ADD COLUMN identification_method TEXT');
      }
    },
  );

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
      (select(activityEntries)..where((t) => t.synced.equals(false))).get();

  Future<void> markActivityEntryAsSynced(String entryId) =>
      (update(activityEntries)..where((t) => t.id.equals(entryId)))
          .write(const ActivityEntriesCompanion(synced: Value(true)));

  Future<ActivityEntry?> getLastEntryForWorkstation(String workstationId) =>
      (select(activityEntries)
            ..where((t) => t.workstationId.equals(workstationId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .getSingleOrNull();

  // ── Analytics queries ─────────────────────────────────────────────────────

  Future<List<ActivityEntry>> getActivityEntriesForEmployee(
    String employeeId, {
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) =>
      (select(activityEntries)
            ..where((t) {
              var predicate = t.employeeId.equals(employeeId);
              if (from != null) predicate = predicate & t.timestamp.isBiggerOrEqualValue(from);
              if (to != null) predicate = predicate & t.timestamp.isSmallerOrEqualValue(to);
              return predicate;
            })
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  Stream<List<ActivityEntry>> watchActivityEntriesForEmployee(
    String employeeId, {
    int limit = 10,
  }) =>
      (select(activityEntries)
            ..where((t) => t.employeeId.equals(employeeId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .watch();

  Future<List<ActivityEntry>> getAllActivityEntriesByDateRange({
    required DateTime from,
    required DateTime to,
    int limit = 2000,
  }) =>
      (select(activityEntries)
            ..where((t) =>
                t.employeeId.isNotNull() &
                t.timestamp.isBiggerOrEqualValue(from) &
                t.timestamp.isSmallerOrEqualValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  // ── EmployeeRecords DAO methods ───────────────────────────────────────────

  Future<void> insertEmployeeRecord(EmployeeRecordsCompanion record) =>
      into(employeeRecords).insert(record, mode: InsertMode.insertOrReplace);

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

  Future<void> insertWorkstationRecord(WorkstationRecordsCompanion record) =>
      into(workstationRecords).insert(record, mode: InsertMode.insertOrReplace);

  Future<WorkstationRecord?> getWorkstationById(String id) =>
      (select(workstationRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> saveEmployeeProfile({
    required String workstationId,
    required String employeeId,
    required String faceEmbeddingJson,
    required String bodySignatureJson,
  }) =>
      (update(workstationRecords)..where((t) => t.id.equals(workstationId)))
          .write(WorkstationRecordsCompanion(
        assignedEmployeeId: Value(employeeId),
        faceEmbedding: Value(faceEmbeddingJson),
        bodySignature: Value(bodySignatureJson),
        profileCapturedAt: Value(DateTime.now()),
        profileVersion: const Value(1),
      ));

  Future<void> clearEmployeeProfile(String workstationId) =>
      (update(workstationRecords)..where((t) => t.id.equals(workstationId)))
          .write(const WorkstationRecordsCompanion(
        assignedEmployeeId: Value(null),
        faceEmbedding: Value(null),
        bodySignature: Value(null),
        profileCapturedAt: Value(null),
        profileVersion: Value(0),
      ));

  // ── SyncQueueEntries methods ──────────────────────────────────────────────

  Future<void> insertSyncQueueEntry(SyncQueueEntriesCompanion entry) =>
      into(syncQueueEntries).insert(entry);

  Future<List<SyncQueueEntry>> getPendingSyncQueueEntries() =>
      select(syncQueueEntries).get();

  Future<void> deleteSyncQueueEntry(int id) =>
      (delete(syncQueueEntries)..where((t) => t.id.equals(id))).go();

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'worksense_db');
  }
}

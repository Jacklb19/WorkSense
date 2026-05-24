import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

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
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant('EMPLOYEE'))();
  TextColumn get companyId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get faceEmbeddings => text().named('face_embedding').nullable()();
  TextColumn get shiftId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShiftRecordData')
class ShiftRecords extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  IntColumn get startHour => integer()();
  IntColumn get startMinute => integer()();
  IntColumn get endHour => integer()();
  IntColumn get endMinute => integer()();
  IntColumn get breakStartHour => integer().nullable()();
  IntColumn get breakStartMinute => integer().nullable()();
  IntColumn get breakEndHour => integer().nullable()();
  IntColumn get breakEndMinute => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceLogData')
class AttendanceLogs extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text()();
  TextColumn get workstationId => text().nullable()();
  TextColumn get companyId => text()();
  DateTimeColumn get shiftDate => dateTime()();
  DateTimeColumn get clockInTime => dateTime()();
  DateTimeColumn get clockOutTime => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('ON_TIME'))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

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
  TextColumn get assignedEmployeeId => text().nullable()();
  TextColumn get faceEmbeddings => text().named('face_embedding').nullable()();
  TextColumn get bodySignature => text().nullable()();
  DateTimeColumn get profileCapturedAt => dateTime().nullable()();
  IntColumn get profileVersion => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('IDLE'))();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityEntries extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get workstationId => text()();
  TextColumn get companyId => text().nullable()();
  TextColumn get state => text()();
  RealColumn get confidence => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
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

@DriftDatabase(
  tables: [
    CompanyRecords,
    EmployeeRecords,
    WorkstationRecords,
    ActivityEntries,
    SyncQueueEntries,
    ShiftRecords,
    AttendanceLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static const String _workstationRoiTable = 'workstation_roi_cache';
  static const String _profileSnapshotTable = 'workstation_profile_snapshots';
  static const String _dailySummaryTable = 'daily_work_summaries';
  static const String _activityRollupTable = 'activity_rollups';

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createAuxiliaryTables();
        },
        onUpgrade: (m, from, to) async {
          final migrator = m;

          if (from < 2) {
            await migrator.addColumn(workstationRecords, workstationRecords.latitude);
            await migrator.addColumn(workstationRecords, workstationRecords.longitude);
            await migrator.addColumn(workstationRecords, workstationRecords.geofenceRadius);
          }

          if (from < 3) {
            await migrator.createTable(syncQueueEntries);
            await migrator.addColumn(workstationRecords, workstationRecords.assignedEmployeeId);
            await migrator.addColumn(workstationRecords, workstationRecords.faceEmbeddings);
            await migrator.addColumn(workstationRecords, workstationRecords.bodySignature);
            await migrator.addColumn(workstationRecords, workstationRecords.profileCapturedAt);
            await migrator.addColumn(workstationRecords, workstationRecords.profileVersion);
            await migrator.addColumn(activityEntries, activityEntries.identityConfidence);
            await migrator.addColumn(activityEntries, activityEntries.identificationMethod);
          }

          if (from < 4) {
            await migrator.addColumn(employeeRecords, employeeRecords.faceEmbeddings);
          }

          if (from < 5) {
            await migrator.addColumn(workstationRecords, workstationRecords.status);
          }

          if (from < 6) {
            await migrator.addColumn(employeeRecords, employeeRecords.shiftId);
            await migrator.createTable(shiftRecords);
            await migrator.createTable(attendanceLogs);
          }

          if (from < 7) {
            await migrator.addColumn(shiftRecords, shiftRecords.breakStartHour);
            await migrator.addColumn(shiftRecords, shiftRecords.breakStartMinute);
            await migrator.addColumn(shiftRecords, shiftRecords.breakEndHour);
            await migrator.addColumn(shiftRecords, shiftRecords.breakEndMinute);
          }

          if (from < 8) {
            await migrator.addColumn(activityEntries, activityEntries.companyId);
          }

          if (from < 12) {
            await migrator.addColumn(employeeRecords, employeeRecords.lastName);
            await migrator.addColumn(employeeRecords, employeeRecords.email);
            await migrator.addColumn(employeeRecords, employeeRecords.role);
          }

          await _createAuxiliaryTables();
        },
      );

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

  Future<List<ActivityEntry>> getActivityEntriesForEmployee(
    String employeeId, {
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) =>
      (select(activityEntries)
            ..where((t) {
              var predicate = t.employeeId.equals(employeeId);
              if (from != null) {
                predicate = predicate & t.timestamp.isBiggerOrEqualValue(from);
              }
              if (to != null) {
                predicate = predicate & t.timestamp.isSmallerOrEqualValue(to);
              }
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

  Future<void> insertEmployeeRecord(EmployeeRecordsCompanion record) =>
      into(employeeRecords).insert(record, mode: InsertMode.insertOrReplace);

  Future<List<EmployeeRecord>> getAllEmployeeRecords() => select(employeeRecords).get();

  Stream<List<EmployeeRecord>> watchAllEmployeeRecords() => select(employeeRecords).watch();

  Future<EmployeeRecord?> getEmployeeRecordById(String id) =>
      (select(employeeRecords)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateEmployeeEmbedding(String employeeId, String faceEmbeddingJson) =>
      (update(employeeRecords)..where((t) => t.id.equals(employeeId))).write(
        EmployeeRecordsCompanion(faceEmbeddings: Value(faceEmbeddingJson)),
      );

  Future<void> deleteEmployeeRecord(String id) =>
      (delete(employeeRecords)..where((t) => t.id.equals(id))).go();

  Future<List<WorkstationRecord>> getAllWorkstationRecords() =>
      select(workstationRecords).get();

  Stream<List<WorkstationRecord>> watchAllWorkstationRecords() =>
      select(workstationRecords).watch();

  Future<void> insertWorkstationRecord(WorkstationRecordsCompanion record) =>
      into(workstationRecords).insert(record, mode: InsertMode.insertOrReplace);

  Future<WorkstationRecord?> getWorkstationById(String id) =>
      (select(workstationRecords)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> saveEmployeeProfile({
    required String workstationId,
    required String employeeId,
    required String faceEmbeddingJson,
    required String bodySignatureJson,
    int profileVersion = 1,
  }) =>
      (update(workstationRecords)..where((t) => t.id.equals(workstationId))).write(
        WorkstationRecordsCompanion(
          assignedEmployeeId: Value(employeeId),
          faceEmbeddings: Value(faceEmbeddingJson),
          bodySignature: Value(bodySignatureJson),
          profileCapturedAt: Value(DateTime.now()),
          profileVersion: Value(profileVersion),
        ),
      );

  Future<void> clearEmployeeProfile(String workstationId) async {
    await (update(workstationRecords)..where((t) => t.id.equals(workstationId))).write(
      const WorkstationRecordsCompanion(
        assignedEmployeeId: Value(null),
        faceEmbeddings: Value(null),
        bodySignature: Value(null),
        profileCapturedAt: Value(null),
        profileVersion: Value(0),
      ),
    );
    await deleteProfileSnapshot(workstationId);
  }

  Future<void> clearWorkstationProfilesByEmployeeId(String employeeId) async {
    final impacted = await (select(workstationRecords)
          ..where((t) => t.assignedEmployeeId.equals(employeeId)))
        .get();
    await (update(workstationRecords)..where((t) => t.assignedEmployeeId.equals(employeeId))).write(
      const WorkstationRecordsCompanion(
        assignedEmployeeId: Value(null),
        faceEmbeddings: Value(null),
        bodySignature: Value(null),
        profileCapturedAt: Value(null),
        profileVersion: Value(0),
      ),
    );
    for (final row in impacted) {
      await deleteProfileSnapshot(row.id);
    }
  }

  Future<void> insertSyncQueueEntry(SyncQueueEntriesCompanion entry) =>
      into(syncQueueEntries).insert(entry);

  Future<List<SyncQueueEntry>> getPendingSyncQueueEntries() =>
      select(syncQueueEntries).get();

  Future<void> deleteSyncQueueEntry(int id) =>
      (delete(syncQueueEntries)..where((t) => t.id.equals(id))).go();

  Future<void> insertShiftRecord(ShiftRecordsCompanion record) =>
      into(shiftRecords).insert(record, mode: InsertMode.insertOrReplace);

  Future<ShiftRecordData?> getShiftById(String id) =>
      (select(shiftRecords)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ShiftRecordData>> getShiftsByCompany(String companyId) =>
      (select(shiftRecords)..where((t) => t.companyId.equals(companyId))).get();

  Future<void> insertAttendanceLog(AttendanceLogsCompanion log) =>
      into(attendanceLogs).insert(log, mode: InsertMode.insertOrReplace);

  Future<void> updateAttendanceLog(AttendanceLogsCompanion log) =>
      (update(attendanceLogs)..where((t) => t.id.equals(log.id.value))).write(log);

  Future<AttendanceLogData?> getOpenAttendanceLogForEmployee(
    String employeeId,
    DateTime today,
  ) =>
      (select(attendanceLogs)
            ..where((t) =>
                t.employeeId.equals(employeeId) &
                t.clockOutTime.isNull() &
                t.shiftDate.equals(today))
            ..orderBy([(t) => OrderingTerm.desc(t.clockInTime)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<AttendanceLogData>> getEmployeeLogsForDate(
    String employeeId,
    DateTime date,
  ) =>
      (select(attendanceLogs)
            ..where((t) => t.employeeId.equals(employeeId) & t.shiftDate.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.clockInTime)]))
          .get();

  Future<List<AttendanceLogData>> getEmployeeAttendanceLogs(
    String employeeId,
    DateTime start,
    DateTime end,
  ) =>
      (select(attendanceLogs)
            ..where((t) =>
                t.employeeId.equals(employeeId) &
                t.shiftDate.isBiggerOrEqualValue(start) &
                t.shiftDate.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.shiftDate)]))
          .get();

  Stream<List<AttendanceLogData>> watchAttendanceLogs() => select(attendanceLogs).watch();

  Future<List<ActivityEntry>> getActivityEntriesForEmployeeDay(
    String employeeId,
    DateTime dayStart,
    DateTime dayEnd,
  ) =>
      (select(activityEntries)
            ..where((t) =>
                t.employeeId.equals(employeeId) &
                t.timestamp.isBiggerOrEqualValue(dayStart) &
                t.timestamp.isSmallerThanValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  Future<List<ActivityEntry>> getSyncedActivityEntriesBefore(DateTime threshold) =>
      (select(activityEntries)
            ..where((t) => t.synced.equals(true) & t.timestamp.isSmallerThanValue(threshold))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  Future<void> deleteActivityEntriesByIds(Iterable<String> ids) async {
    for (final id in ids) {
      await (delete(activityEntries)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<void> saveWorkstationRoi(String workstationId, String roiJson) async {
    await customStatement(
      'INSERT OR REPLACE INTO $_workstationRoiTable (workstation_id, roi_json) VALUES (?, ?)',
      [workstationId, roiJson],
    );
  }

  Future<String?> getWorkstationRoi(String workstationId) async {
    final rows = await customSelect(
      'SELECT roi_json FROM $_workstationRoiTable WHERE workstation_id = ?',
      variables: [Variable<String>(workstationId)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<String>('roi_json');
  }

  Future<void> saveProfileSnapshot(String workstationId, String profileJson) async {
    await customStatement(
      'INSERT OR REPLACE INTO $_profileSnapshotTable (workstation_id, profile_json) VALUES (?, ?)',
      [workstationId, profileJson],
    );
  }

  Future<String?> getProfileSnapshot(String workstationId) async {
    final rows = await customSelect(
      'SELECT profile_json FROM $_profileSnapshotTable WHERE workstation_id = ?',
      variables: [Variable<String>(workstationId)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<String>('profile_json');
  }

  Future<void> deleteProfileSnapshot(String workstationId) async {
    await customStatement(
      'DELETE FROM $_profileSnapshotTable WHERE workstation_id = ?',
      [workstationId],
    );
  }

  Future<void> upsertDailySummaryPayload(
    String id,
    String payloadJson, {
    required DateTime updatedAt,
    bool synced = false,
  }) async {
    await customStatement(
      'INSERT OR REPLACE INTO $_dailySummaryTable (id, payload_json, synced, updated_at) VALUES (?, ?, ?, ?)',
      [id, payloadJson, synced ? 1 : 0, updatedAt.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingDailySummaryPayloads() async {
    final rows = await customSelect(
      'SELECT id, payload_json FROM $_dailySummaryTable WHERE synced = 0',
    ).get();
    return rows
        .map(
          (row) => {
            'id': row.read<String>('id'),
            'payload_json': row.read<String>('payload_json'),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getDailySummaryPayloadsForEmployee(
    String employeeId,
  ) async {
    final rows = await customSelect(
      "SELECT id, payload_json, synced, updated_at FROM $_dailySummaryTable "
      "WHERE json_extract(payload_json, '\$.employee_id') = ? "
      "ORDER BY json_extract(payload_json, '\$.work_date') DESC",
      variables: [Variable<String>(employeeId)],
    ).get();
    return rows
        .map(
          (row) => {
            'id': row.read<String>('id'),
            'payload_json': row.read<String>('payload_json'),
            'synced': row.read<int>('synced') == 1,
            'updated_at': row.read<String>('updated_at'),
          },
        )
        .toList();
  }

  Future<void> markDailySummaryPayloadSynced(String id) async {
    await customStatement(
      'UPDATE $_dailySummaryTable SET synced = 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> upsertActivityRollupPayload(
    String id,
    String payloadJson, {
    required DateTime updatedAt,
    bool synced = false,
  }) async {
    await customStatement(
      'INSERT OR REPLACE INTO $_activityRollupTable (id, payload_json, synced, updated_at) VALUES (?, ?, ?, ?)',
      [id, payloadJson, synced ? 1 : 0, updatedAt.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingActivityRollupPayloads() async {
    final rows = await customSelect(
      'SELECT id, payload_json FROM $_activityRollupTable WHERE synced = 0',
    ).get();
    return rows
        .map(
          (row) => {
            'id': row.read<String>('id'),
            'payload_json': row.read<String>('payload_json'),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getActivityRollupPayloadsForEmployee(
    String employeeId,
  ) async {
    final rows = await customSelect(
      "SELECT id, payload_json, synced, updated_at FROM $_activityRollupTable "
      "WHERE json_extract(payload_json, '\$.employee_id') = ? "
      "ORDER BY json_extract(payload_json, '\$.window_start') DESC",
      variables: [Variable<String>(employeeId)],
    ).get();
    return rows
        .map(
          (row) => {
            'id': row.read<String>('id'),
            'payload_json': row.read<String>('payload_json'),
            'synced': row.read<int>('synced') == 1,
            'updated_at': row.read<String>('updated_at'),
          },
        )
        .toList();
  }

  Future<void> markActivityRollupPayloadSynced(String id) async {
    await customStatement(
      'UPDATE $_activityRollupTable SET synced = 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> _createAuxiliaryTables() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS $_workstationRoiTable (workstation_id TEXT PRIMARY KEY, roi_json TEXT NOT NULL)',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS $_profileSnapshotTable (workstation_id TEXT PRIMARY KEY, profile_json TEXT NOT NULL)',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS $_dailySummaryTable (id TEXT PRIMARY KEY, payload_json TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL)',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS $_activityRollupTable (id TEXT PRIMARY KEY, payload_json TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'worksense_db');
  }
}

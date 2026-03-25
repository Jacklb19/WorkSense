import 'dart:convert';
import 'package:drift/drift.dart';
import '../datasources/local/database.dart';

class SyncRepositoryImpl {
  final AppDatabase _db;
  SyncRepositoryImpl(this._db);

  Future<void> enqueue({
    required String targetTable,
    required String operation,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueueEntries).insert(
      SyncQueueEntriesCompanion.insert(
        targetTable: targetTable,
        operation: operation,
        recordId: recordId,
        payload: jsonEncode(payload),
      ),
    );
  }

  Future<List<SyncQueueEntry>> getPending() {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markSynced(int id) {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.id.equals(id)))
        .write(const SyncQueueEntriesCompanion(isSynced: Value(true)));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.syncQueueEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}

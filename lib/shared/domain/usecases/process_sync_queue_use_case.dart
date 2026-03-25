import 'dart:convert';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';

class ProcessSyncQueueUseCase {
  final AppDatabase _db;
  final SupabaseDataSource _remoteDataSource;

  ProcessSyncQueueUseCase(this._db, this._remoteDataSource);

  Future<int> call() async {
    final entries = await _db.getPendingSyncQueueEntries();
    int processedCount = 0;

    for (final entry in entries) {
      try {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

        switch (entry.targetTable) {
          case 'workstations':
            if (entry.operation == 'UPSERT') {
              await _remoteDataSource.upsertWorkstation(payload);
            } else if (entry.operation == 'DELETE') {
              await _remoteDataSource.deleteWorkstationById(entry.recordId);
            }
        }

        await _db.deleteSyncQueueEntry(entry.id);
        processedCount++;
      } catch (_) {
        // Dejar en cola para el próximo intento de sync
      }
    }

    return processedCount;
  }
}

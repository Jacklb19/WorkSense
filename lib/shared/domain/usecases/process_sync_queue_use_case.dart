import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../data/datasources/remote/supabase_datasource.dart';
import '../../../data/repositories/sync_repository_impl.dart';

class ProcessSyncQueueUseCase {
  final SyncRepositoryImpl _syncRepo;
  final SupabaseDataSource _remote;

  ProcessSyncQueueUseCase(this._syncRepo, this._remote);

  Future<SyncResult> call() async {
    final pending = await _syncRepo.getPending();
    int success = 0;
    final List<String> errors = [];

    for (final entry in pending) {
      try {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

        switch (entry.operation) {
          case 'UPSERT':
            await _remote.upsert(entry.targetTable , payload);
            break;
          case 'DELETE':
            await _remote.delete(entry.targetTable , entry.recordId);
            break;
        }

        await _syncRepo.delete(entry.id); // limpia la cola al sincronizar
        success++;
      } on SyncException catch (e) {
        errors.add('Entry ${entry.id} (${entry.targetTable }): ${e.message}');
        debugPrint('[Sync Error] $e');
      } catch (e) {
        errors.add('Unexpected error on entry ${entry.id}: $e');
        debugPrint('[Sync Unexpected Error] $e');
      }
    }

    return SyncResult(synced: success, errors: errors, total: pending.length);
  }
}

class SyncResult {
  final int synced;
  final int total;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;

  SyncResult({required this.synced, required this.errors, required this.total});
}

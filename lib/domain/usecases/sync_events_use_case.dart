import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';

class SyncEventsUseCase {
  final ActivityRepository _repository;
  final SupabaseDataSource _remoteDataSource;

  SyncEventsUseCase(this._repository, this._remoteDataSource);

  Future<int> call() async {
    final pendingEvents = await _repository.getPendingSync();
    int syncedCount = 0;

    for (final event in pendingEvents) {
      try {
        await _remoteDataSource.insertActivityEvent(event.toMap());
        await _repository.markAsSynced(event.id);
        syncedCount++;
      } catch (_) {
        // Continue with next event; failed events remain pending
      }
    }

    return syncedCount;
  }
}

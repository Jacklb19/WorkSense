import 'package:worksense_app/domain/entities/activity_event.dart';

abstract class ActivityRepository {
  Future<void> saveEvent(ActivityEvent event);

  Future<List<ActivityEvent>> getRecentEvents({int limit = 50});

  Stream<List<ActivityEvent>> watchEvents();

  Future<List<ActivityEvent>> getPendingSync();

  Future<void> markAsSynced(String eventId);

  Future<ActivityEvent?> getLastEventForWorkstation(String workstationId);
}

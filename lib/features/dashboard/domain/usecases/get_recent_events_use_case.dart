import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';

class GetRecentEventsUseCase {
  final ActivityRepository _repository;

  GetRecentEventsUseCase(this._repository);

  Future<List<ActivityEvent>> call({int limit = 50}) =>
      _repository.getRecentEvents(limit: limit);

  Stream<List<ActivityEvent>> watch() => _repository.watchEvents();
}

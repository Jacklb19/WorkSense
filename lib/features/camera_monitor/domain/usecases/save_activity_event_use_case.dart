import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';

class SaveActivityEventUseCase {
  final ActivityRepository _repository;

  SaveActivityEventUseCase(this._repository);

  Future<void> call(ActivityEvent event) => _repository.saveEvent(event);
}

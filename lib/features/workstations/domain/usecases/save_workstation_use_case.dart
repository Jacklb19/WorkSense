import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/domain/repositories/workstation_repository.dart';

class SaveWorkstationUseCase {
  final WorkstationRepository _repository;

  SaveWorkstationUseCase(this._repository);

  Future<void> call(Workstation workstation) {
    return _repository.saveWorkstation(workstation);
  }
}

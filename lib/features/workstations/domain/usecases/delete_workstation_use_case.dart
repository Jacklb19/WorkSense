import 'package:worksense_app/domain/repositories/workstation_repository.dart';

class DeleteWorkstationUseCase {
  final WorkstationRepository _repository;

  DeleteWorkstationUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteWorkstation(id);
  }
}

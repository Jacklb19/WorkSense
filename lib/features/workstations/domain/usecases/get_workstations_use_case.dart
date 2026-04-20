import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/domain/repositories/workstation_repository.dart';

class GetWorkstationsUseCase {
  final WorkstationRepository _repository;

  GetWorkstationsUseCase(this._repository);

  Stream<List<Workstation>> call() {
    return _repository.watchWorkstations();
  }
}

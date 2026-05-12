import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';

class SaveShiftUseCase {
  final ShiftRepository _repository;

  SaveShiftUseCase(this._repository);

  Future<void> call(Shift shift) {
    return _repository.createShift(shift);
  }
}

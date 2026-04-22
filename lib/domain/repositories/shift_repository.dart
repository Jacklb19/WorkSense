import 'package:worksense_app/domain/entities/shift.dart';

abstract class ShiftRepository {
  Future<void> saveShift(Shift shift);
  Future<List<Shift>> getShifts();
  Stream<List<Shift>> watchShifts();
  Future<Shift?> getShiftById(String id);
  Future<void> deleteShift(String id);
  Stream<List<Shift>> watchShiftsByEmployee(String employeeId);
}

import 'package:worksense_app/domain/entities/shift.dart';

abstract class ShiftRepository {
  /// Obtiene todos los turnos disponibles para una empresa
  Future<List<Shift>> getShifts(String companyId);
  
  /// Obtiene un turno específico
  Future<Shift?> getShiftById(String shiftId);

  /// Obtiene el turno asignado a un empleado
  Future<Shift?> getShiftForEmployee(String employeeId);

  /// Crea un nuevo turno en la nube y local
  Future<void> createShift(Shift shift);

  /// Actualiza un turno existente
  Future<void> updateShift(Shift shift);

  /// Asigna un turno a un empleado
  Future<void> assignShiftToEmployee(String employeeId, String shiftId);
}

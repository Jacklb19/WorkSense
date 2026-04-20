import 'package:worksense_app/domain/entities/attendance_log.dart';

abstract class AttendanceRepository {
  /// Registra un ingreso al sistema ("Clock-In")
  Future<void> clockIn({
    required String employeeId,
    required String companyId,
    String? workstationId,
  });

  /// Registra una salida del sistema ("Clock-Out")
  Future<void> clockOut({
    required String employeeId,
    String? workstationId,
  });

  /// Verifica si el empleado tiene una sesión de tiempo abierta hoy
  /// Retorna el AttendanceLog si está adentro, null si está afuera
  Future<AttendanceLog?> getOpenSession(String employeeId);

  /// Obtiene todas las sesiones registradas hoy para poder contar las entradas
  Future<List<AttendanceLog>> getTodaySessions(String employeeId);

  /// Obtiene todo el historial de asistencia de un empleado en un rango
  Future<List<AttendanceLog>> getEmployeeLogs(String employeeId, DateTime start, DateTime end);
}

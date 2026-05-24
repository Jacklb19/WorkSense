import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';

abstract class EmployeeRepository {
  Future<void> saveEmployee(Employee employee);

  Future<List<Employee>> getEmployees();

  Stream<List<Employee>> watchEmployees();

  Future<Employee?> getEmployeeById(String id);

  Future<void> deleteEmployee(String id);

  /// Persiste el embedding facial tanto local como remotamente (vía cola de sincronización).
  Future<void> saveFaceEmbedding(String employeeId, List<double> embedding);

  /// Orquesta el enrolamiento completo del empleado en una workstation.
  /// Actualiza tanto el registro central del empleado como el perfil local de la estación.
  Future<void> enrollEmployee({
    required String employeeId,
    required String workstationId,
    required List<List<double>>? faceEmbeddings,
    required BodySignature bodySignature,
    EmployeeProfile? profile,
  });
}



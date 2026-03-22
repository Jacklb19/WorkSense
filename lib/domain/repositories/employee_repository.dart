import 'package:worksense_app/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<void> saveEmployee(Employee employee);

  Future<List<Employee>> getEmployees();

  Stream<List<Employee>> watchEmployees();

  Future<Employee?> getEmployeeById(String id);

  Future<void> deleteEmployee(String id);
}

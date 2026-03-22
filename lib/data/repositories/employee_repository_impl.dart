import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final AppDatabase _db;

  EmployeeRepositoryImpl(this._db);

  @override
  Future<void> saveEmployee(Employee employee) async {
    await _db.insertEmployeeRecord(EmployeeRecordsCompanion(
      id: Value(employee.id),
      name: Value(employee.name),
      companyId: Value(employee.companyId),
      createdAt: Value(employee.createdAt),
    ));
  }

  @override
  Future<List<Employee>> getEmployees() async {
    final rows = await _db.getAllEmployeeRecords();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Employee>> watchEmployees() =>
      _db.watchAllEmployeeRecords()
          .map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final row = await _db.getEmployeeRecordById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> deleteEmployee(String id) => _db.deleteEmployeeRecord(id);

  Employee _mapToEntity(EmployeeRecord row) {
    return Employee(
      id: row.id,
      name: row.name,
      companyId: row.companyId,
      createdAt: row.createdAt,
    );
  }
}

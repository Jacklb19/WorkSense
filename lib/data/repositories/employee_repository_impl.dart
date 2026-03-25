import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'sync_repository_impl.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  EmployeeRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<void> saveEmployee(Employee employee) async {
    await _db.transaction(() async {
      // 1. Guardar localmente
      await _db.insertEmployeeRecord(EmployeeRecordsCompanion(
        id: Value(employee.id),
        name: Value(employee.name),
        companyId: Value(employee.companyId),
        createdAt: Value(employee.createdAt),
      ));

      // 2. Encolar para sincronización
      await _syncRepo.enqueue(
        targetTable: 'employees',
        operation: 'UPSERT',
        recordId: employee.id,
        payload: employee.toMap(),
      );
    });
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
  Future<void> deleteEmployee(String id) async {
    await _db.transaction(() async {
      // 1. Eliminar localmente
      await _db.deleteEmployeeRecord(id);

      // 2. Encolar eliminación
      await _syncRepo.enqueue(
        targetTable: 'employees',
        operation: 'DELETE',
        recordId: id,
        payload: {},
      );
    });
  }

  Employee _mapToEntity(EmployeeRecord row) {
    return Employee(
      id: row.id,
      name: row.name,
      companyId: row.companyId,
      createdAt: row.createdAt,
    );
  }
}

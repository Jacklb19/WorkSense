import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:worksense_app/core/utils/biometric_utils.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
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

  @override
  Future<void> saveFaceEmbedding(String employeeId, List<double> embedding) async {
    final jsonEmbedding = BiometricSerializer.serializeEmbedding(embedding);

    await _db.transaction(() async {
      // 1. Persistencia local
      await _db.updateEmployeeEmbedding(employeeId, jsonEmbedding);

      // (Nota: No se sincroniza face_embedding hacia la tabla 'employees' en Supabase
      // porque esta base de datos centralizada guarda los embeddings en 'workstations'.)
    });
  }

  @override
  Future<void> enrollEmployee({
    required String employeeId,
    required String workstationId,
    required List<double> faceEmbedding,
    required BodySignature bodySignature,
  }) async {
    final faceEmbeddingJson = BiometricSerializer.serializeEmbedding(faceEmbedding);
    final bodySignatureJson = jsonEncode(bodySignature.toJson());

    await _db.transaction(() async {
      // 1. Guardar perfil en la workstation localmente
      await _db.saveEmployeeProfile(
        workstationId: workstationId,
        employeeId: employeeId,
        faceEmbeddingJson: faceEmbeddingJson,
        bodySignatureJson: bodySignatureJson,
      );

      // 2. Actualizar embedding central del empleado localmente
      await _db.updateEmployeeEmbedding(employeeId, faceEmbeddingJson);

      // 3. Encolar actualizaciones remotas
      // 3.1 Actualización de la workstation en Supabase con los biométricos
      await _syncRepo.enqueue(
        targetTable: 'workstations',
        operation: 'PATCH',
        recordId: workstationId,
        payload: {
          'assigned_employee_id': employeeId,
          'face_embedding': faceEmbeddingJson,
          'body_signature': bodySignatureJson,
        },
      );
    });
  }

  Employee _mapToEntity(EmployeeRecord row) {
    return Employee(
      id: row.id,
      name: row.name,
      companyId: row.companyId,
      createdAt: row.createdAt,
      faceEmbedding: BiometricSerializer.deserializeEmbedding(row.faceEmbedding),
    );
  }
}



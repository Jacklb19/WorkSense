import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/domain/repositories/workstation_repository.dart';
import 'sync_repository_impl.dart';

class WorkstationRepositoryImpl implements WorkstationRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  WorkstationRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<void> saveWorkstation(Workstation workstation) async {
    await _db.transaction(() async {
      // 1. Guardar localmente
      await _db.insertWorkstationRecord(WorkstationRecordsCompanion(
        id: Value(workstation.id),
        name: Value(workstation.name),
        companyId: Value(workstation.companyId),
        deviceId: Value(workstation.deviceId),
        latitude: Value(workstation.latitude),
        longitude: Value(workstation.longitude),
        geofenceRadius: Value(workstation.geofenceRadius),
        assignedEmployeeId: Value(workstation.assignedEmployeeId),
      ));

      // 2. Encolar para sincronizaciÃ³n
      await _syncRepo.enqueue(
        targetTable: 'workstations',
        operation: 'UPSERT',
        recordId: workstation.id,
        payload: workstation.toMap(),
      );
    });
  }

  @override
  Stream<List<Workstation>> watchWorkstations() {
    return _db.watchAllWorkstationRecords().map(
          (rows) => rows.map(_mapToEntity).toList(),
        );
  }

  @override
  Future<void> deleteWorkstation(String id) async {
    await _db.transaction(() async {
      // 1. Eliminar localmente
      await (_db.delete(_db.workstationRecords)..where((t) => t.id.equals(id))).go();

      // 2. Encolar eliminaciÃ³n
      await _syncRepo.enqueue(
        targetTable: 'workstations',
        operation: 'DELETE',
        recordId: id,
        payload: {'id': id},
      );
    });
  }

  Workstation _mapToEntity(WorkstationRecord row) {
    return Workstation(
      id: row.id,
      name: row.name,
      companyId: row.companyId,
      deviceId: row.deviceId,
      latitude: row.latitude,
      longitude: row.longitude,
      geofenceRadius: row.geofenceRadius,
      assignedEmployeeId: row.assignedEmployeeId,
    );
  }
}

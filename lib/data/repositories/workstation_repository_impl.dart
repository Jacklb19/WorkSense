import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/domain/repositories/workstation_repository.dart';

class WorkstationRepositoryImpl implements WorkstationRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  WorkstationRepositoryImpl(this._db);

  @override
  Future<void> saveWorkstation(Workstation workstation) async {
    await _db.transaction(() async {
      // 1. Guardar en Drift localmente
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

      // 2. Encolar en SyncQueue
      await _db.insertSyncQueueEntry(SyncQueueEntriesCompanion(
        id: Value(_uuid.v4()),
        targetTable: const Value('workstations'),
        recordId: Value(workstation.id),
        operation: const Value('UPSERT'),
        payload: Value(jsonEncode({
          'id': workstation.id,
          'name': workstation.name,
          'companyId': workstation.companyId,
          'deviceId': workstation.deviceId,
          'latitude': workstation.latitude,
          'longitude': workstation.longitude,
          'geofenceRadius': workstation.geofenceRadius,
          'assignedEmployeeId': workstation.assignedEmployeeId,
        })),
      ));
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
      // 1. Encolar en SyncQueue primero
      await _db.insertSyncQueueEntry(SyncQueueEntriesCompanion(
        id: Value(_uuid.v4()),
        targetTable: const Value('workstations'),
        recordId: Value(id),
        operation: const Value('DELETE'),
        payload: const Value('{}'),
      ));

      // 2. Eliminar de Drift localmente
      await (_db.delete(_db.workstationRecords)..where((t) => t.id.equals(id))).go();
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

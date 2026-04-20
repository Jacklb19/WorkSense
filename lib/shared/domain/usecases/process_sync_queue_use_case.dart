import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../data/datasources/remote/supabase_datasource.dart';
import '../../../data/datasources/local/database.dart';
import '../../../data/repositories/sync_repository_impl.dart';
import 'package:drift/drift.dart' as drift;

class ProcessSyncQueueUseCase {
  final SyncRepositoryImpl _syncRepo;
  final SupabaseDataSource _remote;
  final AppDatabase _db;

  ProcessSyncQueueUseCase(this._syncRepo, this._remote, this._db);

  Future<SyncResult> call() async {
    final pending = await _syncRepo.getPending();
    int success = 0;
    final List<String> errors = [];

    if (pending.isNotEmpty) {
      debugPrint('[Sync PUSH] Iniciando procesamiento de ${pending.length} ítems pendientes...');
    }

    for (final entry in pending) {
      try {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

        switch (entry.operation) {
          case 'UPSERT':
          case 'INSERT':
            await _remote.upsert(entry.targetTable , payload);
            break;
          case 'PATCH':
          case 'UPDATE':
            await _remote.patch(entry.targetTable , entry.recordId, payload);
            break;
          case 'DELETE':
            await _remote.delete(entry.targetTable , entry.recordId);
            break;
        }

        await _syncRepo.delete(entry.id); // limpia la cola al sincronizar
        success++;
      } on SyncException catch (e) {
        // Si es un error de sintaxis (22P02), FK (23503), o columna inexistente (PGRST204), desechar
        if (e.message.contains('22P02') || e.message.contains('violates foreign key constraint') || e.message.contains('PGRST204')) {
          debugPrint('[Sync] Desechando mensaje corrupto/incompatible: ${e.message}');
          await _syncRepo.delete(entry.id);
        }
        errors.add('Entry ${entry.id} (${entry.targetTable }): ${e.message}');
        debugPrint('[Sync Error] $e');
      } catch (e) {
        errors.add('Unexpected error on entry ${entry.id}: $e');
        debugPrint('[Sync Unexpected Error] $e');
      }
    }

    if (pending.isNotEmpty) {
      debugPrint('[Sync PUSH] Finalizado. Éxito: $success, Errores: ${errors.length}');
    }

    // PULL PHASE: Bajar datos desde Supabase para actualizar la BD Local (Emulator lo necesita)
    try {
      // Intentamos usar el metadata primero, o la base de datos
      String? companyId = _remote.currentCompanyId;
      if (companyId == null || companyId == 'default') {
         final currentUser = await _remote.fetchCurrentEmployee();
         companyId = currentUser?['company_id'] as String?;
      }
      
      debugPrint('[Sync PULL] Descargando de Supabase para empresa: $companyId');
      
      // Descargar Workstations
      final remoteWorkstations = await _remote.fetchAllWorkstations(companyId);
      for (var w in remoteWorkstations) {
        await _db.into(_db.workstationRecords).insertOnConflictUpdate(
          WorkstationRecord(
            id: w['id'],
            name: w['name'],
            companyId: w['company_id'],
            deviceId: w['device_id'],
            latitude: w['latitude'],
            longitude: w['longitude'],
            geofenceRadius: (w['geofence_radius'] as num?)?.toDouble() ?? 50.0,
            assignedEmployeeId: w['assigned_employee_id'],
            faceEmbedding: w['face_embedding']?.toString(), // AQUÍ ESTÁ EL EMBEDDING DEL KIOSCO
            bodySignature: w['body_signature']?.toString(),
            profileCapturedAt: w['profile_captured_at'] != null ? DateTime.parse(w['profile_captured_at']) : null,
            profileVersion: w['profile_version'] ?? 0,
            status: w['status'] ?? 'IDLE',
          )
        );
      }

      // Descargar Empleados
      final remoteEmployees = await _remote.fetchAllEmployees(companyId);
      for (var e in remoteEmployees) {
        await _db.into(_db.employeeRecords).insertOnConflictUpdate(
          EmployeeRecord(
            id: e['id'],
            name: e['name'] ?? 'Desconocido',
            companyId: e['company_id'],
            createdAt: e['created_at'] != null ? DateTime.parse(e['created_at']) : DateTime.now(),
            // La BD central no guarda face_embedding en employees, sino en workstations.
            faceEmbedding: null, 
          )
        );
      }
      debugPrint('[Sync PULL] Sincronización entrante completada con éxito.');
    } catch (e) {
      debugPrint('[Sync PULL Error] Error bajando datos de Supabase: $e');
      errors.add('Pull Error: $e');
    }

    return SyncResult(synced: success, errors: errors, total: pending.length);
  }
}

class SyncResult {
  final int synced;
  final int total;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;

  SyncResult({required this.synced, required this.errors, required this.total});
}

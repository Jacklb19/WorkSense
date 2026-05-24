import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/sync_repository_impl.dart';
import 'package:worksense_app/domain/entities/app_role.dart';
import 'package:worksense_app/shared/domain/usecases/worktime_reconciler.dart';

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
      debugPrint('[Sync ENGINE] Iniciando procesamiento de ${pending.length} items pendientes...');
    }

    final batchEvents = pending
        .where(
          (e) =>
              e.targetTable == 'activity_events' &&
              (e.operation == 'UPSERT' || e.operation == 'INSERT'),
        )
        .toList();

    bool batchSuccess = false;
    if (batchEvents.isNotEmpty) {
      try {
        final payloads = batchEvents
            .map((e) => jsonDecode(e.payload) as Map<String, dynamic>)
            .toList();
        await _remote.upsertBatch('activity_events', payloads);
        for (final entry in batchEvents) {
          await _db.markActivityEntryAsSynced(entry.recordId);
          await _syncRepo.delete(entry.id);
          success++;
        }
        batchSuccess = true;
        debugPrint('[Sync ENGINE] Éxito al procesar batch de ${batchEvents.length} activity_events');
      } catch (e) {
        debugPrint('[Sync ENGINE] Error en batch de activity_events: $e');
      }
    }

    for (final entry in pending) {
      if (batchSuccess && batchEvents.contains(entry)) continue;

      try {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
        debugPrint('[Sync PUSH] Procesando entrada ID: ${entry.id}, tabla: ${entry.targetTable}, operación: ${entry.operation}, payload: $payload');
        
        switch (entry.operation) {
          case 'UPSERT':
          case 'INSERT':
            await _remote.upsert(entry.targetTable, payload);
            if (entry.targetTable == 'activity_events') {
              await _db.markActivityEntryAsSynced(entry.recordId);
            }
            break;
          case 'PATCH':
          case 'UPDATE':
            await _remote.patch(entry.targetTable, entry.recordId, payload);
            break;
          case 'DELETE':
            await _remote.delete(entry.targetTable, entry.recordId);
            break;
        }

        await _syncRepo.delete(entry.id);
        success++;
        debugPrint('[Sync PUSH] Éxito al procesar ${entry.targetTable} ID ${entry.recordId}');
      } on SyncException catch (e) {
        debugPrint('[Sync PUSH] ERROR (SyncException) en entrada ${entry.id} (${entry.targetTable}): ${e.message}');
        if (e.message.contains('22P02') ||
            e.message.contains('violates foreign key constraint') ||
            e.message.contains('PGRST204') ||
            e.message.contains('PGRST205') ||
            e.message.contains('42501')) {
          await _syncRepo.delete(entry.id);
          debugPrint('[Sync PUSH] Entrada omitida y removida de la cola por error de restricciones de BD.');
        }
        errors.add('Entry ${entry.id} (${entry.targetTable}): ${e.message}');
      } catch (e) {
        debugPrint('[Sync PUSH] ERROR INESPERADO en entrada ${entry.id} (${entry.targetTable}): $e');
        errors.add('Unexpected error on entry ${entry.id}: $e');
      }
    }

    await _pushComputedSummaries(errors);
    await _applyLocalRawEventsTtl();

    try {
      await _performPull(errors);
    } catch (e) {
      debugPrint('[Sync PULL] ERROR al ejecutar Pull: $e');
      errors.add('Pull Error: $e');
    }

    final result = SyncResult(synced: success, errors: errors, total: pending.length);
    if (errors.isNotEmpty) {
      debugPrint('[Sync ENGINE] Completado con ${errors.length} errores. Detalles: $errors');
    } else if (pending.isNotEmpty || success > 0) {
      debugPrint('[Sync ENGINE] Completado exitosamente. $success de ${pending.length} procesados.');
    }
    return result;
  }

  Future<void> _pushComputedSummaries(List<String> errors) async {
    final reconciler = WorktimeReconciler(_db);
    await reconciler.buildDailySummaryPayloads();
    await reconciler.buildActivityRollupPayloads();

    final summaries = await _db.getPendingDailySummaryPayloads();
    final rollups = await _db.getPendingActivityRollupPayloads();

    for (final summaryRow in summaries) {
      final summary = jsonDecode(summaryRow['payload_json'] as String)
          as Map<String, dynamic>;
      try {
        await _remote.upsert('daily_work_summaries', summary);
        await _db.markDailySummaryPayloadSynced(summaryRow['id'] as String);
      } catch (e) {
        final msg = e.toString();
        // FK violation o tabla inexistente: marcar como synced para no reintentar
        if (msg.contains('23503') || msg.contains('PGRST205') || msg.contains('42501')) {
          await _db.markDailySummaryPayloadSynced(summaryRow['id'] as String);
        }
        errors.add('Daily summary ${summary['id']}: $e');
      }
    }

    for (final rollupRow in rollups) {
      final rollup = jsonDecode(rollupRow['payload_json'] as String)
          as Map<String, dynamic>;
      try {
        await _remote.upsert('activity_rollups', rollup);
        await _db.markActivityRollupPayloadSynced(rollupRow['id'] as String);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('23503') || msg.contains('PGRST205') || msg.contains('42501')) {
          await _db.markActivityRollupPayloadSynced(rollupRow['id'] as String);
        }
        errors.add('Activity rollup ${rollup['id']}: $e');
      }
    }
  }

  Future<void> _applyLocalRawEventsTtl() async {
    final threshold = DateTime.now().subtract(
      const Duration(days: AiThresholds.rawEventsRetentionDays),
    );
    final oldSynced = await _db.getSyncedActivityEntriesBefore(threshold);
    if (oldSynced.isEmpty) return;
    await _db.deleteActivityEntriesByIds(oldSynced.map((entry) => entry.id));
  }

  Future<void> _performPull(List<String> errors) async {
    String? companyId = _remote.currentCompanyId;
    debugPrint('[Sync PULL] Compañía resuelta desde remote (currentCompanyId): "$companyId"');
    if (companyId == null || companyId == 'default') {
      final currentUser = await _remote.fetchCurrentEmployee();
      companyId = currentUser?['company_id'] as String?;
      debugPrint('[Sync PULL] Compañía resuelta desde empleado actual: "$companyId"');
    }
    // Fallback: consultar public.employees directamente (misma lógica que currentUserProvider)
    if (companyId == null || companyId == 'default') {
      try {
        final userId = _remote.currentUserId;
        if (userId != null) {
          final row = await Supabase.instance.client
              .from('employees')
              .select('company_id')
              .eq('id', userId)
              .maybeSingle();
          companyId = row?['company_id']?.toString();
          debugPrint('[Sync PULL] Compañía resuelta desde employees remoto: "$companyId"');
        }
      } catch (e) {
        debugPrint('[Sync PULL] Error consultando employees remoto: $e');
      }
    }
    final canApplyDestructivePull =
        companyId != null && companyId.isNotEmpty && companyId != 'default';
    debugPrint('[Sync PULL] canApplyDestructivePull: $canApplyDestructivePull');

    final pendingSyncEntries = await _db.getPendingSyncQueueEntries();

    final remoteWorkstations = await _remote.fetchAllWorkstations(companyId);
    final remoteWorkstationIds =
        remoteWorkstations.map((w) => w['id'] as String).toSet();
    debugPrint('[Sync PULL] Workstations remotas recuperadas: ${remoteWorkstationIds.toList()}');

    final localWorkstations = await _db.getAllWorkstationRecords();
    if (canApplyDestructivePull) {
      final pendingWorkstationIds = pendingSyncEntries
          .where((e) => e.targetTable == 'workstations')
          .map((e) => e.recordId)
          .toSet();
      for (final localW in localWorkstations) {
        if (!remoteWorkstationIds.contains(localW.id) &&
            !pendingWorkstationIds.contains(localW.id)) {
          await (_db.delete(_db.workstationRecords)
                ..where((t) => t.id.equals(localW.id)))
              .go();
        }
      }
    } else {
      errors.add('Pull ejecutado en modo seguro: companyId inválido para borrado destructivo.');
    }

    for (final w in remoteWorkstations) {
      await _db.into(_db.workstationRecords).insertOnConflictUpdate(
            WorkstationRecord(
              id: w['id'],
              name: w['name'],
              companyId: w['company_id'],
              deviceId: w['device_id'],
              latitude: (w['latitude'] as num?)?.toDouble(),
              longitude: (w['longitude'] as num?)?.toDouble(),
              geofenceRadius: (w['geofence_radius'] as num?)?.toDouble() ?? 50.0,
              assignedEmployeeId: w['assigned_employee_id'],
              faceEmbeddings: w['face_embedding']?.toString(),
              bodySignature: w['body_signature']?.toString(),
            profileCapturedAt: w['profile_captured_at'] != null
                  ? DateTime.parse(w['profile_captured_at'])
                  : null,
              profileVersion: w['profile_version'] ?? 0,
              status: w['status'] ?? 'IDLE',
            ),
          );
      if (w['roi'] != null) {
        await _db.saveWorkstationRoi(w['id'], jsonEncode(w['roi']));
      }
    }

    final remoteEmployees = await _remote.fetchAllEmployees(companyId);
    final remoteEmployeeIds = remoteEmployees.map((e) => e['id'] as String).toSet();

    if (canApplyDestructivePull) {
      final pendingEmployeeIds = pendingSyncEntries
          .where((e) => e.targetTable == 'employees')
          .map((e) => e.recordId)
          .toSet();
      final localEmployees = await _db.select(_db.employeeRecords).get();
      for (final localE in localEmployees) {
        if (!remoteEmployeeIds.contains(localE.id) &&
            !pendingEmployeeIds.contains(localE.id)) {
          await _db.deleteEmployeeRecord(localE.id);
        }
      }
    }

    for (final e in remoteEmployees) {
      final localEmp = await _db.getEmployeeRecordById(e['id']);
      await _db.into(_db.employeeRecords).insertOnConflictUpdate(
            EmployeeRecord(
              id: e['id'],
              name: e['name'] ?? 'Desconocido',
              lastName: e['last_name'] ?? '',
              email: e['email'] ?? '',
              role: AppRoleX.fromRaw(e['role']).metadataValue,
              companyId: e['company_id'],
              createdAt: e['created_at'] != null
                  ? DateTime.parse(e['created_at'])
                  : DateTime.now(),
              faceEmbeddings: localEmp?.faceEmbeddings,
              shiftId: e['shift_id'] ?? localEmp?.shiftId,
            ),
          );
    }

    final remoteShifts = await _remote.fetchAllShifts(companyId);
    for (final s in remoteShifts) {
      final startParts = s['start_time'].split(':');
      final endParts = s['end_time'].split(':');
      final breakStartParts = s['break_time_start']?.split(':');
      final breakEndParts = s['break_time_end']?.split(':');

      await _db.into(_db.shiftRecords).insertOnConflictUpdate(
            ShiftRecordData(
              id: s['id'],
              companyId: s['company_id'],
              name: s['name'] ?? 'Turno',
              startHour: int.parse(startParts[0]),
              startMinute: int.parse(startParts[1]),
              endHour: int.parse(endParts[0]),
              endMinute: int.parse(endParts[1]),
              breakStartHour:
                  breakStartParts != null ? int.parse(breakStartParts[0]) : null,
              breakStartMinute:
                  breakStartParts != null ? int.parse(breakStartParts[1]) : null,
              breakEndHour:
                  breakEndParts != null ? int.parse(breakEndParts[0]) : null,
              breakEndMinute:
                  breakEndParts != null ? int.parse(breakEndParts[1]) : null,
              createdAt: s['created_at'] != null
                  ? DateTime.parse(s['created_at'])
                  : DateTime.now(),
            ),
          );
    }
  }
}

class SyncResult {
  final int synced;
  final int total;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;

  SyncResult({required this.synced, required this.errors, required this.total});
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class SerializationException implements Exception {
  final String message;
  SerializationException(this.message);

  @override
  String toString() => message;
}

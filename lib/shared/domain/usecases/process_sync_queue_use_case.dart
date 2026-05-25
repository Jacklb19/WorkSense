import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
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

    // Resolve companyId early for filtering
    final companyId = await _resolveCompanyId();
    debugPrint('[Sync ENGINE] companyId resolved: $companyId');

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

    // Get companyId for filtering computed summaries
    await _pushComputedSummaries(errors, companyId);
    await _applyLocalRawEventsTtl();

    try {
      await _performPull(errors, companyId);
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

  Future<void> _pushComputedSummaries(List<String> errors, String companyId) async {
    final reconciler = WorktimeReconciler(_db);
    await reconciler.buildDailySummaryPayloads();
    await reconciler.buildActivityRollupPayloads();

    final summaries = await _db.getPendingDailySummaryPayloads();
    final rollups = await _db.getPendingActivityRollupPayloads();

    for (final summaryRow in summaries) {
      final summary = jsonDecode(summaryRow['payload_json'] as String)
          as Map<String, dynamic>;
      
      // Skip if company_id doesn't match current user
      if (summary['company_id'] != companyId) {
        debugPrint('[Sync PUSH] Skipping daily summary with wrong company_id: ${summary['company_id']}');
        await _db.markDailySummaryPayloadSynced(summaryRow['id'] as String);
        continue;
      }
      
      try {
        await _remote.upsert('daily_work_summaries', summary);
        await _db.markDailySummaryPayloadSynced(summaryRow['id'] as String);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('23503') || msg.contains('PGRST205') || msg.contains('42501')) {
          await _db.markDailySummaryPayloadSynced(summaryRow['id'] as String);
        }
        errors.add('Daily summary ${summary['id']}: $e');
      }
    }

    for (final rollupRow in rollups) {
      final rollup = jsonDecode(rollupRow['payload_json'] as String)
          as Map<String, dynamic>;
      
      // Skip if company_id doesn't match current user
      if (rollup['company_id'] != companyId) {
        debugPrint('[Sync PUSH] Skipping activity rollup with wrong company_id: ${rollup['company_id']}');
        await _db.markActivityRollupPayloadSynced(rollupRow['id'] as String);
        continue;
      }
      
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

Future<String> _resolveCompanyId() async {
    // Priority 1: fetchCurrentEmployee (includes fallback logic)
    final currentUser = await _remote.fetchCurrentEmployee();
    if (currentUser != null && currentUser['company_id'] != null) {
      return currentUser['company_id'] as String;
    }

    // Priority 2: fetch from employees table directly
    final userId = _remote.currentUserId;
    if (userId != null) {
      try {
        final row = await Supabase.instance.client
            .from('employees')
            .select('company_id')
            .eq('id', userId)
            .maybeSingle();
        final companyId = row?['company_id']?.toString();
        if (companyId != null && companyId != AppConstants.defaultCompanyId) {
          return companyId;
        }
      } catch (_) {}
    }

    // Priority 3: infer from local workstations
    final allWorkstations = await _db.getAllWorkstationRecords();
    final wsCompany = allWorkstations
        .map((w) => w.companyId)
        .where((c) => c.isNotEmpty && c != AppConstants.defaultCompanyId)
        .firstOrNull;
    if (wsCompany != null) return wsCompany;

    // Priority 4: infer from local employees
    final allEmployees = await _db.getAllEmployeeRecords();
    final empCompany = allEmployees
        .map((e) => e.companyId)
        .where((c) => c.isNotEmpty && c != AppConstants.defaultCompanyId)
        .firstOrNull;
    if (empCompany != null) return empCompany;

    return AppConstants.defaultCompanyId;
  }

Future<void> _performPull(List<String> errors, String companyId) async {
    debugPrint('[Sync PULL] Using companyId: "$companyId"');

    if (companyId == AppConstants.defaultCompanyId || companyId.isEmpty) {
      errors.add('CRITICAL: No se pudo determinar companyId para el usuario. Verifique que el usuario tenga company_id en metadatos JWT o registro en public.employees.');
      debugPrint('[Sync PULL] ERROR: companyId no puede ser determinado. Abortando sync pull.');
      return;
    }

    debugPrint('[Sync PULL] companyId validado, procediendo con Pull...');

    final pendingSyncEntries = await _db.getPendingSyncQueueEntries();

    final remoteWorkstations = await _remote.fetchAllWorkstations(companyId);
    final remoteWorkstationIds =
        remoteWorkstations.map((w) => w['id'] as String).toSet();
    debugPrint('[Sync PULL] Workstations remotas recuperadas: ${remoteWorkstationIds.toList()}');

    final localWorkstations = await _db.getAllWorkstationRecords();
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

    // ── Phase 1+2: Pull tasks, leaves, alerts, announcements, attendance ─────
    await _pullTasks(errors, companyId);
    await _pullLeaveRequests(errors, companyId);
    await _pullAlertLogs(errors, companyId);
    await _pullAnnouncements(errors, companyId);
    await _pullAttendanceLogs(errors, companyId);

    // ── Phase 5: Pull shifts ──────────────────────────────────────────────────
    await _pullShifts(errors, companyId);
  }

  Future<void> _pullTasks(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany('tasks', companyId);
      debugPrint('[Sync PULL] tasks remotas: ${rows.length}');
      for (final r in rows) {
        await _db.into(_db.taskRecords).insertOnConflictUpdate(
              TaskData(
                id: r['id'] as String,
                companyId: r['company_id'] as String,
                assignedToId: r['assigned_to_id'] as String,
                createdById: (r['created_by_id'] as String?) ?? '',
                title: (r['title'] as String?) ?? '',
                description: r['description'] as String?,
                status: (r['status'] as String?) ?? 'PENDING',
                priority: (r['priority'] as String?) ?? 'NORMAL',
                dueDate: r['due_date'] != null
                    ? DateTime.parse(r['due_date'] as String)
                    : null,
                createdAt: r['created_at'] != null
                    ? DateTime.parse(r['created_at'] as String)
                    : DateTime.now(),
                updatedAt: r['updated_at'] != null
                    ? DateTime.parse(r['updated_at'] as String)
                    : DateTime.now(),
                synced: true,
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling tasks: $e');
      errors.add('Pull tasks: $e');
    }
  }

  Future<void> _pullLeaveRequests(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany('leave_requests', companyId);
      debugPrint('[Sync PULL] leave_requests remotas: ${rows.length}');
      for (final r in rows) {
        await _db.into(_db.leaveRequestRecords).insertOnConflictUpdate(
              LeaveRequestData(
                id: r['id'] as String,
                employeeId: r['employee_id'] as String,
                companyId: r['company_id'] as String,
                type: (r['type'] as String?) ?? 'PERSONAL',
                status: (r['status'] as String?) ?? 'PENDING',
                startDate: DateTime.parse(r['start_date'] as String),
                endDate: DateTime.parse(r['end_date'] as String),
                reason: r['reason'] as String?,
                reviewedById: r['reviewed_by_id'] as String?,
                reviewNote: r['review_note'] as String?,
                createdAt: r['created_at'] != null
                    ? DateTime.parse(r['created_at'] as String)
                    : DateTime.now(),
                updatedAt: r['updated_at'] != null
                    ? DateTime.parse(r['updated_at'] as String)
                    : DateTime.now(),
                synced: true,
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling leave_requests: $e');
      errors.add('Pull leave_requests: $e');
    }
  }

  Future<void> _pullAlertLogs(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany(
        'alert_logs',
        companyId,
        orderBy: 'triggered_at',
        ascending: false,
        limit: 200,
      );
      debugPrint('[Sync PULL] alert_logs remotas: ${rows.length}');
      for (final r in rows) {
        await _db.into(_db.alertLogRecords).insertOnConflictUpdate(
              AlertLogData(
                id: r['id'] as String,
                companyId: r['company_id'] as String,
                employeeId: r['employee_id'] as String?,
                workstationId: r['workstation_id'] as String?,
                alertType: (r['alert_type'] as String?) ?? 'ABSENCE',
                durationSeconds: (r['duration_seconds'] as int?) ?? 0,
                triggeredAt: r['triggered_at'] != null
                    ? DateTime.parse(r['triggered_at'] as String)
                    : DateTime.now(),
                acknowledged: (r['acknowledged'] as bool?) ?? false,
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling alert_logs: $e');
      errors.add('Pull alert_logs: $e');
    }
  }

  Future<void> _pullAnnouncements(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany('announcements', companyId);
      debugPrint('[Sync PULL] announcements remotas: ${rows.length}');
      for (final r in rows) {
        await _db.into(_db.announcementRecords).insertOnConflictUpdate(
              AnnouncementData(
                id: r['id'] as String,
                companyId: r['company_id'] as String,
                authorId: (r['author_id'] as String?) ?? '',
                title: (r['title'] as String?) ?? '',
                content: (r['content'] as String?) ?? '',
                priority: (r['priority'] as String?) ?? 'NORMAL',
                createdAt: r['created_at'] != null
                    ? DateTime.parse(r['created_at'] as String)
                    : DateTime.now(),
                expiresAt: r['expires_at'] != null
                    ? DateTime.parse(r['expires_at'] as String)
                    : null,
                synced: true,
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling announcements: $e');
      errors.add('Pull announcements: $e');
    }
  }

  /// Parses an HH:MM:SS time string to its hour component.
  int _timeHour(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    return int.tryParse(raw.split(':')[0]) ?? 0;
  }

  /// Parses an HH:MM:SS time string to its minute component.
  int _timeMinute(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final parts = raw.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  Future<void> _pullShifts(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany('shifts', companyId);
      debugPrint('[Sync PULL] shifts remotos: ${rows.length}');
      for (final r in rows) {
        // Remote stores times as 'HH:MM:SS' strings — parse to hour/minute ints
        final startRaw = r['start_time'] as String?;
        final endRaw = r['end_time'] as String?;
        final breakStartRaw = r['break_time_start'] as String?;
        final breakEndRaw = r['break_time_end'] as String?;

        await _db.into(_db.shiftRecords).insertOnConflictUpdate(
              ShiftRecordData(
                id: r['id'] as String,
                companyId: r['company_id'] as String,
                name: (r['name'] as String?) ?? '',
                startHour: _timeHour(startRaw),
                startMinute: _timeMinute(startRaw),
                endHour: _timeHour(endRaw),
                endMinute: _timeMinute(endRaw),
                breakStartHour: breakStartRaw != null ? _timeHour(breakStartRaw) : null,
                breakStartMinute: breakStartRaw != null ? _timeMinute(breakStartRaw) : null,
                breakEndHour: breakEndRaw != null ? _timeHour(breakEndRaw) : null,
                breakEndMinute: breakEndRaw != null ? _timeMinute(breakEndRaw) : null,
                createdAt: r['created_at'] != null
                    ? DateTime.parse(r['created_at'] as String)
                    : DateTime.now(),
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling shifts: $e');
      errors.add('Pull shifts: $e');
    }
  }

  Future<void> _pullAttendanceLogs(List<String> errors, String companyId) async {
    try {
      final rows = await _remote.fetchByCompany(
        'attendance_logs',
        companyId,
        orderBy: 'clock_in_time',
        ascending: false,
        limit: 300,
      );
      debugPrint('[Sync PULL] attendance_logs remotas: ${rows.length}');
      for (final r in rows) {
        await _db.into(_db.attendanceLogs).insertOnConflictUpdate(
              AttendanceLogData(
                id: r['id'] as String,
                employeeId: r['employee_id'] as String,
                workstationId: r['workstation_id'] as String?,
                companyId: r['company_id'] as String,
                shiftDate: r['shift_date'] != null
                    ? DateTime.parse(r['shift_date'] as String)
                    : DateTime.now(),
                clockInTime: r['clock_in_time'] != null
                    ? DateTime.parse(r['clock_in_time'] as String)
                    : DateTime.now(),
                clockOutTime: r['clock_out_time'] != null
                    ? DateTime.parse(r['clock_out_time'] as String)
                    : null,
                status: (r['status'] as String?) ?? 'ON_TIME',
                synced: true,
              ),
            );
      }
    } catch (e) {
      debugPrint('[Sync PULL] Error pulling attendance_logs: $e');
      errors.add('Pull attendance_logs: $e');
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

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/datasources/local/database.dart' as local_db;
import 'package:worksense_app/domain/entities/attendance_log.dart';
import 'package:worksense_app/domain/repositories/attendance_repository.dart';
import 'sync_repository_impl.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final local_db.AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;
  final _uuid = const Uuid();

  AttendanceRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<void> clockIn({
    required String employeeId,
    required String companyId,
    String? workstationId,
  }) async {
    final now = DateTime.now();
    // Normalizamos la fecha a 00:00:00
    final today = DateTime(now.year, now.month, now.day);
    final logId = _uuid.v4();

    final companion = local_db.AttendanceLogsCompanion(
      id: Value(logId),
      employeeId: Value(employeeId),
      companyId: Value(companyId),
      workstationId: Value(workstationId),
      shiftDate: Value(today),
      clockInTime: Value(now),
      status: const Value('ON_TIME'), // En un futuro, se calculará al cruzar con Shift
      synced: const Value(false),
    );

    await _db.transaction(() async {
      await _db.insertAttendanceLog(companion);

      // Usar Supabase local Queue via SyncRepository
      final payload = {
        'id': logId,
        'employee_id': employeeId,
        'company_id': companyId,
        'workstation_id': workstationId,
        'shift_date': today.toIso8601String(),
        'clock_in_time': now.toIso8601String(),
        'status': 'ON_TIME',
      };

      await _syncRepo.enqueue(
        targetTable: 'attendance_logs',
        operation: 'INSERT',
        recordId: logId,
        payload: payload,
      );
    });
  }

  @override
  Future<void> clockOut({
    required String employeeId,
    String? workstationId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final openLog = await _db.getOpenAttendanceLogForEmployee(employeeId, today);
    if (openLog == null) {
      throw Exception('No open session found to clock out.');
    }

    final updatedCompanion = local_db.AttendanceLogsCompanion(
      id: Value(openLog.id),
      clockOutTime: Value(now),
      synced: const Value(false),
    );

    await _db.transaction(() async {
      await _db.updateAttendanceLog(updatedCompanion);

      final payload = {
        'id': openLog.id,
        'clock_out_time': now.toIso8601String(),
      };

      await _syncRepo.enqueue(
        targetTable: 'attendance_logs',
        operation: 'UPDATE', // Upsert if supported, or Update since it was inserted
        recordId: openLog.id,
        payload: payload,
      );
    });
  }

  @override
  Future<AttendanceLog?> getOpenSession(String employeeId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final data = await _db.getOpenAttendanceLogForEmployee(employeeId, today);
    if (data == null) return null;

    return AttendanceLog(
      id: data.id,
      employeeId: data.employeeId,
      workstationId: data.workstationId,
      companyId: data.companyId,
      shiftDate: data.shiftDate,
      clockInTime: data.clockInTime,
      clockOutTime: data.clockOutTime,
      status: AttendanceStatus.fromString(data.status),
    );
  }

  @override
  Future<List<AttendanceLog>> getTodaySessions(String employeeId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final data = await _db.getEmployeeLogsForDate(employeeId, today);
    
    return data.map((d) => AttendanceLog(
      id: d.id,
      employeeId: d.employeeId,
      workstationId: d.workstationId,
      companyId: d.companyId,
      shiftDate: d.shiftDate,
      clockInTime: d.clockInTime,
      clockOutTime: d.clockOutTime,
      status: AttendanceStatus.fromString(d.status),
    )).toList();
  }

  @override
  Future<List<AttendanceLog>> getEmployeeLogs(String employeeId, DateTime start, DateTime end) async {
    final data = await _db.getEmployeeAttendanceLogs(employeeId, start, end);
    return data.map((d) => AttendanceLog(
      id: d.id,
      employeeId: d.employeeId,
      workstationId: d.workstationId,
      companyId: d.companyId,
      shiftDate: d.shiftDate,
      clockInTime: d.clockInTime,
      clockOutTime: d.clockOutTime,
      status: AttendanceStatus.fromString(d.status),
    )).toList();
  }
}

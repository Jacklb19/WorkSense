import 'package:flutter/material.dart' show TimeOfDay;
import 'package:worksense_app/data/datasources/local/database.dart' as local_db;
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';
import 'sync_repository_impl.dart';
import 'package:drift/drift.dart' show Value, InsertMode;

class ShiftRepositoryImpl implements ShiftRepository {
  final local_db.AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  ShiftRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<List<Shift>> getShifts(String companyId) async {
    final rows = await _db.getShiftsByCompany(companyId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Shift?> getShiftById(String shiftId) async {
    final row = await _db.getShiftById(shiftId);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<Shift?> getShiftForEmployee(String employeeId) async {
    final emp = await _db.getEmployeeRecordById(employeeId);
    if (emp?.shiftId == null) return null;
    return getShiftById(emp!.shiftId!);
  }

  @override
  Future<void> createShift(Shift shift) async {
    final companion = local_db.ShiftRecordsCompanion(
      id: Value(shift.id),
      companyId: Value(shift.companyId),
      name: Value(shift.name),
      startHour: Value(shift.startTime.hour),
      startMinute: Value(shift.startTime.minute),
      endHour: Value(shift.endTime.hour),
      endMinute: Value(shift.endTime.minute),
      createdAt: Value(shift.createdAt),
    );

    await _db.transaction(() async {
      await _db.insertShiftRecord(companion);

      final payload = {
        'id': shift.id,
        'company_id': shift.companyId,
        'name': shift.name,
        'start_time': '${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${shift.endTime.hour.toString().padLeft(2, '0')}:${shift.endTime.minute.toString().padLeft(2, '0')}:00',
        'created_at': shift.createdAt.toIso8601String(),
      };

      await _syncRepo.enqueue(
        targetTable: 'shifts',
        operation: 'INSERT',
        recordId: shift.id,
        payload: payload,
      );
    });
  }

  @override
  Future<void> updateShift(Shift shift) async {
    // Igual que create por insertOrReplace
    return createShift(shift);
  }

  @override
  Future<void> assignShiftToEmployee(String employeeId, String shiftId) async {
    // Update local employee
    final emp = await _db.getEmployeeRecordById(employeeId);
    if (emp == null) return;

    await _db.into(_db.employeeRecords).insert(
      emp.copyWith(shiftId: Value(shiftId)),
      mode: InsertMode.insertOrReplace,
    );

    // Sync to remote
    await _syncRepo.enqueue(
      targetTable: 'employees',
      operation: 'UPDATE',
      recordId: employeeId,
      payload: {'id': employeeId, 'shift_id': shiftId},
    );
  }

  Shift _mapToEntity(local_db.ShiftRecordData row) {
    return Shift(
      id: row.id,
      companyId: row.companyId,
      name: row.name,
      startTime: TimeOfDay(hour: row.startHour, minute: row.startMinute),
      endTime: TimeOfDay(hour: row.endHour, minute: row.endMinute),
      createdAt: row.createdAt,
    );
  }
}

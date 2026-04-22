import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final AppDatabase _db;

  ShiftRepositoryImpl(this._db);

  @override
  Future<void> saveShift(Shift shift) async {
    await _db.insertShiftRecord(ShiftRecordsCompanion(
      id: Value(shift.id),
      employeeId: Value(shift.employeeId),
      startTime: Value(shift.startTime),
      endTime: Value(shift.endTime),
      status: Value(shift.status),
      notes: Value(shift.notes),
      createdAt: Value(shift.createdAt),
    ));
  }

  @override
  Future<List<Shift>> getShifts() async {
    final rows = await _db.getAllShiftRecords();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Shift>> watchShifts() =>
      _db.watchAllShiftRecords().map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<Shift?> getShiftById(String id) async {
    final row = await _db.getShiftRecordById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> deleteShift(String id) => _db.deleteShiftRecord(id);

  @override
  Stream<List<Shift>> watchShiftsByEmployee(String employeeId) =>
      _db.watchShiftRecordsByEmployee(employeeId).map((rows) => rows.map(_mapToEntity).toList());

  Shift _mapToEntity(ShiftRecord row) {
    return Shift(
      id: row.id,
      employeeId: row.employeeId,
      startTime: row.startTime,
      endTime: row.endTime,
      status: row.status,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }
}

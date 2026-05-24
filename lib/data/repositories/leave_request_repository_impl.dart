import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/repositories/leave_request_repository.dart';
import 'sync_repository_impl.dart';

class LeaveRequestRepositoryImpl implements LeaveRequestRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  LeaveRequestRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<List<LeaveRequest>> getLeavesByEmployee(String employeeId) async {
    final rows = await _db.getLeavesByEmployee(employeeId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<LeaveRequest>> getLeavesByCompany(String companyId) async {
    final rows = await _db.getLeavesByCompany(companyId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<LeaveRequest>> watchLeavesByEmployee(String employeeId) =>
      _db.watchLeavesByEmployee(employeeId).map((rows) => rows.map(_mapToEntity).toList());

  @override
  Stream<List<LeaveRequest>> watchLeavesByCompany(String companyId) =>
      _db.watchLeavesByCompany(companyId).map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<void> saveLeaveRequest(LeaveRequest request) async {
    await _db.transaction(() async {
      await _db.insertLeaveRequest(LeaveRequestRecordsCompanion(
        id: Value(request.id),
        employeeId: Value(request.employeeId),
        companyId: Value(request.companyId),
        type: Value(request.type.raw),
        status: Value(request.status.raw),
        startDate: Value(request.startDate),
        endDate: Value(request.endDate),
        reason: Value(request.reason),
        reviewedById: Value(request.reviewedById),
        reviewNote: Value(request.reviewNote),
        createdAt: Value(request.createdAt),
        updatedAt: Value(request.updatedAt),
      ));

      await _syncRepo.enqueue(
        targetTable: 'leave_requests',
        operation: 'UPSERT',
        recordId: request.id,
        payload: request.toMap(),
      );
    });
  }

  @override
  Future<void> reviewLeaveRequest({
    required String requestId,
    required LeaveStatus status,
    required String reviewedById,
    String? reviewNote,
  }) async {
    await _db.transaction(() async {
      await _db.updateLeaveRequestReview(
        requestId: requestId,
        status: status.raw,
        reviewedById: reviewedById,
        reviewNote: reviewNote,
      );

      await _syncRepo.enqueue(
        targetTable: 'leave_requests',
        operation: 'PATCH',
        recordId: requestId,
        payload: {
          'status': status.raw,
          'reviewed_by_id': reviewedById,
          'review_note': reviewNote,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  @override
  Future<void> deleteLeaveRequest(String requestId) async {
    await _db.transaction(() async {
      await _db.deleteLeaveRequest(requestId);

      await _syncRepo.enqueue(
        targetTable: 'leave_requests',
        operation: 'DELETE',
        recordId: requestId,
        payload: {},
      );
    });
  }

  LeaveRequest _mapToEntity(LeaveRequestData row) {
    return LeaveRequest(
      id: row.id,
      employeeId: row.employeeId,
      companyId: row.companyId,
      type: LeaveType.fromRaw(row.type),
      status: LeaveStatus.fromRaw(row.status),
      startDate: row.startDate,
      endDate: row.endDate,
      reason: row.reason,
      reviewedById: row.reviewedById,
      reviewNote: row.reviewNote,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

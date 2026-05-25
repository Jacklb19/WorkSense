import 'package:worksense_app/domain/entities/leave_request.dart';

abstract interface class LeaveRequestRepository {
  // ── Lecturas ──────────────────────────────────────────────────────────────
  Future<List<LeaveRequest>> getLeavesByEmployee(String employeeId);
  Future<List<LeaveRequest>> getLeavesByCompany(String companyId);
  Stream<List<LeaveRequest>> watchLeavesByEmployee(String employeeId);
  Stream<List<LeaveRequest>> watchLeavesByCompany(String companyId);

  // ── Escrituras ────────────────────────────────────────────────────────────
  Future<void> saveLeaveRequest(LeaveRequest request);
  Future<void> reviewLeaveRequest({
    required String requestId,
    required LeaveStatus status,
    required String reviewedById,
    String? reviewNote,
  });
  Future<void> deleteLeaveRequest(String requestId);
}

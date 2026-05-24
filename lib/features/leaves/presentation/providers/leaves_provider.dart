import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/leave_request_repository_impl.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/repositories/leave_request_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/services/notification_service.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final leaveRequestRepositoryProvider = Provider<LeaveRequestRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return LeaveRequestRepositoryImpl(db, syncRepo);
});

// ── Stream providers ──────────────────────────────────────────────────────────

/// Admin: todas las solicitudes de permiso de la empresa
final companyLeavesProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final repo = ref.watch(leaveRequestRepositoryProvider);
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) return Stream.value([]);
  return repo.watchLeavesByCompany(companyId);
});

/// Employee: mis solicitudes
final myLeavesProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final repo = ref.watch(leaveRequestRepositoryProvider);
  final userId = ref.watch(currentUserProvider).valueOrNull?.user?.id;
  if (userId == null) return Stream.value([]);
  return repo.watchLeavesByEmployee(userId);
});

/// Conteo de solicitudes pendientes por revisar (admin badge)
final pendingLeavesCountProvider = Provider<int>((ref) {
  final leaves = ref.watch(companyLeavesProvider).valueOrNull ?? [];
  return leaves.where((l) => l.status == LeaveStatus.pending).length;
});

/// Conteo de mis solicitudes pendientes (employee badge)
final myPendingLeavesCountProvider = Provider<int>((ref) {
  final leaves = ref.watch(myLeavesProvider).valueOrNull ?? [];
  return leaves.where((l) => l.status == LeaveStatus.pending).length;
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class LeavesNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaveRequestRepository _repo;

  LeavesNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> submitRequest(LeaveRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.saveLeaveRequest(request));
    if (state is AsyncData) {
      // Notify admin about the new leave request
      await NotificationService.instance
          .notifyLeaveRequest(request.employeeId);
    }
  }

  Future<void> reviewRequest({
    required String requestId,
    required LeaveStatus status,
    required String reviewedById,
    String? reviewNote,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.reviewLeaveRequest(
        requestId: requestId,
        status: status,
        reviewedById: reviewedById,
        reviewNote: reviewNote,
      ),
    );
    if (state is AsyncData && startDate != null && endDate != null) {
      // Notify employee about the review result
      await NotificationService.instance.notifyLeaveReviewed(
        approved: status == LeaveStatus.approved,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  Future<void> deleteRequest(String requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteLeaveRequest(requestId));
  }
}

final leavesNotifierProvider =
    StateNotifierProvider<LeavesNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(leaveRequestRepositoryProvider);
  return LeavesNotifier(repo);
});

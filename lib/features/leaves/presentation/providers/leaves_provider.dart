import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/leave_request_repository_impl.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/repositories/leave_request_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/features/notifications/data/notification_repository.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final leaveRequestRepositoryProvider = Provider<LeaveRequestRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return LeaveRequestRepositoryImpl(db, syncRepo);
});

// ── Supabase Realtime ─────────────────────────────────────────────────────────

/// Opens a Supabase Realtime channel for `leave_requests` filtered by
/// [companyId]. When a change arrives it's immediately upserted into
/// local SQLite so [companyLeavesProvider] updates the admin panel
/// without waiting for the 60-second periodic sync cycle.
///
/// Watch this provider inside any widget that needs live leave data
/// (typically `_AdminLeavesList`). Auto-disposed when the widget unmounts.
final leavesRealtimeProvider = Provider.autoDispose<void>((ref) {
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) return;

  final db = ref.watch(appDatabaseProvider);
  final client = Supabase.instance.client;

  final channel = client
      .channel('worksense_leaves_$companyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'leave_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'company_id',
          value: companyId,
        ),
        callback: (payload) => _applyLeaveChange(payload, db),
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    debugPrint('[Realtime] leave_requests channel disposed.');
  });
});

/// Applies an incoming Supabase Realtime payload to local SQLite.
Future<void> _applyLeaveChange(
  PostgresChangePayload payload,
  AppDatabase db,
) async {
  try {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'] as String?;
      if (oldId == null) return;
      await (db.delete(db.leaveRequestRecords)
            ..where((t) => t.id.equals(oldId)))
          .go();
      debugPrint('[Realtime] Leave request $oldId deleted locally.');
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty || r['id'] == null) return;

    await db.into(db.leaveRequestRecords).insertOnConflictUpdate(
          LeaveRequestData(
            id: r['id'] as String,
            employeeId: (r['employee_id'] as String?) ?? '',
            companyId: (r['company_id'] as String?) ?? '',
            type: (r['type'] as String?) ?? 'PERSONAL',
            status: (r['status'] as String?) ?? 'PENDING',
            startDate: r['start_date'] != null
                ? DateTime.parse(r['start_date'] as String)
                : DateTime.now(),
            endDate: r['end_date'] != null
                ? DateTime.parse(r['end_date'] as String)
                : DateTime.now(),
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
    debugPrint('[Realtime] Leave request ${r['id']} upserted locally.');
  } catch (e) {
    debugPrint('[Realtime] Error applying leave change: $e');
  }
}

// ── Stream providers ──────────────────────────────────────────────────────────

/// Admin: todas las solicitudes de permiso de la empresa.
/// Backed by local SQLite (offline-first); real-time updates arrive via
/// [leavesRealtimeProvider] when the admin UI is active.
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

// ── Targeted remote refresh ───────────────────────────────────────────────────

/// Pulls the latest `leave_requests` from Supabase for the current company and
/// upserts them into local SQLite. The Drift stream [companyLeavesProvider]
/// updates automatically because it watches the same table.
///
/// Call this when the admin opens the Leaves screen for a fast, focused refresh
/// instead of waiting for the full [syncNotifierProvider] cycle.
class LeavesRefreshNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> refresh() async {
    final companyId = ref.read(currentUserProvider).valueOrNull?.companyId;
    if (companyId == null || companyId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final remote = ref.read(supabaseDataSourceProvider);
      final db = ref.read(appDatabaseProvider);

      final rows = await remote.fetchByCompany('leave_requests', companyId);
      debugPrint('[Leaves] Remote pull: ${rows.length} rows for company $companyId');

      for (final r in rows) {
        await db.into(db.leaveRequestRecords).insertOnConflictUpdate(
          LeaveRequestData(
            id: r['id'] as String,
            employeeId: (r['employee_id'] as String?) ?? '',
            companyId: (r['company_id'] as String?) ?? '',
            type: (r['type'] as String?) ?? 'PERSONAL',
            status: (r['status'] as String?) ?? 'PENDING',
            startDate: r['start_date'] != null
                ? DateTime.parse(r['start_date'] as String)
                : DateTime.now(),
            endDate: r['end_date'] != null
                ? DateTime.parse(r['end_date'] as String)
                : DateTime.now(),
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

      state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('[Leaves] Remote pull failed (non-fatal): $e');
      state = const AsyncValue.data(null); // non-fatal — show whatever is in local SQLite
    }
  }
}

final leavesRefreshNotifierProvider =
    AsyncNotifierProvider<LeavesRefreshNotifier, void>(LeavesRefreshNotifier.new);

// ── Notifier ─────────────────────────────────────────────────────────────────

class LeavesNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaveRequestRepository _repo;
  final SupabaseDataSource _remote;

  LeavesNotifier(this._repo, this._remote) : super(const AsyncValue.data(null));

  Future<void> submitRequest(LeaveRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.saveLeaveRequest(request));
    if (state is AsyncData) {
      // ── Direct Supabase push ───────────────────────────────────────────────
      // Bypass sync queue for immediate admin visibility. The sync queue entry
      // added by saveLeaveRequest() remains as a retry fallback if this fails.
      try {
        await _remote.upsert('leave_requests', request.toMap());
        debugPrint('[LeavesNotifier] Leave ${request.id} pushed directly to Supabase.');
      } catch (e) {
        // Non-fatal — sync queue will push in the next cycle (≤60 s).
        debugPrint('[LeavesNotifier] Direct Supabase push failed '
            '(sync queue will retry): $e');
      }

      // Notification failure must never roll back the local save.
      try {
        await NotificationRepository.instance.pushToAdmins(
          companyId: request.companyId,
          type: 'leave_request',
          title: '📅 Nueva solicitud de permiso',
          body: '${request.type.label} · '
              '${request.startDate.day}/${request.startDate.month} – '
              '${request.endDate.day}/${request.endDate.month}',
          senderId: request.employeeId,
          route: '/leaves',
        );
      } catch (e) {
        debugPrint('[LeavesNotifier] Notification push failed (non-fatal): $e');
      }
    }
  }

  Future<void> reviewRequest({
    required String requestId,
    required LeaveStatus status,
    required String reviewedById,
    required String employeeId,
    required String companyId,
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
    if (state is AsyncData) {
      // ── Direct Supabase patch for immediate employee visibility ───────────
      try {
        await _remote.patch('leave_requests', requestId, {
          'status': status.raw,
          'reviewed_by_id': reviewedById,
          'review_note': reviewNote,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[LeavesNotifier] Leave $requestId reviewed and patched directly.');
      } catch (e) {
        debugPrint('[LeavesNotifier] Direct patch failed (sync queue will retry): $e');
      }

      // Notification failure must never roll back the local review.
      try {
        final approved = status == LeaveStatus.approved;
        final dateStr = startDate != null && endDate != null
            ? '${startDate.day}/${startDate.month} – '
              '${endDate.day}/${endDate.month}'
            : '';
        await NotificationRepository.instance.pushToUser(
          recipientId: employeeId,
          companyId: companyId,
          type: approved ? 'leave_approved' : 'leave_rejected',
          title: approved ? '✅ Permiso aprobado' : '❌ Permiso rechazado',
          body: dateStr.isNotEmpty
              ? 'Tu solicitud ($dateStr) fue revisada'
              : 'Tu solicitud fue revisada',
          senderId: reviewedById,
          route: '/leaves',
        );
      } catch (e) {
        debugPrint('[LeavesNotifier] Notification push failed (non-fatal): $e');
      }
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
  final remote = ref.watch(supabaseDataSourceProvider);
  return LeavesNotifier(repo, remote);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class LeavesListScreen extends ConsumerStatefulWidget {
  const LeavesListScreen({super.key});

  @override
  ConsumerState<LeavesListScreen> createState() => _LeavesListScreenState();
}

class _LeavesListScreenState extends ConsumerState<LeavesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaveStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Run a full sync first (flushes employee sync queues → puts data in
      // Supabase), then pull leave_requests so the admin sees the latest.
      ref.read(syncNotifierProvider.notifier).sync().then((_) {
        if (mounted) {
          ref.read(leavesRefreshNotifierProvider.notifier).refresh();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = userState?.role == AppRole.admin ||
        userState?.role == AppRole.superAdmin;

    final l10n = context.l10n;
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          l10n.leaves.toUpperCase(),
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: isAdmin
            ? [
                // Manual sync button — lets admin pull the latest requests immediately
                const _SyncButton(),
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: ac.textDisabled,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.leavePendingPlural),
            Tab(text: l10n.leaveApprovedPlural),
            Tab(text: l10n.leaveRejectedPlural),
          ],
          onTap: (i) {
            setState(() {
              _filterStatus = switch (i) {
                1 => LeaveStatus.pending,
                2 => LeaveStatus.approved,
                3 => LeaveStatus.rejected,
                _ => null,
              };
            });
          },
        ),
      ),
      body: isAdmin
          ? _AdminLeavesList(filterStatus: _filterStatus)
          : _EmployeeLeavesList(filterStatus: _filterStatus),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.leaveNew),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: Text(l10n.leaveRequestLabel),
            )
          : null,
    );
  }
}

// ── Admin view ─────────────────────────────────────────────────────────────────

class _AdminLeavesList extends ConsumerWidget {
  final LeaveStatus? filterStatus;

  const _AdminLeavesList({this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate Supabase Realtime — updates admin panel instantly when employees
    // submit or when the admin approves/rejects on another device.
    ref.watch(leavesRealtimeProvider);

    final leavesAsync = ref.watch(companyLeavesProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return leavesAsync.when(
      // Keep previous data visible while refreshing — prevents empty-list flash
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (leaves) {
        // ── Debug: verify admin is receiving data ──────────────────────────
        debugPrint('[LeavesAdmin] ${leaves.length} leaves in SQLite for this company'
            ' | pending: ${leaves.where((l) => l.status == LeaveStatus.pending).length}'
            ' | approved: ${leaves.where((l) => l.status == LeaveStatus.approved).length}'
            ' | rejected: ${leaves.where((l) => l.status == LeaveStatus.rejected).length}');

        final filtered = filterStatus != null
            ? leaves.where((l) => l.status == filterStatus).toList()
            : leaves;

        final employees = employeesAsync.valueOrNull ?? [];
        final empMap = {for (final e in employees) e.id: e};

        // Count stats across all leaves (not just filtered)
        final totalAll = leaves.length;
        final approvedCount = leaves.where((l) => l.status == LeaveStatus.approved).length;
        final rejectedCount = leaves.where((l) => l.status == LeaveStatus.rejected).length;
        final pendingCount = leaves.where((l) => l.status == LeaveStatus.pending).length;

        return Column(
          children: [
            // ── Stats panel ──────────────────────────────────────────
            if (filterStatus == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _StatChip(label: context.l10n.total, count: totalAll, color: AppColors.primary),
                    const SizedBox(width: 8),
                    _StatChip(label: context.l10n.leaveApprovedPlural, count: approvedCount, color: AppColors.success),
                    const SizedBox(width: 8),
                    _StatChip(label: context.l10n.leaveRejectedPlural, count: rejectedCount, color: AppColors.error),
                    const SizedBox(width: 8),
                    _StatChip(label: context.l10n.leavePendingPlural, count: pendingCount, color: AppColors.warning),
                  ],
                ),
              ),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref
                      .read(leavesRefreshNotifierProvider.notifier)
                      .refresh();
                },
                child: filtered.isEmpty
                    ? _EmptyState(filterStatus: filterStatus, isAdmin: true)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final req = filtered[i];
                          final emp = empMap[req.employeeId];
                          return LeaveRequestCard(
                            request: req,
                            employeeName: emp?.displayName,
                            isAdmin: true,
                            onApprove: () => _review(
                              context, ref, req,
                              LeaveStatus.approved,
                              user?.user?.id ?? '',
                            ),
                            onReject: () => _showRejectDialog(
                              context, ref, req,
                              user?.user?.id ?? '',
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    LeaveRequest req,
    LeaveStatus status,
    String reviewerId,
  ) async {
    try {
      await ref.read(leavesNotifierProvider.notifier).reviewRequest(
            requestId: req.id,
            status: status,
            reviewedById: reviewerId,
            employeeId: req.employeeId,
            companyId: req.companyId,
            startDate: req.startDate,
            endDate: req.endDate,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == LeaveStatus.approved
                ? context.l10n.leaveApprovedMsg
                : context.l10n.leaveRejectedMsg),
            backgroundColor:
                status == LeaveStatus.approved ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    LeaveRequest req,
    String reviewerId,
  ) async {
    final noteCtrl = TextEditingController();
    // ⚠️  Use dlgCtx (the dialog's own context) for Navigator.pop so we close
    //     the dialog instead of the root navigator's shell route.
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text(context.l10n.rejectLeaveTitle,
            style: TextStyle(color: context.appColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.rejectReason,
                style: TextStyle(color: context.appColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: context.appColors.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.l10n.writeNote,
                hintStyle: TextStyle(color: context.appColors.textDisabled),
                filled: true,
                fillColor: context.appColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(context.l10n.reject,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    try {
      await ref.read(leavesNotifierProvider.notifier).reviewRequest(
            requestId: req.id,
            status: LeaveStatus.rejected,
            reviewedById: reviewerId,
            employeeId: req.employeeId,
            companyId: req.companyId,
            reviewNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            startDate: req.startDate,
            endDate: req.endDate,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.leaveRejectedMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Sync button ───────────────────────────────────────────────────────────────

/// AppBar action that triggers an immediate sync and shows a spinner while running.
class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final isSyncing = syncState.isLoading;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: context.l10n.syncNow,
        icon: isSyncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.sync, color: AppColors.primary),
        onPressed: isSyncing
            ? null
            : () async {
                // Full sync first (flushes employee queues), then pull leaves.
                await ref.read(syncNotifierProvider.notifier).sync();
                await ref.read(leavesRefreshNotifierProvider.notifier).refresh();
              },
      ),
    );
  }
}

// ── Leave stat chip ────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.grey400, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Employee view ──────────────────────────────────────────────────────────────

/// Using StatefulConsumerWidget so `mounted` is reliable across the async gap
/// between the dialog close and the delete operation completing.
class _EmployeeLeavesList extends ConsumerStatefulWidget {
  final LeaveStatus? filterStatus;

  const _EmployeeLeavesList({this.filterStatus});

  @override
  ConsumerState<_EmployeeLeavesList> createState() => _EmployeeLeavesListState();
}

class _EmployeeLeavesListState extends ConsumerState<_EmployeeLeavesList> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(myLeavesProvider);

    return leavesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (leaves) {
        final filtered = widget.filterStatus != null
            ? leaves.where((l) => l.status == widget.filterStatus).toList()
            : leaves;

        if (filtered.isEmpty) {
          return _EmptyState(filterStatus: widget.filterStatus, isAdmin: false);
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final req = filtered[i];
                return LeaveRequestCard(
                  request: req,
                  isAdmin: false,
                  // Disable button while a delete is already in-flight
                  onDelete: _deleting ? null : () => _delete(req.id),
                );
              },
            ),
            // Lightweight overlay while deleting — prevents double-tap crash
            if (_deleting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.transparent,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _delete(String requestId) async {
    // ⚠️  Use dlgCtx (the dialog's own context) for Navigator.pop.
    //     showDialog() uses the ROOT navigator (useRootNavigator: true by default).
    //     Calling Navigator.pop(context, value) with the SHELL/TAB context would
    //     pop the wrong navigator entry → black screen.
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text(
          context.l10n.cancelRequest,
          style: TextStyle(color: context.appColors.textPrimary),
        ),
        content: Text(
          context.l10n.confirmCancelRequest,
          style: TextStyle(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(
              context.l10n.cancelRequest,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;       // user cancelled
    if (!mounted) return;         // widget disposed while dialog was open

    setState(() => _deleting = true);
    try {
      await ref.read(leavesNotifierProvider.notifier).deleteRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.requestCancelledOk),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Leaves] Delete failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.errorDeleting}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final LeaveStatus? filterStatus;
  final bool isAdmin;

  const _EmptyState({this.filterStatus, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = filterStatus != null
        ? '${l10n.noLeavesFiltered} ${filterStatus!.label.toLowerCase()}'
        : isAdmin
            ? l10n.noLeaveRequests
            : l10n.noLeaveRequestsEmployee;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            final ac = context.appColors;
            return Icon(
              Icons.beach_access_outlined,
              size: 64,
              color: ac.textDisabled.withValues(alpha: 0.3),
            );
          }),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final ac = context.appColors;
            return Text(
              message,
              style: TextStyle(
                color: ac.textDisabled,
                fontSize: 14,
              ),
            );
          }),
          if (!isAdmin && filterStatus == null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.leaveNew),
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: Text(
                l10n.leaveRequestLabel,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

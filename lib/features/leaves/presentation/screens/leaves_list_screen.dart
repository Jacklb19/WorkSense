import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/leaves/presentation/widgets/leave_request_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = userState?.role == AppRole.admin ||
        userState?.role == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'PERMISOS',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.appOnSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.tabUnselectedLabelColor(),
          labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Rechazados'),
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
              label: const Text('Solicitar permiso'),
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
    final theme = Theme.of(context);
    final leavesAsync = ref.watch(companyLeavesProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return leavesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
      ),
      data: (leaves) {
        final filtered = filterStatus != null
            ? leaves.where((l) => l.status == filterStatus).toList()
            : leaves;

        final employees = employeesAsync.valueOrNull ?? [];
        final empMap = {for (final e in employees) e.id: e};

        final totalAll = leaves.length;
        final approvedCount = leaves.where((l) => l.status == LeaveStatus.approved).length;
        final rejectedCount = leaves.where((l) => l.status == LeaveStatus.rejected).length;
        final pendingCount = leaves.where((l) => l.status == LeaveStatus.pending).length;

        return Column(
          children: [
            if (filterStatus == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXl, AppDimensions.spacingXxl, 0),
                child: Row(
                  children: [
                    _StatChip(label: 'Total', count: totalAll, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.spacingMd),
                    _StatChip(label: 'Aprobados', count: approvedCount, color: AppColors.success),
                    const SizedBox(width: AppDimensions.spacingMd),
                    _StatChip(label: 'Rechazados', count: rejectedCount, color: AppColors.error),
                    const SizedBox(width: AppDimensions.spacingMd),
                    _StatChip(label: 'Pendientes', count: pendingCount, color: AppColors.warning),
                  ],
                ),
              ),

            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(filterStatus: filterStatus, isAdmin: true)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
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
              ? 'Permiso aprobado'
              : 'Permiso rechazado'),
          backgroundColor:
              status == LeaveStatus.approved ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    LeaveRequest req,
    String reviewerId,
  ) async {
    final theme = Theme.of(context);
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Rechazar permiso',
            style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Motivo del rechazo (opcional)',
                style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurfaceSecondary)),
            const SizedBox(height: AppDimensions.spacingMd),
            TextField(
              controller: noteCtrl,
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurface),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Escribe una nota…',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceDisabled),
                filled: true,
                fillColor: context.appBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: context.appGlassBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
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
          const SnackBar(
            content: Text('Permiso rechazado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd, horizontal: AppDimensions.spacingXs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: AppDimensions.fontTitleLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Employee view ──────────────────────────────────────────────────────────────

class _EmployeeLeavesList extends ConsumerWidget {
  final LeaveStatus? filterStatus;

  const _EmployeeLeavesList({this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leavesAsync = ref.watch(myLeavesProvider);

    return leavesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
      ),
      data: (leaves) {
        final filtered = filterStatus != null
            ? leaves.where((l) => l.status == filterStatus).toList()
            : leaves;

        if (filtered.isEmpty) {
          return _EmptyState(filterStatus: filterStatus, isAdmin: false);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXxl, AppDimensions.spacingXxl, 100),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final req = filtered[i];
            return LeaveRequestCard(
              request: req,
              isAdmin: false,
              onDelete: () => _delete(context, ref, req.id),
            );
          },
        );
      },
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String requestId) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title:
            Text('Cancelar solicitud', style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
        content: Text('¿Seguro que quieres cancelar esta solicitud?',
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(leavesNotifierProvider.notifier).deleteRequest(requestId);
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
    final theme = Theme.of(context);
    final message = filterStatus != null
        ? 'No hay permisos ${filterStatus!.label.toLowerCase()}'
        : isAdmin
            ? 'No hay solicitudes de permiso'
            : 'No has enviado solicitudes de permiso';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.beach_access_outlined,
            size: 64,
            color: context.appOnSurfaceDisabled,
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
          ),
          if (!isAdmin && filterStatus == null) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.leaveNew),
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text(
                'Solicitar permiso',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
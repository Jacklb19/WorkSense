import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_dashboard_card.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email;

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: ac.surface,
        onRefresh: () async {
          await ref.read(syncNotifierProvider.notifier).sync();
          ref.invalidate(adminEmployeesProvider);
          ref.invalidate(employeeAnalyticsProvider);
          ref.invalidate(employeeDetailProvider);
          ref.invalidate(employeeAttendanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _DashboardHeader(
                userEmail: userEmail,
                ref: ref,
              ),
            ),

            // ── KPI panel ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _KpiPanel(ref: ref),
            ),

            // ── Quick actions row 1 ──────────────────────────────────────
            const SliverToBoxAdapter(child: _QuickActionsRow()),

            // ── Quick actions row 2 (Nómina + Evaluaciones) ──────────────
            const SliverToBoxAdapter(child: _QuickActionsRow2()),

            // ── Employee list ────────────────────────────────────────────
            employeesAsync.when(
              loading: () => SliverFillRemaining(
                child: AppLoadingWidget(message: context.l10n.loadingCollaborators),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorView(error: error.toString()),
              ),
              data: (employees) {
                final l10n = context.l10n;
                if (employees.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: l10n.noCollaboratorsYet,
                      subtitle: l10n.noCollaboratorsSubtitle,
                      actionLabel: l10n.registerEmployee,
                      actionIcon: Icons.person_add_rounded,
                      onAction: () => context.push(AppRoutes.employeeNew),
                    ),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: AppColors.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.employees.toUpperCase(),
                              style: TextStyle(
                                color: ac.textSecondary
                                    .withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '${employees.length}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 176,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => EmployeeDashboardCard(
                              employee: employees[index]),
                          childCount: employees.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDimensions.spacing100),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String? userEmail;
  final WidgetRef ref;

  const _DashboardHeader({this.userEmail, required this.ref});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            context.appColors.background,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.greeting(),
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.controlPanel,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell (replaces announcement bell — includes all notifications)
          const NotificationBellButton(isIconButton: false),
          const SizedBox(width: 6),
          // Chat button
          _HeaderIconBtn(
            icon: Icons.forum_rounded,
            tooltip: l10n.conversations,
            onTap: () => context.push(AppRoutes.chatList),
          ),
          const SizedBox(width: 4),
          // Analytics button
          _HeaderIconBtn(
            icon: Icons.bar_chart_rounded,
            tooltip: l10n.analytics,
            onTap: () => context.push(AppRoutes.analytics),
          ),
          const SizedBox(width: 4),
          const SyncIndicatorWidget(),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.meeting_room_rounded,
              label: l10n.kiosk.toUpperCase(),
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.entrance),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.desktop_windows_rounded,
              label: l10n.stations.toUpperCase(),
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.workstations),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.picture_as_pdf_rounded,
              label: l10n.reports.toUpperCase(),
              color: AppColors.accent,
              onTap: () => context.push(AppRoutes.reports),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions row 2 ───────────────────────────────────────────────────────
// Nómina oculta temporalmente (tiene errores) — el botón se reactiva cuando esté listo.

class _QuickActionsRow2 extends StatelessWidget {
  const _QuickActionsRow2();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.star_rounded,
              label: l10n.evaluations.toUpperCase(),
              color: AppColors.accent,
              onTap: () => context.push(AppRoutes.evaluations),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Panel ─────────────────────────────────────────────────────────────────

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final employeeCount =
        ref.watch(adminEmployeesProvider).valueOrNull?.length ?? 0;
    final workstationCount =
        ref.watch(workstationsProvider).valueOrNull?.length ?? 0;
    final pendingTasks = ref
            .watch(companyTasksProvider)
            .valueOrNull
            ?.where((t) =>
                t.status.name == 'pending' || t.status.name == 'inProgress')
            .length ??
        0;
    final unackAlerts = ref.watch(unacknowledgedAlertCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _KpiTile(
              icon: Icons.people_rounded,
              label: l10n.navEmployees,
              value: employeeCount,
              colors: AppColors.cyanGradient,
              onTap: () => context.push(AppRoutes.employees),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.computer_rounded,
              label: l10n.stations,
              value: workstationCount,
              colors: AppColors.primaryGradient,
              onTap: () => context.push(AppRoutes.workstations),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.task_alt_rounded,
              label: l10n.navTasks,
              value: pendingTasks,
              colors: AppColors.warningGradient,
              onTap: () => context.push(AppRoutes.tasks),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.warning_amber_rounded,
              label: l10n.alerts,
              value: unackAlerts,
              colors: AppColors.errorGradient,
              onTap: () => context.push(AppRoutes.alertLog),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colors.first;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.errorLoadingData,
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Icon(icon, size: 18, color: context.appColors.textSecondary),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_dashboard_card.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
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
              loading: () => const SliverFillRemaining(
                child: AppLoadingWidget(message: 'Cargando colaboradores…'),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorView(error: error.toString()),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyEmployeesView(userEmail: userEmail),
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
                              'COLABORADORES',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.backgroundDark,
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
                  greeting,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Comando Central',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
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
            tooltip: 'Conversaciones',
            onTap: () => context.push(AppRoutes.chatList),
          ),
          const SizedBox(width: 4),
          // Analytics button
          _HeaderIconBtn(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Analíticas',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.meeting_room_rounded,
              label: 'KIOSCO',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.entrance),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.desktop_windows_rounded,
              label: 'ESTACIONES',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.workstations),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.picture_as_pdf_rounded,
              label: 'REPORTES',
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

class _QuickActionsRow2 extends StatelessWidget {
  const _QuickActionsRow2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.attach_money_rounded,
              label: 'NÓMINA',
              color: const Color(0xFF10B981),
              onTap: () => context.push(AppRoutes.payroll),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionChip(
              icon: Icons.star_rounded,
              label: 'EVALUACIONES',
              color: const Color(0xFF8B5CF6),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
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
    );
  }
}

// ── KPI Panel ─────────────────────────────────────────────────────────────────

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
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
    final pendingLeaves = ref.watch(pendingLeavesCountProvider);
    final unackAlerts = ref.watch(unacknowledgedAlertCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _KpiTile(
              icon: Icons.people_rounded,
              label: 'Empleados',
              value: employeeCount,
              colors: AppColors.cyanGradient,
              onTap: () => context.push(AppRoutes.employees),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.computer_rounded,
              label: 'Estaciones',
              value: workstationCount,
              colors: AppColors.primaryGradient,
              onTap: () => context.push(AppRoutes.workstations),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.task_alt_rounded,
              label: 'Tareas',
              value: pendingTasks,
              colors: AppColors.warningGradient,
              onTap: () => context.push(AppRoutes.tasks),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.event_note_rounded,
              label: 'Permisos',
              value: pendingLeaves,
              colors: AppColors.successGradient,
              onTap: () => context.push(AppRoutes.leaves),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiTile(
              icon: Icons.warning_amber_rounded,
              label: 'Alertas',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
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
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
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
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyEmployeesView extends ConsumerWidget {
  final String? userEmail;

  const _EmptyEmployeesView({this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin colaboradores aún',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra empleados para comenzar a\ngestionar asistencia y productividad.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.employeeNew),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Registrar empleado'),
            ),
          ],
        ),
      ),
    );
  }
}

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
            const Text(
              AppStrings.errorLoadingData,
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
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
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }
}

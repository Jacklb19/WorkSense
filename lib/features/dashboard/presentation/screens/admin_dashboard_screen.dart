import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncNotifierProvider.notifier).sync();
          ref.invalidate(adminEmployeesProvider);
          ref.invalidate(employeeAnalyticsProvider);
          ref.invalidate(employeeDetailProvider);
          ref.invalidate(employeeAttendanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text(
                'Comando central',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                _AnnouncementBell(ref: ref),
                IconButton(
                  icon: const Icon(Icons.bar_chart_outlined),
                  tooltip: 'Analíticas',
                  onPressed: () => context.push(AppRoutes.analytics),
                ),
                const SyncIndicatorWidget(),
                const SizedBox(width: 8),
              ],
            ),

            // ── KPI panel ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _KpiPanel(ref: ref),
            ),

            employeesAsync.when(
              loading: () =>
                  const SliverFillRemaining(child: AppLoadingWidget()),
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
                      padding: const EdgeInsets.all(24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COLABORADORES',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tus trabajadores',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisExtent: 180,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              EmployeeDashboardCard(employee: employees[index]),
                          childCount: employees.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'reports_btn',
            mini: true,
            onPressed: () => context.push(AppRoutes.reports),
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.white,
            tooltip: 'Reportes PDF',
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'kiosk_btn',
            onPressed: () {
              context.push(AppRoutes.workstations);
            },
            icon: const Icon(Icons.desktop_windows),
            label: const Text('VER ESTACIONES'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'entrance_btn',
            onPressed: () => context.push(AppRoutes.entrance),
            icon: const Icon(Icons.meeting_room),
            label: const Text('KIOSCO RECEPCION'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _EmptyEmployeesView extends ConsumerWidget {
  final String? userEmail;

  const _EmptyEmployeesView({this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay colaboradores',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra a tus empleados para administrar su asistencia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.employeeNew),
              icon: const Icon(Icons.add),
              label: const Text('REGISTRAR EMPLEADO'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.errorLoadingData,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.grey500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI panel ─────────────────────────────────────────────────────────────────

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final employeeCount = ref.watch(adminEmployeesProvider).valueOrNull?.length ?? 0;
    final workstationCount = ref.watch(workstationsProvider).valueOrNull?.length ?? 0;
    final pendingTasks = ref.watch(companyTasksProvider).valueOrNull
            ?.where((t) =>
                t.status.name == 'pending' || t.status.name == 'inProgress')
            .length ??
        0;
    final pendingLeaves = ref.watch(pendingLeavesCountProvider);
    final unackAlerts = ref.watch(unacknowledgedAlertCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  icon: Icons.people_outline,
                  label: 'Empleados',
                  value: employeeCount,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.employees),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  icon: Icons.computer,
                  label: 'Estaciones',
                  value: workstationCount,
                  color: AppColors.info,
                  onTap: () => context.push(AppRoutes.workstations),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  icon: Icons.task_alt,
                  label: 'Tareas pend.',
                  value: pendingTasks,
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.tasks),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  icon: Icons.event_note_outlined,
                  label: 'Permisos',
                  value: pendingLeaves,
                  color: AppColors.success,
                  onTap: () => context.push(AppRoutes.leaves),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Alertas',
                  value: unackAlerts,
                  color: AppColors.error,
                  onTap: () => context.push(AppRoutes.alertLog),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.grey400,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement bell button with unread badge ────────────────────────────────

class _AnnouncementBell extends StatelessWidget {
  const _AnnouncementBell({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadAnnouncementsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.campaign_outlined),
          tooltip: 'Comunicados',
          onPressed: () => context.push(AppRoutes.announcements),
        ),
        if (unread > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/dashboard/presentation/helpers/hours_formatters.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_section_header.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final userState = ref.watch(currentUserProvider);
    final userEmail =
        userState.valueOrNull?.user?.email ?? l10n.employee;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySpace),
        centerTitle: false,
        actions: [
          // Notification bell (unified: tasks, leaves, messages, etc.)
          const NotificationBellButton(),
          // Chat with admin
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: l10n.messages,
            onPressed: () => context.push(
              AppRoutes.chatList,
              extra: {'isEmployee': true},
            ),
          ),
          const SyncIndicatorWidget(),
          const SizedBox(width: AppDimensions.spacingMd),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: context.appColors.surface,
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header con gradiente ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      context.appColors.background,
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.glassBorder, width: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.greeting(),
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.todaySummary,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(title: l10n.assignedWorkstation,
                        icon: Icons.desktop_windows_rounded),
                    const _AssignedWorkstationSection(),
                    const SizedBox(height: 24),

                    AppSectionHeader(title: l10n.myProductivityToday,
                        icon: Icons.bar_chart_rounded),
                    const _PersonalProductivitySection(),
                    const SizedBox(height: 24),

                    AppSectionHeader(title: l10n.recentActivityLive,
                        icon: Icons.history_rounded),
                    const _RecentActivitySection(),
                    const SizedBox(height: 24),

                    AppSectionHeader(title: l10n.myTasksLabel,
                        icon: Icons.task_alt_rounded),
                    const _TaskMiniWidget(),
                    const SizedBox(height: 24),

                    AppSectionHeader(title: l10n.quickAccess,
                        icon: Icons.grid_view_rounded),
                    _QuickAccessCard(
                      icon: Icons.history_rounded,
                      title: l10n.myActivity,
                      subtitle: l10n.myActivitySubtitle,
                      route: AppRoutes.myActivity,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.schedule_rounded,
                      title: l10n.myHours,
                      subtitle: l10n.myHoursSubtitle,
                      route: AppRoutes.myHours,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.person_rounded,
                      title: l10n.myProfile,
                      subtitle: l10n.myProfileSubtitle,
                      route: AppRoutes.profile,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.star_rounded,
                      title: l10n.myEvaluations,
                      subtitle: l10n.myEvaluationsSubtitle,
                      route: AppRoutes.evaluations,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _greeting() moved to AppLocalizations.greeting()

// ── Assigned Workstation ──────────────────────────────────────────────────────
class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync =
        ref.watch(employeeAssignedWorkstationProvider);

    return workstationAsync.when(
      loading: () => AppLoadingWidget(message: context.l10n.verifyingWorkstation),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudo cargar la información del puesto de trabajo. Desliza hacia abajo para reintentar.',
      ),
      data: (workstation) {
        if (workstation == null) {
          return const _NoWorkstationCard();
        }
        return _WorkstationCard(workstation: workstation);
      },
    );
  }
}

class _NoWorkstationCard extends StatelessWidget {
  const _NoWorkstationCard();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.grey600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.desktop_access_disabled_rounded,
                color: ac.textDisabled, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.noAssignedWorkstation,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.noAssignedWorkstationDesc,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkstationCard extends StatelessWidget {
  final WorkstationRecord workstation;
  const _WorkstationCard({required this.workstation});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.computer_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workstation.name,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.monitoringAssigned,
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

class _PersonalProductivitySection extends ConsumerWidget {
  const _PersonalProductivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => AppLoadingWidget(message: context.l10n.calculatingTime),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudieron cargar tus métricas de productividad. Desliza hacia abajo para reintentar.',
      ),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing24),
              child: Center(
                child: Text(
                  context.l10n.noActivityToday,
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
            ),
          );
        }

        final totalDuration = analytics.totalTrackedTime;
        final workTime =
            analytics.stateDurations[ActivityState.trabajando] ??
                Duration.zero;
        final distractTime =
            analytics.stateDurations[ActivityState.distraido] ??
                Duration.zero;
        final fatigueTime =
            analytics.stateDurations[ActivityState.fatiga] ??
                Duration.zero;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total: ${HoursFormatters.formatDuration(totalDuration)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimensions.fontTitle,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                _StatBarRow(
                  label: context.l10n.working,
                  duration: workTime,
                  total: totalDuration,
                  color: AppColors.primary,
                  icon: Icons.work,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _StatBarRow(
                  label: context.l10n.distracted,
                  duration: distractTime,
                  total: totalDuration,
                  color: AppColors.warning,
                  icon: Icons.search,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _StatBarRow(
                  label: context.l10n.fatigue,
                  duration: fatigueTime,
                  total: totalDuration,
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _StatBarRow extends StatelessWidget {
  final String label;
  final Duration duration;
  final Duration total;
  final Color color;
  final IconData icon;

  const _StatBarRow({
    required this.label,
    required this.duration,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage =
        total.inSeconds > 0 ? (duration.inSeconds / total.inSeconds) : 0.0;

    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconXs, color: color),
        const SizedBox(width: AppDimensions.spacingMd),
        SizedBox(
          width: AppDimensions.statBarLabelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppDimensions.fontBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withAlpha(25),
              color: color,
              minHeight: AppDimensions.progressBarHeight,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        SizedBox(
          width: AppDimensions.statBarValueWidth,
          child: Text(
            HoursFormatters.formatDuration(duration),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: AppDimensions.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(employeeRecentEventsProvider);

    return eventsAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudo cargar la actividad reciente. Desliza hacia abajo para reintentar.',
      ),
      data: (events) {
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Center(
              child: Text(
                context.l10n.noRecentEvents,
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < events.length; i++) ...[
                ListTile(
                  leading: Container(
                    width: AppDimensions.stateIndicatorSize * 1.5,
                    height: AppDimensions.stateIndicatorSize * 1.5,
                    decoration: BoxDecoration(
                      color: events[i].state.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    events[i].state.label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(_formatTime(events[i].timestamp)),
                  trailing: events[i].identificationMethod != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingMd,
                            vertical: AppDimensions.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Text(
                            events[i].identificationMethod!,
                            style: TextStyle(
                              fontSize: AppDimensions.fontXs,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),
                if (i < events.length - 1)
                  Divider(height: 1, color: context.appColors.divider),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    final sec = time.second.toString().padLeft(2, '0');
    return '$hour:$min:$sec';
  }
}

// ── Task Mini Widget ────────────────────────────────────────────────────────

class _TaskMiniWidget extends ConsumerWidget {
  const _TaskMiniWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksProvider);

    return tasksAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final overdue = tasks.where((t) => t.isOverdue).length;

        final ac = context.appColors;
        return Material(
          color: ac.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.go(AppRoutes.tasks),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ac.divider),
              ),
              child: Row(
                children: [
                  _TaskCountBadge(count: pending, label: 'Pendientes', color: ac.textSecondary),
                  const _TaskDivider(),
                  _TaskCountBadge(count: inProgress, label: 'En curso', color: AppColors.primary),
                  const _TaskDivider(),
                  _TaskCountBadge(count: overdue, label: 'Vencidas', color: AppColors.error),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: ac.textDisabled),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskCountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _TaskCountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey500, fontSize: 10),
        ),
      ],
    );
  }
}

class _TaskDivider extends StatelessWidget {
  const _TaskDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.glassBorder,
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Material(
      color: ac.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: ac.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

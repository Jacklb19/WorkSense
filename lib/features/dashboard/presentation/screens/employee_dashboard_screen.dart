import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(currentUserProvider);
    final userEmail =
        userState.valueOrNull?.user?.email ?? AppStrings.employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mySpace),
        centerTitle: false,
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Mensajes',
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
        backgroundColor: context.appSurface,
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.backgroundDark,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: context.appGlassBorder, width: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurfaceSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.todaySummary,
                      style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurfaceSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacing20),
              AppContentConstrainer(
                width: AppContentWidth.dashboard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(label: AppStrings.assignedWorkstation,
                        icon: Icons.desktop_windows_rounded),
                    const SizedBox(height: 10),
                    _AssignedWorkstationSection(),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    _SectionHeader(label: AppStrings.myProductivityToday,
                        icon: Icons.bar_chart_rounded),
                    const SizedBox(height: 10),
                    _PersonalProductivitySection(),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    _SectionHeader(label: AppStrings.recentActivityLive,
                        icon: Icons.history_rounded),
                    const SizedBox(height: 10),
                    _RecentActivitySection(),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    _SectionHeader(label: 'MIS TAREAS',
                        icon: Icons.task_alt_rounded),
                    const SizedBox(height: 10),
                    _TaskMiniWidget(),
                    const SizedBox(height: AppDimensions.spacingXxl),

                    _SectionHeader(label: 'ACCESOS RÁPIDOS',
                        icon: Icons.grid_view_rounded),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.history_rounded,
                      title: 'Mi actividad',
                      subtitle: 'Ver historial personal detallado',
                      route: AppRoutes.myActivity,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.schedule_rounded,
                      title: 'Mis horas',
                      subtitle: 'Consultar horas, sesiones y resumen diario',
                      route: AppRoutes.myHours,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.person_rounded,
                      title: 'Mi perfil',
                      subtitle: 'Ver estadísticas personales y datos de cuenta',
                      route: AppRoutes.profile,
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessCard(
                      icon: Icons.star_rounded,
                      title: 'Mis evaluaciones',
                      subtitle: 'Consultar tus evaluaciones de desempeño',
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

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días \u{1F44B}';
  if (h < 18) return 'Buenas tardes \u{1F44B}';
  return 'Buenas noches \u{1F44B}';
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appOnSurfaceSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync =
        ref.watch(employeeAssignedWorkstationProvider);

    return workstationAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.verifyingWorkstation),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: context.appDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.grey600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            ),
            child: Icon(Icons.desktop_access_disabled_rounded,
                color: context.appOnSurfaceDisabled, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noAssignedWorkstation,
                  style: theme.textTheme.labelLarge?.copyWith(color: context.appOnSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.noAssignedWorkstationDescription,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.computer_rounded,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workstation.name,
                  style: theme.textTheme.titleSmall?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w700),
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
                      AppStrings.monitoringAssigned,
                      style: theme.textTheme.labelMedium?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
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
    final theme = Theme.of(context);
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.calculatingTime),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudieron cargar tus métricas de productividad. Desliza hacia abajo para reintentar.',
      ),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              side: BorderSide(color: context.appGlassBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing24),
child: Center(
                  child: Text(
                    AppStrings.noActivityToday,
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
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
            side: BorderSide(color: context.appGlassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total: ${_formatDuration(totalDuration)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                _StatBarRow(
                  label: 'Trabajando',
                  duration: workTime,
                  total: totalDuration,
                  color: AppColors.primary,
                  icon: Icons.work,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _StatBarRow(
                  label: 'Distraido',
                  duration: distractTime,
                  total: totalDuration,
                  color: AppColors.warning,
                  icon: Icons.search,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _StatBarRow(
                  label: 'Fatiga',
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

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
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
    final theme = Theme.of(context);
    final double percentage =
        total.inSeconds > 0 ? (duration.inSeconds / total.inSeconds) : 0.0;

    String formatDuration(Duration d) {
      if (d.inMinutes < 1) return '${d.inSeconds}s';
      if (d.inHours < 1) return '${d.inMinutes}m';
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }

    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconXs, color: color),
        const SizedBox(width: AppDimensions.spacingMd),
        SizedBox(
          width: AppDimensions.statBarLabelWidth,
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
            formatDuration(duration),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
    final theme = Theme.of(context);
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
                AppStrings.noRecentEvents,
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
              ),
            ),
          );
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            side: BorderSide(color: context.appGlassBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: context.appDivider),
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Container(
                  width: AppDimensions.stateIndicatorSize * 1.5,
                  height: AppDimensions.stateIndicatorSize * 1.5,
                  decoration: BoxDecoration(
                    color: event.state.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  event.state.label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_formatTime(event.timestamp)),
                trailing: event.identificationMethod != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingMd,
                          vertical: AppDimensions.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: context.appSurface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            color: context.appOnSurfaceSecondary,
                          ),
                        ),
                      )
                    : null,
              );
            },
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

        return Semantics(
          button: true,
          label: 'Mis tareas',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            child: InkWell(
              onTap: () => context.go(AppRoutes.tasks),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  border: Border.all(color: context.appDivider),
                ),
                child: Row(
                  children: [
                    _TaskCountBadge(count: pending, label: 'Pendientes', color: context.appOnSurfaceSecondary),
                    const _TaskDivider(),
                    _TaskCountBadge(count: inProgress, label: 'En curso', color: AppColors.primary),
                    const _TaskDivider(),
                    _TaskCountBadge(count: overdue, label: 'Vencidas', color: AppColors.error),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: context.appOnSurfaceDisabled),
                  ],
                ),
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
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.grey500, fontSize: AppDimensions.fontXs),
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
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
      color: context.appGlassBorder,
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
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: 14),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              border: Border.all(color: context.appDivider),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
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
                        style: theme.textTheme.labelLarge?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.appOnSurfaceDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
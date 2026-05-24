import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../../domain/entities/activity_state.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/styled/app_section_header.dart';
import '../../../../shared/widgets/sync_indicator_widget.dart';
import '../../presentation/providers/employee_dashboard_provider.dart';

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
          const SyncIndicatorWidget(),
          const SizedBox(width: AppDimensions.spacingMd),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hola, $userEmail',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                AppStrings.todaySummary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              const AppSectionHeader(title: AppStrings.assignedWorkstation),
              const _AssignedWorkstationSection(),
              const SizedBox(height: AppDimensions.spacing24),
              const AppSectionHeader(title: AppStrings.myProductivityToday),
              const _PersonalProductivitySection(),
              const SizedBox(height: AppDimensions.spacing24),
              const AppSectionHeader(title: AppStrings.recentActivityLive),
              const _RecentActivitySection(),
              const SizedBox(height: AppDimensions.spacing40),
            ],
          ),
        ),
      ),
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
      loading: () =>
          const AppLoadingWidget(message: AppStrings.verifyingWorkstation),
      error: (e, _) => Card(
        color: AppColors.errorSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppDimensions.spacingXxl),
          child: Text(AppStrings.errorLoadingWorkstation),
        ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingXxl),
        child: Row(
          children: [
            Icon(
              Icons.desktop_access_disabled,
              color: AppColors.textDisabled,
              size: AppDimensions.iconXl,
            ),
            SizedBox(width: AppDimensions.spacingXxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.noAssignedWorkstation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontTitle,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    AppStrings.noAssignedWorkstationDescription,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimensions.fontBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkstationCard extends StatelessWidget {
  final WorkstationRecord workstation;
  const _WorkstationCard({required this.workstation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        side: BorderSide(color: AppColors.primary.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.computer, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.spacingXxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workstation.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontTitle,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Row(
                    children: [
                      Container(
                        width: AppDimensions.stateIndicatorSize,
                        height: AppDimensions.stateIndicatorSize,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        AppStrings.monitoringAssigned,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      loading: () =>
          const AppLoadingWidget(message: AppStrings.calculatingTime),
      error: (e, _) =>
          Text(AppStrings.couldNotLoadMetrics, style: const TextStyle(color: AppColors.error)),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.spacing24),
              child: Center(
                child: Text(
                  AppStrings.noActivityToday,
                  style: TextStyle(color: AppColors.textSecondary),
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
                  'Tiempo total: ${_formatDuration(totalDuration)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimensions.fontTitle,
                  ),
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
            formatDuration(duration),
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
      error: (e, _) => Text(
        AppStrings.errorLoadingHistory,
        style: const TextStyle(color: AppColors.error),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingXxl),
            child: Center(
              child: Text(
                AppStrings.noRecentEvents,
                style: TextStyle(color: AppColors.textSecondary),
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_formatTime(event.timestamp)),
                trailing: event.identificationMethod != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingMd,
                          vertical: AppDimensions.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontXs,
                            color: AppColors.textSecondary,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_section_header.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email ?? AppStrings.employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mySpace),
        centerTitle: false,
        actions: const [
          SyncIndicatorWidget(),
          SizedBox(width: AppDimensions.spacingMd),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
          // employeeRecentEventsProvider is a stream so it updates automatically
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Section 1: Assigned Workstation
              const AppSectionHeader(title: AppStrings.assignedWorkstation),
              const _AssignedWorkstationSection(),
              const SizedBox(height: AppDimensions.spacing24),

              // Section 2: Personal Productivity
              const AppSectionHeader(title: AppStrings.myProductivityToday),
              const _PersonalProductivitySection(),
              const SizedBox(height: AppDimensions.spacing24),

              // Section 3: Recent Activity Feed
              const AppSectionHeader(title: AppStrings.recentActivityLive),
              const _RecentActivitySection(),
              const SizedBox(height: AppDimensions.spacing24),

              const AppSectionHeader(title: 'ACCESOS RAPIDOS'),
              const _QuickAccessCard(
                icon: Icons.history,
                title: 'Mi actividad',
                subtitle: 'Ver historial personal detallado',
                route: AppRoutes.myActivity,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              const _QuickAccessCard(
                icon: Icons.schedule,
                title: 'Mis horas',
                subtitle: 'Consultar horas, sesiones y resumen diario',
                route: AppRoutes.myHours,
              ),
              const SizedBox(height: AppDimensions.spacing40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assigned Workstation ──────────────────────────────────────────────────────
class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync = ref.watch(employeeAssignedWorkstationProvider);

    return workstationAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.verifyingWorkstation),
      error: (e, _) => Card(
        color: AppColors.error.withValues(alpha: 0.1),
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
        side: const BorderSide(color: AppColors.grey300),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingXxl),
        child: Row(
          children: [
            Icon(Icons.desktop_access_disabled, color: AppColors.grey500, size: AppDimensions.iconXl),
            SizedBox(width: AppDimensions.spacingXxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.noAssignedWorkstation,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontTitle),
                  ),
                  SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    AppStrings.noAssignedWorkstationDescription,
                    style: TextStyle(color: AppColors.grey600, fontSize: AppDimensions.fontBody),
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
      elevation: AppDimensions.cardElevation,
      shadowColor: AppColors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontTitle),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Row(
                    children: [
Semantics(
                        label: 'Estado activo',
                        child: Container(
                          width: AppDimensions.stateIndicatorSize,
                          height: AppDimensions.stateIndicatorSize,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      const Text(
                        AppStrings.monitoringAssigned,
                        style: TextStyle(color: AppColors.grey600, fontSize: AppDimensions.fontBody),
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

// ── Personal Productivity ───────────────────────────────────────────────────
class _PersonalProductivitySection extends ConsumerWidget {
  const _PersonalProductivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.calculatingTime),
      error: (e, _) => const Text(AppStrings.couldNotLoadMetrics),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacing24),
              child: Center(
                child: Text(AppStrings.noActivityToday, style: TextStyle(color: AppColors.grey600)),
              ),
            ),
          );
        }

        final totalDuration = analytics.totalTrackedTime;
        final workTime = analytics.stateDurations[ActivityState.trabajando] ?? Duration.zero;
        final distractTime = analytics.stateDurations[ActivityState.distraido] ?? Duration.zero;
        final fatigueTime = analytics.stateDurations[ActivityState.fatiga] ?? Duration.zero;

        return Card(
          elevation: AppDimensions.cardElevation,
          shadowColor: AppColors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total: ${_formatDuration(totalDuration)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontTitle),
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
                  label: 'Distraído',
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
    final double percentage = total.inSeconds > 0 
      ? (duration.inSeconds / total.inSeconds)
      : 0.0;
      
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
          child: Text(label, style: const TextStyle(fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: AppDimensions.progressBarHeightSm,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        SizedBox(
          width: AppDimensions.statBarValueWidth,
          child: Text(
            formatDuration(duration),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}


// ── Recent Activity Feed ────────────────────────────────────────────────────
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(employeeRecentEventsProvider);

    return eventsAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => const Text(AppStrings.errorLoadingHistory),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingXxl),
            child: Center(child: Text(AppStrings.noRecentEvents, style: TextStyle(color: AppColors.grey500))),
          );
        }

        return Card(
          elevation: AppDimensions.cardElevation,
          shadowColor: AppColors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
leading: Semantics(
                  label: event.state.label,
                  child: Container(
                    width: AppDimensions.stateBreakdownDotSize,
                    height: AppDimensions.stateBreakdownDotSize,
                    decoration: BoxDecoration(
                      color: event.state.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                title: Text(
                  event.state.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_formatTime(event.timestamp)),
                trailing: event.identificationMethod != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd, vertical: AppDimensions.spacingXxs),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: const TextStyle(fontSize: AppDimensions.fontXs, color: AppColors.grey700),
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
    return Card(
      elevation: AppDimensions.cardElevation,
      shadowColor: AppColors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingXxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimensions.fontTitle,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: AppDimensions.fontBody,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
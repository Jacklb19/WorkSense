import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../domain/entities/activity_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/styled/app_empty_state.dart';
import '../../../../shared/widgets/styled/app_content_constrainer.dart';
import '../../domain/entities/employee_analytics.dart';
import '../providers/admin_analytics_provider.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeAnalyticsProvider);
    final dateRange = ref.watch(analyticsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiticas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeeAnalyticsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingXxl,
              AppDimensions.spacingLg,
              AppDimensions.spacingXxl,
              AppDimensions.spacingXs,
            ),
            child: Row(
              children: [
                _DateChip(
                  label: 'Hoy',
                  selected: dateRange == AnalyticsDateRange.today,
                  onTap: () => ref
                      .read(analyticsDateRangeProvider.notifier)
                      .state = AnalyticsDateRange.today,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                _DateChip(
                  label: 'Esta semana',
                  selected: dateRange == AnalyticsDateRange.thisWeek,
                  onTap: () => ref
                      .read(analyticsDateRangeProvider.notifier)
                      .state = AnalyticsDateRange.thisWeek,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'Leyenda de estados',
                  onPressed: () => _showLegend(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: analyticsAsync.when(
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacing24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingXl),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusCard,
                          ),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: AppDimensions.iconEmptyState,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      Text(
                        'Error: $e',
                        style: TextStyle(color: context.appOnSurfaceSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (analyticsList) {
                if (analyticsList.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.analytics_outlined,
                    title: 'Sin datos de analiticas',
                    subtitle:
                        'Los datos apareceran cuando el sistema registre actividad de empleados.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(employeeAnalyticsProvider),
                  child: AppContentConstrainer(
                    width: AppContentWidth.dashboard,
                    child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.spacingXxl,
                      AppDimensions.spacingMd,
                      AppDimensions.spacingXxl,
                      AppDimensions.spacing80,
                    ),
                    itemCount: analyticsList.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.spacingXl),
                    itemBuilder: (context, index) =>
                        _EmployeeAnalyticsCard(
                          analytics: analyticsList[index],
                          onTap: () => context.push(
                            '/analytics/${analyticsList[index].employee.id}',
                          ),
                        ).animate().fadeIn(
                              delay: (index * 60).ms,
                              duration: AppDimensions.animEntrance,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLegend(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leyenda de estados',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            ...ActivityState.values.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingXs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppDimensions.spacingXxl,
                      height: AppDimensions.spacingXxl,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingLg),
                    Text(s.label),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(38),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : context.appOnSurfaceSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : context.appGlassBorder,
      ),
    );
  }
}

class _EmployeeAnalyticsCard extends StatelessWidget {
  final EmployeeAnalytics analytics;
  final VoidCallback onTap;

  const _EmployeeAnalyticsCard({
    required this.analytics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emp = analytics.employee;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: BorderSide(color: context.appGlassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarSm / 2,
                    backgroundColor: AppColors.primary.withAlpha(25),
                    child: Text(
                      emp.name.isNotEmpty
                          ? emp.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimensions.fontTitleLg,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacingXxs),
                        Text(
                          analytics.hasData
                              ? '${analytics.totalEvents} eventos - ${_formatDuration(analytics.totalTrackedTime)}'
                              : 'Sin datos registrados',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.appOnSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.appOnSurfaceDisabled,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'Tiempo total',
                    value: _formatDuration(analytics.totalTrackedTime),
                  ),
                  _MiniStat(
                    label: 'Eventos',
                    value: '${analytics.totalEvents}',
                  ),
                  _MiniStat(
                    label: 'Productividad',
                    value: '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appOnSurface,
              ),
        ),
        const SizedBox(height: AppDimensions.spacingXxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.appOnSurfaceSecondary,
              ),
        ),
      ],
    );
  }
}
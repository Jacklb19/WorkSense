import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeAnalyticsProvider);
    final dateRange = ref.watch(analyticsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analíticas'),
        centerTitle: false,
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeeAnalyticsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date Range Toggle ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingLg, AppDimensions.spacingXxl, AppDimensions.spacingXs),
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
                // Legend popover
                IconButton(
                  icon: const Icon(Icons.info_outline, size: AppDimensions.iconMd),
                  tooltip: 'Leyenda de estados',
                  onPressed: () => _showLegend(context),
                ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────
          Expanded(
            child: analyticsAsync.when(
              loading: () => const AppLoadingWidget(),
              error: (e, _) => Center(
                child: Padding(
padding: const EdgeInsets.all(AppDimensions.spacing24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: AppDimensions.iconEmptyState,
                      ),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      Text('Error: $e',
                          style: const TextStyle(color: AppColors.grey500),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              data: (analyticsList) {
                if (analyticsList.isEmpty) {
                  return const AppEmptyState(icon: Icons.bar_chart_outlined, title: 'Sin datos de analíticas', subtitle: 'Los datos aparecerán cuando el sistema\nregistre actividad de empleados.');
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(employeeAnalyticsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingMd, AppDimensions.spacingXxl, 80),
                    itemCount: analyticsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacing10),
                    itemBuilder: (context, index) =>
                        _EmployeeAnalyticsCard(
                      analytics: analyticsList[index],
                      onTap: () => context.push(
                        '/analytics/${analyticsList[index].employee.id}',
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
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusRound)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leyenda de estados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            ...ActivityState.values.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: s.color,
borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
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

// ── Date Range Chip ──────────────────────────────────────────────────────────

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
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.grey600,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.grey300,
      ),
    );
  }
}

// ── Employee Analytics Card ──────────────────────────────────────────────────

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
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarRadiusSm,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                              ? '${analytics.totalEvents} eventos · ${_formatDuration(analytics.totalTrackedTime)}'
                              : 'Sin datos registrados',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (analytics.lastState != null) _StateDot(analytics.lastState!),
                  const SizedBox(width: AppDimensions.spacingXs),
                  const Icon(Icons.chevron_right, color: AppColors.grey400),
                ],
              ),

              // Distribution bar
              if (analytics.hasData) ...[
                const SizedBox(height: AppDimensions.spacingXl),
                _DistributionBar(analytics: analytics),
                const SizedBox(height: AppDimensions.spacingMd),
                _TopStatesRow(analytics: analytics),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Distribution Bar (horizontal stacked) ────────────────────────────────────

class _DistributionBar extends StatelessWidget {
  final EmployeeAnalytics analytics;

  const _DistributionBar({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final totalSec = analytics.totalTrackedTime.inSeconds;
    if (totalSec == 0) return const SizedBox.shrink();

    // Build segments sorted by duration desc
    final segments = analytics.stateDurations.entries.toList()
      ..sort((a, b) => b.value.inSeconds.compareTo(a.value.inSeconds));

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: SizedBox(
        height: AppDimensions.distributionBarHeight,
        child: Row(
          children: segments.map((entry) {
            final fraction = entry.value.inSeconds / totalSec;
            if (fraction < 0.01) return const SizedBox.shrink();
            return Expanded(
              flex: (fraction * 1000).round(),
              child: Container(color: entry.key.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Top States Row (labels below bar) ────────────────────────────────────────

class _TopStatesRow extends StatelessWidget {
  final EmployeeAnalytics analytics;

  const _TopStatesRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final sorted = analytics.stateDurations.entries.toList()
      ..sort((a, b) => b.value.inSeconds.compareTo(a.value.inSeconds));

    final top = sorted.take(3);

    return Row(
      children: top.map((entry) {
        final pct = (analytics.percentageFor(entry.key) * 100).round();
        return Padding(
          padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimensions.stateIndicatorSize,
                height: AppDimensions.stateIndicatorSize,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(
                '${entry.key.label} $pct%',
                style: const TextStyle(
                  fontSize: AppDimensions.fontXs,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── State Dot ────────────────────────────────────────────────────────────────

class _StateDot extends StatelessWidget {
  final ActivityState state;
  const _StateDot(this.state);

  @override
Widget build(BuildContext context) {
    return Semantics(
      label: state.label,
      child: Tooltip(
        message: state.label,
        child: Container(
          width: AppDimensions.stateBreakdownDotSize,
          height: AppDimensions.stateBreakdownDotSize,
          decoration: BoxDecoration(
            color: state.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}



// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatDuration(Duration d) {
  if (d.inHours > 0) {
    final mins = d.inMinutes.remainder(60);
    return '${d.inHours}h ${mins}m';
  }
  return '${d.inMinutes}m';
}

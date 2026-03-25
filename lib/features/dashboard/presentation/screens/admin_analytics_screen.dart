import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _DateChip(
                  label: 'Hoy',
                  selected: dateRange == AnalyticsDateRange.today,
                  onTap: () => ref
                      .read(analyticsDateRangeProvider.notifier)
                      .state = AnalyticsDateRange.today,
                ),
                const SizedBox(width: 8),
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
                  icon: const Icon(Icons.info_outline, size: 20),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $e',
                          style: const TextStyle(color: AppColors.grey500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (analyticsList) {
                if (analyticsList.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(employeeAnalyticsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: analyticsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leyenda de estados',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...ActivityState.values.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
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
      selectedColor: AppColors.primary.withOpacity(0.15),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      emp.name.isNotEmpty
                          ? emp.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
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
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.grey400),
                ],
              ),

              // Distribution bar
              if (analytics.hasData) ...[
                const SizedBox(height: 14),
                _DistributionBar(analytics: analytics),
                const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
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
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.key.label} $pct%',
                style: const TextStyle(
                  fontSize: 10,
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
    return Tooltip(
      message: state.label,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: state.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_outlined,
              size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'Sin datos de analíticas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los datos aparecerán cuando el sistema\nregistre actividad de empleados.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey400,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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

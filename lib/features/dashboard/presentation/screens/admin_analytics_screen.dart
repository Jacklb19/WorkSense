import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/avatar_initials.dart';
import 'package:worksense_app/shared/widgets/activity_bar_row.dart';
import 'package:worksense_app/shared/widgets/confidence_bar.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeAnalyticsProvider);
    final dateRange = ref.watch(analyticsDateRangeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: AppColors.textSecondary,
                      ),
                      Text('Analytics', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(employeeAnalyticsProvider),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: theme.textTheme.labelSmall,
                        side: const BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Date Filter Chips ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  _DateChip(
                    label: 'Today',
                    selected: dateRange == AnalyticsDateRange.today,
                    onTap: () => ref
                        .read(analyticsDateRangeProvider.notifier)
                        .state = AnalyticsDateRange.today,
                  ),
                  const SizedBox(width: 8),
                  _DateChip(
                    label: 'Week',
                    selected: dateRange == AnalyticsDateRange.thisWeek,
                    onTap: () => ref
                        .read(analyticsDateRangeProvider.notifier)
                        .state = AnalyticsDateRange.thisWeek,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Content ──────────────────────────────────
            Expanded(
              child: analyticsAsync.when(
                loading: () => const AppLoadingWidget(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Error: $e',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (analyticsList) {
                  if (analyticsList.isEmpty) {
                    return const _EmptyView();
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.elevated,
                    onRefresh: () async =>
                        ref.invalidate(employeeAnalyticsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, 80,
                      ),
                      itemCount: analyticsList.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
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
      ),
    );
  }
}

// ── Date Chip ────────────────────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : Colors.transparent,
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

// ── Employee Analytics Card ──────────────────────────────────────
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
    final initials = emp.name.length >= 2
        ? emp.name.substring(0, 2).toUpperCase()
        : (emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?');

    return WsCard(
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                AvatarInitials(
                  initials: initials,
                  bg: AppColors.primaryDark,
                  size: 36,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        analytics.hasData
                            ? '${analytics.totalEvents} events · ${_formatDuration(analytics.totalTrackedTime)}'
                            : 'No data recorded',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (analytics.lastState != null)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: analytics.lastState!.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: analytics.lastState!.color
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 18),
              ],
            ),

            // Distribution bar + labels
            if (analytics.hasData) ...[
              const SizedBox(height: AppSpacing.lg),
              _DistributionBar(analytics: analytics),
              const SizedBox(height: AppSpacing.sm),
              _TopStatesRow(analytics: analytics),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Distribution Bar ─────────────────────────────────────────────
class _DistributionBar extends StatelessWidget {
  final EmployeeAnalytics analytics;
  const _DistributionBar({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final totalSec = analytics.totalTrackedTime.inSeconds;
    if (totalSec == 0) return const SizedBox.shrink();

    final segments = analytics.stateDurations.entries.toList()
      ..sort((a, b) => b.value.inSeconds.compareTo(a.value.inSeconds));

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
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

// ── Top States Row ───────────────────────────────────────────────
class _TopStatesRow extends StatelessWidget {
  final EmployeeAnalytics analytics;
  const _TopStatesRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final sorted = analytics.stateDurations.entries.toList()
      ..sort((a, b) => b.value.inSeconds.compareTo(a.value.inSeconds));

    return Row(
      children: sorted.take(3).map((entry) {
        final pct = (analytics.percentageFor(entry.key) * 100).round();
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty View ───────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No analytics data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Data will appear when the system\nrecords employee activity.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────
String _formatDuration(Duration d) {
  if (d.inHours > 0) {
    final mins = d.inMinutes.remainder(60);
    return '${d.inHours}h ${mins}m';
  }
  return '${d.inMinutes}m';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/activity_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/styled/app_glass_card.dart';
import '../../../../shared/widgets/styled/app_stat_chip.dart';
import '../../domain/entities/employee_analytics.dart';
import '../providers/employee_dashboard_provider.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return Scaffold(
      body: analyticsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (analytics) {
          if (analytics == null || !analytics.hasData) {
            return _EmptyHoursView();
          }

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text(
                  'RENDIMIENTO HOY',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: false,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                sliver: SliverToBoxAdapter(
                  child: AppGlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AppStatChip(
                          label: 'ACTIVO',
                          value:
                              _fmtDur(analytics.totalTrackedTime),
                          icon: Icons.timer,
                        ),
                        AppStatChip(
                          label: 'EVENTOS',
                          value: '${analytics.totalEvents}',
                          icon: Icons.bolt,
                        ),
                        AppStatChip(
                          label: 'PROD.',
                          value:
                              '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%',
                          icon: Icons.trending_up,
                          accentColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'DISTRIBUCION DE ACTIVIDAD',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildStateBreakdown(context, analytics),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildStateBreakdown(
    BuildContext context,
    EmployeeAnalytics analytics,
  ) {
    final sorted = ActivityState.values.toList()
      ..sort(
        (a, b) =>
            (analytics.stateDurations[b] ?? Duration.zero)
                .compareTo(analytics.stateDurations[a] ?? Duration.zero),
      );

    return sorted.map((state) {
      final dur = analytics.stateDurations[state] ?? Duration.zero;
      final pct = analytics.percentageFor(state);
      if (dur.inSeconds == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacing24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  state.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                ),
                const Spacer(),
                Text(
                  _fmtDur(dur),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: AppDimensions.progressBarHeightSm,
                backgroundColor: AppColors.surface,
                color: state.color,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}

class _EmptyHoursView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing24),
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_outlined,
                size: AppDimensions.iconEmptyStateLg,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              'SIN DATOS HOY',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              'Las metricas se generaran automaticamente\ncuando inicies tu jornada laboral.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textDisabled,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(employeeTodayAnalyticsProvider),
              icon: const Icon(Icons.refresh, size: AppDimensions.iconXs),
              label: const Text('ACTUALIZAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

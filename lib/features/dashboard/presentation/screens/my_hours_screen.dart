import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/daily_work_summary.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/helpers/hours_formatters.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);
    final summaryAsync = ref.watch(employeeTodaySummaryProvider);
    final summariesAsync = ref.watch(employeeDailySummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.myHours.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        centerTitle: false,
      ),
      body: _buildBody(context, ref, analyticsAsync, summaryAsync, summariesAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue analyticsAsync,
    AsyncValue summaryAsync,
    AsyncValue summariesAsync,
  ) {
    // ── Cargando ──────────────────────────────────────────────
    if (analyticsAsync.isLoading || summaryAsync.isLoading || summariesAsync.isLoading) {
      return AppLoadingWidget(message: context.l10n.calculatingHours);
    }

    // ── Error ─────────────────────────────────────────────────
    if (analyticsAsync.hasError || summaryAsync.hasError || summariesAsync.hasError) {
      return AppErrorWidget(
        message: context.l10n.errorLoadingHoursMsg,
        icon: Icons.schedule_outlined,
        onRetry: () {
          ref.invalidate(employeeTodayAnalyticsProvider);
          ref.invalidate(employeeTodaySummaryProvider);
          ref.invalidate(employeeDailySummariesProvider);
        },
      );
    }

    // ── Datos disponibles ─────────────────────────────────────
    final analytics = analyticsAsync.valueOrNull as EmployeeAnalytics?;
    final summary = summaryAsync.valueOrNull as DailyWorkSummary?;
    final summaries = (summariesAsync.valueOrNull as List<DailyWorkSummary>?) ?? [];

    if ((summary == null) && (analytics == null || !analytics.hasData)) {
      return _EmptyHoursView(onRetry: () {
        ref.invalidate(employeeTodaySummaryProvider);
        ref.invalidate(employeeTodayAnalyticsProvider);
      });
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _SummaryHeroCard(summary: summary),
          ),
        ),
        if (summary != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: _MetricsGrid(summary: summary),
            ),
          ),
        if (summary != null && summary.hasAnomalies)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: _AnomaliesCard(summary: summary),
            ),
          ),
        if (analytics != null && analytics.hasData) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.l10n.activityTodaySection,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: _ActivityOverviewCard(analytics: analytics),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildStateBreakdown(context, analytics),
              ),
            ),
          ),
        ],
        if (summaries.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.l10n.recentSessionsSection,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            sliver: SliverList.separated(
              itemCount: summaries.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _HistoryCard(
                summary: summaries[index],
              ),
            ),
          ),
        ],
        // Extra bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  List<Widget> _buildStateBreakdown(BuildContext context, EmployeeAnalytics analytics) {
    final ac = context.appColors;
    final sorted = ActivityState.values.toList()
      ..sort(
        (a, b) => (analytics.stateDurations[b] ?? Duration.zero)
            .compareTo(analytics.stateDurations[a] ?? Duration.zero),
      );

    return sorted.map((state) {
      final dur = analytics.stateDurations[state] ?? Duration.zero;
      final pct = analytics.percentageFor(state);
      if (dur.inSeconds == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ac.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: state.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.label,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _fmtDur(dur),
                    style: TextStyle(color: ac.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: AppColors.glassBorder,
                  color: state.color,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _fmtDur(Duration d) => HoursFormatters.formatDuration(d);
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyHoursView extends StatelessWidget {
  final VoidCallback? onRetry;
  const _EmptyHoursView({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: ac.card,
                shape: BoxShape.circle,
                border: Border.all(color: ac.divider),
              ),
              child: Icon(
                Icons.access_time_rounded,
                size: 40,
                color: ac.textDisabled,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noHoursYet,
              style: TextStyle(
                color: ac.textDisabled,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.noHoursDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: ac.textDisabled, fontSize: 13, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(context.l10n.refresh),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.textSecondary,
                  side: BorderSide(color: ac.divider),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Summary Hero Card ─────────────────────────────────────────────────────────

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.summary});

  final DailyWorkSummary? summary;

  @override
  Widget build(BuildContext context) {
    final worked = summary?.workedMinutes ?? 0;
    final expected = summary?.expectedMinutes ?? 0;
    final ratio = summary?.completionRatio ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.dailySummary,
            style: const TextStyle(
              color: AppColors.onDark70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.workedLabel(HoursFormatters.formatMinutes(worked)),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            expected > 0
                ? context.l10n.dailyGoalLabel(HoursFormatters.formatMinutes(expected))
                : context.l10n.noShiftGoal,
            style: const TextStyle(color: AppColors.onDark70, height: 1.35),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.onDark24,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroChip(
                label: context.l10n.completion,
                value: '${(ratio * 100).round()}%',
              ),
              const SizedBox(width: 10),
              _HeroChip(
                label: context.l10n.workStatus,
                value: (summary?.hasAnomalies ?? false) ? context.l10n.review : 'OK',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onDark12,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onDark70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metrics Grid ──────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final l10n = context.l10n;
    final tiles = [
      _MetricData(l10n.expected, HoursFormatters.formatMinutes(summary.expectedMinutes), Icons.schedule),
      _MetricData(l10n.breakTime, HoursFormatters.formatMinutes(summary.breakMinutes), Icons.free_breakfast),
      _MetricData(l10n.lateness, HoursFormatters.formatMinutes(summary.lateMinutes), Icons.access_time_filled),
      _MetricData(l10n.extra, HoursFormatters.formatMinutes(summary.extraMinutes), Icons.trending_up),
      _MetricData(l10n.absence, HoursFormatters.formatMinutes(summary.absenceMinutes), Icons.person_off),
      _MetricData(l10n.kpiSessions, '${summary.sessionCount}', Icons.login),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles.map((item) => SizedBox(
            width: tileWidth,
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ac.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ac.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, color: AppColors.primaryLight, size: 20),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.label,
                      style: TextStyle(color: ac.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

// ── Anomalies Card ────────────────────────────────────────────────────────────

class _AnomaliesCard extends StatelessWidget {
  const _AnomaliesCard({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                context.l10n.aspectsToReview,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...summary.anomalies.map(
            (anomaly) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${context.l10n.formatAnomalyLabel(anomaly)}',
                style: TextStyle(color: context.appColors.textSecondary, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Overview Card ────────────────────────────────────────────────────

class _ActivityOverviewCard extends StatelessWidget {
  const _ActivityOverviewCard({required this.analytics});

  final EmployeeAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActivityPill(
            label: context.l10n.active,
            value: HoursFormatters.formatDuration(analytics.totalTrackedTime),
            icon: Icons.timer_outlined,
          ),
          _ActivityPill(
            label: context.l10n.kpiEvents,
            value: '${analytics.totalEvents}',
            icon: Icons.bolt_rounded,
          ),
          _ActivityPill(
            label: context.l10n.productive,
            value:
                '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%',
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final date = summary.workDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.workedOfExpected(
                    HoursFormatters.formatMinutes(summary.workedMinutes),
                    HoursFormatters.formatMinutes(summary.expectedMinutes),
                  ),
                  style: TextStyle(color: ac.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(summary.completionRatio * 100).round()}%',
                style: TextStyle(
                  color: ac.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.hasAnomalies ? context.l10n.review : 'OK',
                style: TextStyle(
                  color: summary.hasAnomalies ? AppColors.warning : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity Pill ─────────────────────────────────────────────────────────────

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/daily_work_summary.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/helpers/hours_formatters.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/styled.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  static const String _screenTitle = 'MIS HORAS';
  static const String _activitySectionTitle = 'ACTIVIDAD DE HOY';
  static const String _historySectionTitle = 'JORNADAS RECIENTES';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);
    final summaryAsync = ref.watch(employeeTodaySummaryProvider);
    final summariesAsync = ref.watch(employeeDailySummariesProvider);

    return Scaffold(
      body: summariesAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (summaries) {
          return summaryAsync.when(
            loading: () => const AppLoadingWidget(),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (summary) {
              return analyticsAsync.when(
                loading: () => const AppLoadingWidget(),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (analytics) {
                  if ((summary == null) && (analytics == null || !analytics.hasData)) {
                    return const _EmptyHoursView();
                  }

                  return CustomScrollView(
                    slivers: [
                      const SliverAppBar(
                        pinned: true,
                        title: Text(
                          _screenTitle,
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        ),
                        centerTitle: false,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacing20, AppDimensions.spacing20, AppDimensions.spacingLg),
                        sliver: SliverToBoxAdapter(
                          child: _SummaryHeroCard(summary: summary),
                        ),
                      ),
                      if (summary != null)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20, vertical: AppDimensions.spacingMd),
                          sliver: SliverToBoxAdapter(
                            child: _MetricsGrid(summary: summary),
                          ),
                        ),
                      if (summary != null && summary.hasAnomalies)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20, vertical: AppDimensions.spacingMd),
                          sliver: SliverToBoxAdapter(
                            child: _AnomaliesCard(summary: summary),
                          ),
                        ),
                      if (analytics != null && analytics.hasData) ...[
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacing18, AppDimensions.spacing20, AppDimensions.spacingMd),
                          sliver: SliverToBoxAdapter(
                            child: SectionLabel(label: _activitySectionTitle),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20, vertical: AppDimensions.spacingMd),
                          sliver: SliverToBoxAdapter(
                            child: _ActivityOverviewCard(analytics: analytics),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacingMd, AppDimensions.spacing20, AppDimensions.spacingXxl),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              _buildStateBreakdown(analytics),
                            ),
                          ),
                        ),
                      ],
                      if (summaries.isNotEmpty) ...[
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacing10, AppDimensions.spacing20, AppDimensions.spacingMd),
                          sliver: SliverToBoxAdapter(
                            child: SectionLabel(label: _historySectionTitle),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacingMd, AppDimensions.spacing20, AppDimensions.spacing28),
                          sliver: SliverList.separated(
                            itemCount: summaries.take(5).length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingLg),
                            itemBuilder: (context, index) => _HistoryCard(
                              summary: summaries[index],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildStateBreakdown(EmployeeAnalytics analytics) {
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
        padding: const EdgeInsets.only(bottom: AppDimensions.spacing18),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: AppDimensions.spacing10,
                    height: AppDimensions.spacing10,
                    decoration: BoxDecoration(
                      color: state.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing10),
                  Expanded(
                    child: Text(
                      state.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _fmtDur(dur),
                    style: const TextStyle(color: AppColors.white70),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Semantics(
                  label: 'Progreso de ${state.label}: ${(pct * 100).round()}%',
                  value: '${(pct * 100).round()}%',
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: AppDimensions.progressBarHeight,
                    backgroundColor: AppColors.white5,
                    color: state.color,
                  ),
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

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.summary});

  final DailyWorkSummary? summary;

  @override
  Widget build(BuildContext context) {
    final worked = summary?.workedMinutes ?? 0;
    final expected = summary?.expectedMinutes ?? 0;
    final ratio = summary?.completionRatio ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardXxl),
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
          const Text(
            'RESUMEN DE LA JORNADA',
            style: TextStyle(
              color: AppColors.white70,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            '${HoursFormatters.formatMinutes(worked)} trabajados',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: AppDimensions.fontDisplaySm,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            expected > 0
                ? 'Meta del dia: ${HoursFormatters.formatMinutes(expected)}'
                : 'Aún no hay una meta de turno configurada',
            style: const TextStyle(color: AppColors.white70, height: 1.35),
          ),
          const SizedBox(height: AppDimensions.spacing18),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusInfinity),
            child: Semantics(
              label: 'Progreso de cumplimiento: ${(ratio * 100).round()}%',
              value: '${(ratio * 100).round()}%',
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: AppDimensions.progressBarHeight,
                backgroundColor: AppColors.white.withValues(alpha: 0.18),
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              _HeroChip(
                label: 'Cumplimiento',
                value: '${(ratio * 100).round()}%',
              ),
              const SizedBox(width: AppDimensions.spacing10),
              _HeroChip(
                label: 'Estado',
                value: (summary?.hasAnomalies ?? false) ? 'Revisar' : 'OK',
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
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacing10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white70,
              fontSize: AppDimensions.fontXs,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
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

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricData('Esperado', HoursFormatters.formatMinutes(summary.expectedMinutes), Icons.schedule),
      _MetricData('Descanso', HoursFormatters.formatMinutes(summary.breakMinutes), Icons.free_breakfast),
      _MetricData('Tardanza', HoursFormatters.formatMinutes(summary.lateMinutes), Icons.access_time_filled),
      _MetricData('Extra', HoursFormatters.formatMinutes(summary.extraMinutes), Icons.trending_up),
      _MetricData('Ausencia', HoursFormatters.formatMinutes(summary.absenceMinutes), Icons.person_off),
      _MetricData('Sesiones', '${summary.sessionCount}', Icons.login),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.spacingLg,
        crossAxisSpacing: AppDimensions.spacingLg,
        childAspectRatio: 1.45,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final item = tiles[index];
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item.icon, color: AppColors.primaryLight, size: AppDimensions.iconMd),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontHeadline,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(color: AppColors.white54, fontSize: AppDimensions.fontCaption),
              ),
            ],
          ),
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

class _AnomaliesCard extends StatelessWidget {
  const _AnomaliesCard({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing18),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.warningSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: AppDimensions.spacing10),
              Text(
                'Aspectos para revisar',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ...summary.anomalies.map(
            (anomaly) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
              child: Text(
                '• ${HoursFormatters.formatAnomalyLabel(anomaly)}',
                style: const TextStyle(color: AppColors.white70, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityOverviewCard extends StatelessWidget {
  const _ActivityOverviewCard({required this.analytics});

  final EmployeeAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardXl),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActivityPill(
            label: 'Activo',
            value: HoursFormatters.formatDuration(analytics.totalTrackedTime),
            icon: Icons.timer_outlined,
          ),
          _ActivityPill(
            label: 'Eventos',
            value: '${analytics.totalEvents}',
            icon: Icons.bolt_rounded,
          ),
          _ActivityPill(
            label: 'Productivo',
            value:
                '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%',
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }

}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.summary});

  final DailyWorkSummary summary;

  @override
  Widget build(BuildContext context) {
    final date = summary.workDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: AppDimensions.iconSm),
          ),
          const SizedBox(width: AppDimensions.spacingXl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  '${HoursFormatters.formatMinutes(summary.workedMinutes)} trabajados de ${HoursFormatters.formatMinutes(summary.expectedMinutes)} esperados',
                  style: const TextStyle(color: AppColors.white60, fontSize: AppDimensions.fontCaption),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(summary.completionRatio * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                summary.hasAnomalies ? 'Revisar' : 'OK',
                style: TextStyle(
                  color: summary.hasAnomalies ? AppColors.warning : AppColors.success,
                  fontSize: AppDimensions.fontCaption,
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
        Icon(icon, size: AppDimensions.iconMd, color: AppColors.primaryLight),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: AppDimensions.fontBodyLg,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white54,
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHoursView extends ConsumerWidget {
  const _EmptyHoursView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Sin datos de horas consolidadas',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white5),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: AppDimensions.iconHuge,
                  color: AppColors.white24,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              const Text(
                'AUN NO HAY HORAS CONSOLIDADAS',
                style: TextStyle(
                  color: AppColors.white30,
                  fontSize: AppDimensions.fontSubtitle,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              const Text(
                'Tu resumen aparecera automaticamente cuando se registren sesiones y actividad durante la jornada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.white38, fontSize: AppDimensions.fontBody, height: 1.5),
              ),
              const SizedBox(height: AppDimensions.spacing28),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(employeeTodaySummaryProvider);
                  ref.invalidate(employeeTodayAnalyticsProvider);
                },
                icon: const Icon(Icons.refresh, size: AppDimensions.iconXs),
                label: const Text('Actualizar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white54,
                  side: const BorderSide(color: AppColors.white12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

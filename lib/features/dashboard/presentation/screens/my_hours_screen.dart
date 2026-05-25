import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/daily_work_summary.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/helpers/hours_formatters.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

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
      appBar: AppBar(
        title: Text(
          _screenTitle,
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
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
    final theme = Theme.of(context);
    if (analyticsAsync.isLoading || summaryAsync.isLoading || summariesAsync.isLoading) {
      return const AppLoadingWidget(message: 'Calculando tus horas...');
    }

    if (analyticsAsync.hasError || summaryAsync.hasError || summariesAsync.hasError) {
      return AppErrorWidget(
        message:
            'No se pudieron cargar tus horas de trabajo.\nVerifica tu conexión e intenta de nuevo.',
        icon: Icons.schedule_outlined,
        onRetry: () {
          ref.invalidate(employeeTodayAnalyticsProvider);
          ref.invalidate(employeeTodaySummaryProvider);
          ref.invalidate(employeeDailySummariesProvider);
        },
      );
    }

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
        AppSliverContentConstrainer(
          width: AppContentWidth.dashboard,
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacing20, bottom: AppDimensions.spacingLg),
            child: _SummaryHeroCard(summary: summary),
          ),
        ),
        if (summary != null)
          AppSliverContentConstrainer(
            width: AppContentWidth.dashboard,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              child: _MetricsGrid(summary: summary),
            ),
          ),
        if (summary != null && summary.hasAnomalies)
          AppSliverContentConstrainer(
            width: AppContentWidth.dashboard,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              child: _AnomaliesCard(summary: summary),
            ),
          ),
        if (analytics != null && analytics.hasData) ...[
          AppSliverContentConstrainer(
            width: AppContentWidth.dashboard,
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingLg, bottom: AppDimensions.spacingMd),
              child: Text(
                _activitySectionTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.appOnSurfaceSecondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          AppSliverContentConstrainer(
            width: AppContentWidth.dashboard,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
              child: _ActivityOverviewCard(analytics: analytics),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingMd, AppDimensions.spacingXxl, AppDimensions.spacingXxl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildStateBreakdown(context, analytics),
              ),
            ),
          ),
        ],
        if (summaries.isNotEmpty) ...[
          AppSliverContentConstrainer(
            width: AppContentWidth.dashboard,
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingLg, bottom: AppDimensions.spacingMd),
              child: Text(
                _historySectionTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.appOnSurfaceSecondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingMd, AppDimensions.spacingXxl, AppDimensions.spacingXxl),
            sliver: SliverList.separated(
              itemCount: summaries.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingLg),
              itemBuilder: (context, index) => _HistoryCard(
                summary: summaries[index],
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacingXxl)),
      ],
    );
  }

  List<Widget> _buildStateBreakdown(BuildContext context, EmployeeAnalytics analytics) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
            border: Border.all(color: context.appGlassBorder),
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
                      style: theme.textTheme.headlineLarge?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    _fmtDur(dur),
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: context.appOnSurface.withValues(alpha: 0.05),
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

class _EmptyHoursView extends StatelessWidget {
  final VoidCallback? onRetry;
  const _EmptyHoursView({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: context.appCard,
                shape: BoxShape.circle,
                border: Border.all(color: context.appGlassBorder),
              ),
              child: Icon(
                Icons.access_time_rounded,
                size: 40,
                color: context.appOnSurfaceDisabled,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              'AÚN NO HAY HORAS CONSOLIDADAS',
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.appOnSurfaceDisabled,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              'Tu resumen aparecerá automáticamente cuando\nse registren sesiones durante la jornada.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurfaceDisabled, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Actualizar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appOnSurfaceSecondary,
                  side: BorderSide(color: context.appGlassBorder),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            expected > 0
                ? 'Meta del día: ${HoursFormatters.formatMinutes(expected)}'
                : 'Aún no hay una meta de turno configurada',
            style: const TextStyle(color: AppColors.white70, height: 1.35),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusInfinity),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.white.withValues(alpha: 0.18),
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              _HeroChip(
                label: 'Cumplimiento',
                value: '${(ratio * 100).round()}%',
              ),
              const SizedBox(width: 10),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: 10),
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
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: context.appOnSurface,
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
    final theme = Theme.of(context);
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
            color: context.appCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: context.appGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item.icon, color: AppColors.primaryLight, size: 20),
              Text(
                item.value,
                style: TextStyle(
                  color: context.appOnSurface,
                  fontSize: AppDimensions.fontHeadline,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
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
                'Aspectos para revisar',
                style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ...summary.anomalies.map(
            (anomaly) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
              child: Text(
                '• ${HoursFormatters.formatAnomalyLabel(anomaly)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary, height: 1.35),
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
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardXl),
        border: Border.all(color: context.appGlassBorder),
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
    final theme = Theme.of(context);
    final date = summary.workDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        border: Border.all(color: context.appGlassBorder),
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
            child: Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: AppDimensions.iconSm),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.headlineLarge?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${HoursFormatters.formatMinutes(summary.workedMinutes)} trabajados'
                  ' de ${HoursFormatters.formatMinutes(summary.expectedMinutes)} esperados',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(summary.completionRatio * 100).round()}%',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.hasAnomalies ? 'Revisar' : 'OK',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: summary.hasAnomalies ? AppColors.warning : AppColors.success,
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          value,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: AppDimensions.fontBodyLg,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: context.appOnSurfaceSecondary,
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
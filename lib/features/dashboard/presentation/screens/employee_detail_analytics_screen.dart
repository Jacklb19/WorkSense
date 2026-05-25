import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../domain/entities/activity_state.dart';
import '../../../../shared/widgets/loading_widget.dart';

import '../../../../shared/widgets/styled/app_content_constrainer.dart';
import '../../../../shared/widgets/styled/app_stat_chip.dart';
import '../../domain/entities/employee_analytics.dart';
import '../providers/admin_analytics_provider.dart';

class EmployeeDetailAnalyticsScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailAnalyticsScreen({
    required this.employeeId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(employeeDetailProvider(employeeId));
    final attendanceAsync =
        ref.watch(employeeAttendanceProvider(employeeId));
    final dateRange = ref.watch(analyticsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.whenOrNull(
          data: (EmployeeAnalytics? a) =>
              Text(a?.employee.displayName ?? 'Empleado'),
        ) ?? const Text('Detalle'),
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (EmployeeAnalytics? analytics) {
          if (analytics == null) {
            return const Center(child: Text('Empleado no encontrado'));
          }

          if (!analytics.hasData) {
            return _EmptyDetailView(name: analytics.employee.displayName);
          }

          return CustomScrollView(
            slivers: [
              AppSliverContentConstrainer(
                width: AppContentWidth.dashboard,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spacingLg,
                    bottom: AppDimensions.spacingXs,
                  ),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Hoy',
                        selected: dateRange == AnalyticsDateRange.today,
                        onTap: () => ref
                            .read(analyticsDateRangeProvider.notifier)
                            .state = AnalyticsDateRange.today,
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      _Chip(
                        label: 'Esta semana',
                        selected: dateRange == AnalyticsDateRange.thisWeek,
                        onTap: () => ref
                            .read(analyticsDateRangeProvider.notifier)
                            .state = AnalyticsDateRange.thisWeek,
                      ),
                    ],
                  ),
                ),
              ),
              AppSliverContentConstrainer(
                width: AppContentWidth.dashboard,
                child: _SummaryHeader(analytics: analytics),
              ),
              AppSliverContentConstrainer(
                width: AppContentWidth.dashboard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingMd,
                  ),
                  child: Text(
                    'Distribucion por estado',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  _buildStateBreakdown(context, analytics),
                ),
              ),
              AppSliverContentConstrainer(
                width: AppContentWidth.dashboard,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spacing24,
                    bottom: AppDimensions.spacingMd,
                  ),
                  child: Text(
                    'Asistencia Diaria (Horas Reales)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              attendanceAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return AppSliverContentConstrainer(
                      width: AppContentWidth.dashboard,
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
child: Text(
                'No hay registros de asistencia en el scanner.',
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
              ),
                      ),
                    );
                  }

                  Duration totalNetTime = Duration.zero;
                  for (final log in logs) {
                    final outTime = log.clockOutTime ?? DateTime.now();
                    totalNetTime += outTime.difference(log.clockInTime);
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingXxl,
                          vertical: AppDimensions.spacingMd,
                        ),
child: Text(
                           'Total horas en oficina: ${_fmtDur(totalNetTime)}',
                           style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                         ),
                      ),
                      ...logs.map((log) {
                        final inStr =
                            DateFormat('HH:mm').format(log.clockInTime);
                        final outStr = log.clockOutTime != null
                            ? DateFormat('HH:mm').format(log.clockOutTime!)
                            : 'En curso';
                        final diff = (log.clockOutTime ?? DateTime.now())
                            .difference(log.clockInTime);
                        return ListTile(
                          leading: Icon(
                            Icons.sensor_door,
                            color: context.appOnSurfaceDisabled,
                          ),
                          title: Text('Entrada: $inStr - Salida: $outStr'),
                          trailing: Text(
                            _fmtDur(diff),
                            style: theme.textTheme.labelLarge?.copyWith(),
                          ),
                        );
                      }),
                    ]),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    SliverToBoxAdapter(child: Text('Error: $e')),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing40),
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
    final statesWithData = <ActivityState, Duration>{};
    for (final state in ActivityState.values) {
      statesWithData[state] =
          analytics.stateDurations[state] ?? Duration.zero;
    }

    final sorted = statesWithData.entries.toList()
      ..sort((a, b) => b.value.inSeconds.compareTo(a.value.inSeconds));

    return sorted.map((entry) {
      final pct = analytics.percentageFor(entry.key);

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXxl,
          vertical: AppDimensions.spacingXs,
        ),
        child: Row(
          children: [
            Container(
              width: AppDimensions.stateBreakdownDotSize,
              height: AppDimensions.stateBreakdownDotSize,
              decoration: BoxDecoration(
                color: entry.key.color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            Expanded(
              flex: 3,
              child: Text(
                entry.key.label,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: context.appSurface,
                  color: entry.key.color,
                  minHeight: AppDimensions.progressBarHeight,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            SizedBox(
              width: AppDimensions.stateBreakdownPercentageWidth,
              child: Text(
                '${(pct * 100).round()}% - ${_fmtDur(entry.value)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.appOnSurfaceSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _SummaryHeader extends StatelessWidget {
  final EmployeeAnalytics analytics;

  const _SummaryHeader({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          side: BorderSide(color: context.appGlassBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      analytics.employee.displayName.isNotEmpty
                          ? analytics.employee.displayName[0].toUpperCase()
                          : '?',
style: theme.textTheme.titleLarge?.copyWith(
                         color: AppColors.primary,
                         fontWeight: FontWeight.bold,
                       ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analytics.employee.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (analytics.lastUpdate != null)
                          Text(
                            'Ultima actividad: ${DateFormat('HH:mm').format(analytics.lastUpdate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.appOnSurfaceSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (analytics.lastState != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingXl,
                        vertical: AppDimensions.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            analytics.lastState!.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusPill,
                        ),
                        border: Border.all(
                          color: analytics.lastState!.color.withAlpha(76),
                        ),
                      ),
                      child: Text(
                        analytics.lastState!.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: analytics.lastState!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AppStatChip(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo total',
                    value: _fmtDur(analytics.totalTrackedTime),
                  ),
                  AppStatChip(
                    icon: Icons.event_note_outlined,
                    label: 'Eventos',
                    value: '${analytics.totalEvents}',
                  ),
                  AppStatChip(
                    icon: Icons.trending_up,
                    label: 'Productividad',
                    value:
                        '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
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

class _EmptyDetailView extends StatelessWidget {
  final String name;
  const _EmptyDetailView({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: AppDimensions.iconEmptyStateLg,
            color: context.appOnSurfaceDisabled,
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'Sin datos para $name',
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.appOnSurfaceSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No se han registrado eventos\nen el periodo seleccionado.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appOnSurfaceDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _fmtDur(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}
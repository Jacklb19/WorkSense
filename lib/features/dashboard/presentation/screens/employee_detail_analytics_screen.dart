import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/loading_indicator.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';

class EmployeeDetailAnalyticsScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailAnalyticsScreen({
    required this.employeeId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(employeeDetailProvider(employeeId));
    final attendanceAsync = ref.watch(employeeAttendanceProvider(employeeId));
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
            return AppEmptyState(icon: Icons.person_search_outlined, title: 'Sin datos para ${analytics.employee.displayName}', subtitle: 'No se han registrado eventos\nen el período seleccionado.');
          }

          return CustomScrollView(
            slivers: [
              // ── Date toggles ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingLg, AppDimensions.spacingXxl, AppDimensions.spacingXs),
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
                        selected:
                            dateRange == AnalyticsDateRange.thisWeek,
                        onTap: () => ref
                            .read(analyticsDateRangeProvider.notifier)
                            .state = AnalyticsDateRange.thisWeek,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary header ────────────────────────────
              SliverToBoxAdapter(
                child: _SummaryHeader(analytics: analytics),
              ),

              // ── State breakdown list ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
                  child: Text(
                    'Distribución por estado',
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

              // ── Attendance list ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacing24, AppDimensions.spacingXxl, AppDimensions.spacingMd),
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
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.spacingXxl),
                        child: Text('No hay registros de asistencia en el escáner.', style: TextStyle(color: AppColors.grey500)),
                      ),
                    );
                  }
                  
                  // Calcular tiempo total neto
                  Duration totalNetTime = Duration.zero;
                  for (final log in logs) {
                    final outTime = log.clockOutTime ?? DateTime.now();
                    totalNetTime += outTime.difference(log.clockInTime);
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
                        child: Text(
                          'Total horas en oficina: ${_fmtDur(totalNetTime)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      ...logs.map((log) {
                        final inStr = DateFormat('HH:mm').format(log.clockInTime);
                        final outStr = log.clockOutTime != null ? DateFormat('HH:mm').format(log.clockOutTime!) : 'En curso';
                        final diff = (log.clockOutTime ?? DateTime.now()).difference(log.clockInTime);
                        return ListTile(
                          leading: const Icon(Icons.sensor_door, color: AppColors.grey400),
                          title: Text('Entrada: $inStr - Salida: $outStr'),
                          trailing: Text(_fmtDur(diff), style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }),
                    ]),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: AppLoadingIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing40)),
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
    // Sort by duration descending, show all states even if 0
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppDimensions.spacingXs),
        child: Row(
          children: [
            // State color dot
            Container(
              width: AppDimensions.stateBreakdownDotSize,
                height: AppDimensions.stateBreakdownDotSize,
              decoration: BoxDecoration(
                color: entry.key.color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),

            // Label
            Expanded(
              flex: 3,
              child: Text(
                entry.key.label,
                style: const TextStyle(fontSize: AppDimensions.fontBody),
              ),
            ),

            // Bar
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.grey200,
                  color: entry.key.color,
                  minHeight: AppDimensions.progressBarHeight,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),

            // Percentage + duration
            SizedBox(
              width: AppDimensions.stateBreakdownPercentageWidth,
              child: Text(
                '${(pct * 100).round()}% · ${_fmtDur(entry.value)}',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSm,
                  color: AppColors.grey600,
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

// ── Summary Header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final EmployeeAnalytics analytics;

  const _SummaryHeader({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            children: [
              // Avatar + name
              Row(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarRadiusMd,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      analytics.employee.displayName.isNotEmpty
                          ? analytics.employee.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimensions.fontHeadlineLg,
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
                            'Última actividad: ${DateFormat('HH:mm').format(analytics.lastUpdate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (analytics.lastState != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: AppDimensions.spacingXs),
                      decoration: BoxDecoration(
                        color: analytics.lastState!.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Text(
                        analytics.lastState!.label,
                        style: TextStyle(
                          color: analytics.lastState!.color,
fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXxl),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo total',
                    value: _fmtDuration(analytics.totalTrackedTime),
                  ),
                  _StatChip(
                    icon: Icons.event_note_outlined,
                    label: 'Eventos',
                    value: '${analytics.totalEvents}',
                  ),
                  _StatChip(
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

  String _fmtDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: AppDimensions.statChipIconSize, color: AppColors.primary),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppDimensions.fontTitle,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontCaption,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }
}

// ── Date Chip ────────────────────────────────────────────────────────────────

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



// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDur(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

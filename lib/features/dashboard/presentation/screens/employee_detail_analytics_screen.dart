import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class EmployeeDetailAnalyticsScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailAnalyticsScreen({
    super.key,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(employeeDetailProvider(employeeId));
    final dateRange = ref.watch(analyticsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.whenOrNull(
          data: (a) => Text(a?.employee.name ?? 'Empleado'),
        ) ?? const Text('Detalle'),
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (analytics) {
          if (analytics == null) {
            return const Center(child: Text('Empleado no encontrado'));
          }

          if (!analytics.hasData) {
            return _EmptyDetailView(name: analytics.employee.name);
          }

          return CustomScrollView(
            slivers: [
              // ── Date toggles ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Hoy',
                        selected: dateRange == AnalyticsDateRange.today,
                        onTap: () => ref
                            .read(analyticsDateRangeProvider.notifier)
                            .state = AnalyticsDateRange.today,
                      ),
                      const SizedBox(width: 8),
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // State color dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: entry.key.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              flex: 3,
              child: Text(
                entry.key.label,
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // Bar
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.grey200,
                  color: entry.key.color,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Percentage + duration
            SizedBox(
              width: 80,
              child: Text(
                '${(pct * 100).round()}% · ${_fmtDur(entry.value)}',
                style: const TextStyle(
                  fontSize: 11,
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
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar + name
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      analytics.employee.name.isNotEmpty
                          ? analytics.employee.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analytics.employee.name,
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
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: analytics.lastState!.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        analytics.lastState!.label,
                        style: TextStyle(
                          color: analytics.lastState!.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

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
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
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

// ── Empty View ───────────────────────────────────────────────────────────────

class _EmptyDetailView extends StatelessWidget {
  final String name;
  const _EmptyDetailView({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search_outlined,
              size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'Sin datos para $name',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se han registrado eventos\nen el período seleccionado.',
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

String _fmtDur(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

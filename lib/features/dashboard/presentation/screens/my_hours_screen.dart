import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Horas de Hoy'),
      ),
      body: analyticsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Error al cargar analíticas', style: TextStyle(color: AppColors.error)),
              TextButton(
                onPressed: () => ref.invalidate(employeeTodayAnalyticsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (analytics) {
          if (analytics == null || !analytics.hasData) {
            return const _EmptyHoursView();
          }

          return CustomScrollView(
            slivers: [
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
                    'Distribución de tiempo',
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

  String _fmtDur(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _EmptyHoursView extends ConsumerWidget {
  const _EmptyHoursView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_outlined,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin registros de hoy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los datos analíticos del entorno \nse recopilarán automáticamente cuando inicies tu labor.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey400,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.invalidate(employeeTodayAnalyticsProvider),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final EmployeeAnalytics analytics;

  const _SummaryHeader({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                    label: 'Eventos hoy',
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

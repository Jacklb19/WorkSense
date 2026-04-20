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
      body: analyticsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (analytics) {
          if (analytics == null || !analytics.hasData) return const _EmptyHoursView();

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text('RENDIMIENTO HOY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                centerTitle: false,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'ACTIVO', value: _fmtDur(analytics.totalTrackedTime), icon: Icons.timer),
                        _StatItem(label: 'EVENTOS', value: '${analytics.totalEvents}', icon: Icons.bolt),
                        _StatItem(label: 'PROD.', value: '${(analytics.percentageFor(ActivityState.trabajando) * 100).round()}%', icon: Icons.trending_up, color: Colors.greenAccent),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text('DISTRIBUCIÓN DE ACTIVIDAD', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(_buildStateBreakdown(context, analytics)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildStateBreakdown(BuildContext context, EmployeeAnalytics analytics) {
    final sorted = ActivityState.values.toList()..sort((a,b) => (analytics.stateDurations[b] ?? Duration.zero).compareTo(analytics.stateDurations[a] ?? Duration.zero));

    return sorted.map((state) {
      final dur = analytics.stateDurations[state] ?? Duration.zero;
      final pct = analytics.percentageFor(state);
      if (dur.inSeconds == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Row(
              children: [
                Text(state.label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const Spacer(),
                Text(_fmtDur(dur), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: state.color,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}

class _EmptyHoursView extends ConsumerWidget {
  const _EmptyHoursView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_outlined, size: 64, color: Colors.white10),
            const SizedBox(height: 24),
            const Text(
              'SIN DATOS HOY',
              style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            const Text(
              'Las métricas se generarán automáticamente\ncuando inicies tu jornada laboral.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white12, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(employeeTodayAnalyticsProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('ACTUALIZAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: const BorderSide(color: Colors.white12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

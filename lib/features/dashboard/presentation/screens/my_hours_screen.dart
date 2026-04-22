import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_shell.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final eventsAsync = ref.watch(recentEventsStreamProvider);

    return EmployeeShell(
      selectedIndex: 1,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text(
                'MI RENDIMIENTO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.invalidate(recentEventsStreamProvider),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            eventsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingWidget(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $e')),
              ),
              data: (allEvents) {
                final userId = currentUser?.user?.id;
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);

                final todayEvents = allEvents.where((e) {
                  final matchesUser =
                      userId == null || e.employeeId == userId;
                  return matchesUser &&
                      e.timestamp.isAfter(todayStart);
                }).toList()
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                if (todayEvents.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(),
                  );
                }

                final durations = _computeDurations(todayEvents);
                final total = durations.values.fold(
                  Duration.zero,
                  (sum, d) => sum + d,
                );
                final workingDur =
                    durations[ActivityState.trabajando] ?? Duration.zero;
                final productivity = total.inSeconds > 0
                    ? workingDur.inSeconds / total.inSeconds
                    : 0.0;

                return SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.timer_rounded,
                              label: 'ACTIVO',
                              value: _fmtDur(total),
                            ),
                            _StatItem(
                              icon: Icons.bolt_rounded,
                              label: 'EVENTOS',
                              value: '${todayEvents.length}',
                            ),
                            _StatItem(
                              icon: Icons.trending_up_rounded,
                              label: 'PROD.',
                              value: '${(productivity * 100).round()}%',
                              color: AppColors.stateWorking,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'DISTRIBUCIÓN DE ACTIVIDAD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ActivityState.values.map((state) {
                        final dur = durations[state] ?? Duration.zero;
                        if (dur.inSeconds == 0) return const SizedBox.shrink();
                        final pct = total.inSeconds > 0
                            ? dur.inSeconds / total.inSeconds
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    state.label.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _fmtDur(dur),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor:
                                      Theme.of(context).hintColor.withOpacity(0.1),
                                  color: state.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<ActivityState, Duration> _computeDurations(List<ActivityEvent> sorted) {
    final durations = <ActivityState, Duration>{};
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i + 1].timestamp.difference(sorted[i].timestamp);
      if (diff.inMinutes < 30) {
        durations[sorted[i].state] =
            (durations[sorted[i].state] ?? Duration.zero) + diff;
      }
    }
    if (sorted.isNotEmpty) {
      durations[sorted.last.state] =
          (durations[sorted.last.state] ?? Duration.zero) +
              const Duration(minutes: 1);
    }
    return durations;
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded,
              size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            'Sin datos hoy',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las métricas se generarán cuando\ntu kiosco registre actividad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

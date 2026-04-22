import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/providers/theme_mode_provider.dart';

final employeeDetailTimeRangeProvider = StateProvider.autoDispose<int>((ref) => 0); // 0: Hoy, 1: Esta semana

class EmployeeDetailAnalyticsScreen extends ConsumerWidget {
  final String employeeId;
  const EmployeeDetailAnalyticsScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final eventsAsync = ref.watch(recentEventsStreamProvider);
    final timeRangeIndex = ref.watch(employeeDetailTimeRangeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final employeeAsync = employeesAsync.whenData(
      (list) => list.where((e) => e.id == employeeId).firstOrNull,
    );

    final employee = employeeAsync.valueOrNull;
    final allEvents = eventsAsync.valueOrNull ?? [];
    
    // Simple filter based on time range (mock logic for demo)
    final now = DateTime.now();
    final filteredEvents = allEvents.where((e) {
      if (e.employeeId != employeeId) return false;
      if (timeRangeIndex == 0) {
        return e.timestamp.year == now.year && e.timestamp.month == now.month && e.timestamp.day == now.day;
      } else {
        return e.timestamp.isAfter(now.subtract(const Duration(days: 7)));
      }
    }).toList();

    final events = filteredEvents..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              employee?.name ?? 'Detalle',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.3),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: themeMode == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
                onPressed: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
                icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              ),
            ],
          ),
          
          if (employeesAsync.isLoading || eventsAsync.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadingWidget(),
            )
          else if (employee == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Empleado no encontrado')),
            )
          else ...[
            // ChoiceChips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Hoy'),
                      selected: timeRangeIndex == 0,
                      onSelected: (val) => ref.read(employeeDetailTimeRangeProvider.notifier).state = 0,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: timeRangeIndex == 0 ? AppColors.primary : Theme.of(context).hintColor,
                        fontWeight: timeRangeIndex == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Esta semana'),
                      selected: timeRangeIndex == 1,
                      onSelected: (val) => ref.read(employeeDetailTimeRangeProvider.notifier).state = 1,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: timeRangeIndex == 1 ? AppColors.primary : Theme.of(context).hintColor,
                        fontWeight: timeRangeIndex == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Summary Header
            SliverToBoxAdapter(
              child: _SummaryHeader(employee: employee, events: events),
            ),

            // State Breakdown
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'DISTRIBUCIÓN POR ESTADO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: _StateBreakdown(events: events),
              ),
            ),

            // Asistencia Diaria
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'ASISTENCIA DIARIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            if (events.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Sin registros de asistencia para este periodo',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reversed = events.reversed.toList();
                      final event = reversed[index];
                      return _AttendanceRow(event: event);
                    },
                    childCount: events.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final Employee employee;
  final List<ActivityEvent> events;

  const _SummaryHeader({required this.employee, required this.events});

  @override
  Widget build(BuildContext context) {
    final lastEvent = events.isEmpty ? null : events.last;
    final total = events.length;

    final durations = _computeDurations(events);
    final totalDur = durations.values.fold(Duration.zero, (sum, d) => sum + d);
    final workingPct = totalDur.inSeconds > 0
        ? (durations[ActivityState.trabajando] ?? Duration.zero).inSeconds / totalDur.inSeconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (lastEvent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lastEvent.state.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lastEvent.state.color.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: lastEvent.state.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lastEvent.state.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: lastEvent.state.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Desconectado',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.timer_rounded,
                label: 'TIEMPO',
                value: _fmtDur(totalDur),
              ),
              _StatChip(
                icon: Icons.bolt_rounded,
                label: 'EVENTOS',
                value: '$total',
              ),
              _StatChip(
                icon: Icons.trending_up_rounded,
                label: 'PRODUCTIVIDAD',
                value: '${(workingPct * 100).round()}%',
                color: AppColors.stateWorking,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<ActivityState, Duration> _computeDurations(List<ActivityEvent> sorted) {
    final durations = <ActivityState, Duration>{};
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i + 1].timestamp.difference(sorted[i].timestamp);
      if (diff.inMinutes < 30) {
        durations[sorted[i].state] = (durations[sorted[i].state] ?? Duration.zero) + diff;
      }
    }
    return durations;
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color ?? AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class _StateBreakdown extends StatelessWidget {
  final List<ActivityEvent> events;
  const _StateBreakdown({required this.events});

  @override
  Widget build(BuildContext context) {
    final durations = _computeDurations(events);
    final totalDur = durations.values.fold(Duration.zero, (sum, d) => sum + d);
    final totalSecs = totalDur.inSeconds;

    if (totalSecs == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Datos insuficientes', style: TextStyle(color: Theme.of(context).hintColor)),
        ),
      );
    }

    return Column(
      children: ActivityState.values.map((state) {
        final dur = durations[state] ?? Duration.zero;
        if (dur.inSeconds == 0) return const SizedBox.shrink();
        
        final pct = dur.inSeconds / totalSecs;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 8),
                  Text(
                    state.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${(pct * 100).round()}% · ${_fmtDur(dur)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).dividerColor,
                  color: state.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<ActivityState, Duration> _computeDurations(List<ActivityEvent> sorted) {
    final durations = <ActivityState, Duration>{};
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = sorted[i + 1].timestamp.difference(sorted[i].timestamp);
      if (diff.inMinutes < 30) {
        durations[sorted[i].state] = (durations[sorted[i].state] ?? Duration.zero) + diff;
      }
    }
    return durations;
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

class _AttendanceRow extends StatelessWidget {
  final ActivityEvent event;
  const _AttendanceRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm a').format(event.timestamp);
    final dateStr = DateFormat('dd MMM yyyy').format(event.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: event.state.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              size: 20,
              color: event.state.color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.state.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

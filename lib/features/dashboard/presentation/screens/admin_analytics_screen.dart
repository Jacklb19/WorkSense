import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/providers/theme_mode_provider.dart';

final analyticsTimeRangeProvider = StateProvider<int>((ref) => 0); // 0: Hoy, 1: Esta semana

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final eventsAsync = ref.watch(recentEventsStreamProvider);
    final timeRangeIndex = ref.watch(analyticsTimeRangeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              'Analíticas',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'Leyenda de estados',
                onPressed: () => _showLegendBottomSheet(context),
              ),
              IconButton(
                tooltip: themeMode == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
                onPressed: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
                icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(employeesProvider);
                  ref.invalidate(recentEventsStreamProvider);
                },
                tooltip: 'Actualizar',
              ),
            ],
          ),
          
          // ChoiceChips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Hoy'),
                    selected: timeRangeIndex == 0,
                    onSelected: (val) => ref.read(analyticsTimeRangeProvider.notifier).state = 0,
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
                    onSelected: (val) => ref.read(analyticsTimeRangeProvider.notifier).state = 1,
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

          employeesAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadingWidget(),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $e')),
            ),
            data: (employees) {
              if (employees.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(),
                );
              }

              final allEvents = eventsAsync.valueOrNull ?? [];
              
              // Simple filter based on time range (mock logic for demo)
              final now = DateTime.now();
              final filteredEvents = allEvents.where((e) {
                if (timeRangeIndex == 0) {
                  return e.timestamp.year == now.year && e.timestamp.month == now.month && e.timestamp.day == now.day;
                } else {
                  return e.timestamp.isAfter(now.subtract(const Duration(days: 7)));
                }
              }).toList();

              final eventsByEmployee = _groupByEmployee(filteredEvents);

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final employee = employees[index];
                      final events = eventsByEmployee[employee.id] ?? [];
                      return _EmployeeAnalyticsCard(
                        employee: employee,
                        events: events,
                        onTap: () => context.push('/analytics/${employee.id}'),
                      );
                    },
                    childCount: employees.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, List<ActivityEvent>> _groupByEmployee(List<ActivityEvent> events) {
    final map = <String, List<ActivityEvent>>{};
    for (final e in events) {
      if (e.employeeId == null) continue;
      map.putIfAbsent(e.employeeId!, () => []).add(e);
    }
    return map;
  }

  void _showLegendBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leyenda de Estados',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...ActivityState.values.map((state) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: state.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeAnalyticsCard extends StatelessWidget {
  final Employee employee;
  final List<ActivityEvent> events;
  final VoidCallback onTap;

  const _EmployeeAnalyticsCard({
    required this.employee,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastEvent = events.isEmpty
        ? null
        : (events..sort((a, b) => b.timestamp.compareTo(a.timestamp))).first;

    final stateCounts = <ActivityState, int>{};
    for (final e in events) {
      stateCounts[e.state] = (stateCounts[e.state] ?? 0) + 1;
    }
    final total = events.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total evento${total != 1 ? 's' : ''} registrado${total != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (lastEvent != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: lastEvent.state.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: lastEvent.state.color.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 16),
                // Stacked bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: ActivityState.values.map((state) {
                        final count = stateCounts[state] ?? 0;
                        final flex = count;
                        if (flex == 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: flex,
                          child: Container(color: state.color),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Top 3 states
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: (stateCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                      .take(3)
                      .map<Widget>((entry) {
                        final pct = total > 0 ? (entry.value / total * 100).round() : 0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: entry.key.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key.label} $pct%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        );
                      })
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
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
          Icon(Icons.bar_chart_rounded, size: 72, color: Theme.of(context).hintColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Sin información analítica',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no hay datos suficientes para mostrar.',
            style: TextStyle(color: Theme.of(context).hintColor),
          )
        ],
      ),
    );
  }
}

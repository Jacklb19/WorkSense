import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_shell.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final eventsAsync = ref.watch(recentEventsStreamProvider);

    return EmployeeShell(
      selectedIndex: 0,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text(
                'MI ACTIVIDAD',
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
                child: _ErrorView(message: e.toString()),
              ),
              data: (allEvents) {
                final userId = currentUser?.user?.id;
                final events = userId != null
                    ? allEvents
                        .where((e) => e.employeeId == userId)
                        .toList()
                    : allEvents;

                if (events.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ActivityEventCard(event: events[index]),
                      childCount: events.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  final ActivityEvent event;
  const _ActivityEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(event.timestamp);
    final dateStr = DateFormat('dd/MM/yy').format(event.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.state.color.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: event.state.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.state.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.workstationId.length > 8
                      ? 'Estación: ...${event.workstationId.substring(event.workstationId.length - 6)}'
                      : 'Estación: ${event.workstationId}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ],
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
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            'Sin registros recientes',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu actividad aparecerá aquí\ncuando el kiosco te detecte.',
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

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

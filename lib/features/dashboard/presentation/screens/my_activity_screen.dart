import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(employeeRecentEventsProvider);

    return Scaffold(
      body: recentEventsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (events) {
          if (events.isEmpty) return const _EmptyActivityView();

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text('REGISTRO DE ACTIVIDAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                centerTitle: false,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ActivityEventTile(event: events[index]),
                    childCount: events.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyActivityView extends StatelessWidget {
  const _EmptyActivityView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.white10),
          SizedBox(height: 16),
          Text('SIN REGISTROS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          SizedBox(height: 8),
          Text('La actividad reciente aparecerá en este log.', style: TextStyle(color: Colors.white12, fontSize: 12)),
        ],
      ),
    );
  }
}

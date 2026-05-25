import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(employeeRecentEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'REGISTRO DE ACTIVIDAD',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: false,
      ),
      body: recentEventsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando actividad...'),
        error: (error, _) => AppErrorWidget(
          message:
              'No se pudo cargar tu historial de actividad.\nVerifica tu conexión e intenta de nuevo.',
          icon: Icons.history_toggle_off,
          onRetry: () => ref.invalidate(employeeRecentEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) return const _EmptyActivityView();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) => ActivityEventTile(event: events[index]),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 40,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SIN REGISTROS AÚN',
              style: TextStyle(
                color: Colors.white30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu actividad reciente aparecerá aquí\ncuando comiences a trabajar.',
              style: TextStyle(color: Colors.white24, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

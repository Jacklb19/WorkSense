import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(employeeRecentEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Actividad Reciente'),
      ),
      body: recentEventsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Error al cargar la actividad', style: TextStyle(color: AppColors.error)),
              TextButton(
                onPressed: () => ref.invalidate(employeeRecentEventsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay actividad registrada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.grey500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si ya fuiste monitorizado, los eventos aparecerán aquí.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey400,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(employeeRecentEventsProvider),
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) => ActivityEventTile(
              event: events[index],
            ),
          );
        },
      ),
    );
  }
}

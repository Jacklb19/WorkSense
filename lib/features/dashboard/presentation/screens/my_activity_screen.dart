import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';

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
          if (events.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_toggle_off,
              title: 'SIN REGISTROS',
              subtitle: 'La actividad reciente aparecera en este log.',
              iconColor: AppColors.textDisabled,
            );
          }

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

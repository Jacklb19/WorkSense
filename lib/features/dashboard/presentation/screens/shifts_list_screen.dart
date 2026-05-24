import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class ShiftsListScreen extends ConsumerWidget {
  const ShiftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios Laborales'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(shiftsProvider),
        child: shiftsAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (e, trace) => Center(child: Text('Error: $e')),
          data: (shifts) {
            if (shifts.isEmpty) {
              return const _EmptyShiftsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spacingXxl),
              itemCount: shifts.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingLg),
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final String startStr = '${shift.startTime.hour}:${shift.startTime.minute.toString().padLeft(2, '0')}';
                final String endStr = '${shift.endTime.hour}:${shift.endTime.minute.toString().padLeft(2, '0')}';
                
                return Card(
                  elevation: AppDimensions.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacingLg),
                    leading: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingLg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                      ),
                      child: const Icon(Icons.schedule, color: AppColors.primary),
                    ),
                    title: Text(
                      shift.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.spacingXs),
                      child: Text(
                        '$startStr - $endStr',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
                    onTap: () {
                      // TODO: Implementar edicion
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.shiftNew),
        icon: const Icon(Icons.add),
        label: const Text('NUEVO TURNO'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _EmptyShiftsView extends StatelessWidget {
  const _EmptyShiftsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: AppDimensions.iconEmptyStateLg, color: AppColors.grey300),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'No hay turnos registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Crea tu primer horario laboral \npara asignarlo a tus empleados.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

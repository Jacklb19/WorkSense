import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/shared/widgets/async_value_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

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
        child: AsyncValueWidget(
          value: shiftsAsync,
          builder: (shifts) {
            if (shifts.isEmpty) {
              return const _EmptyShiftsView();
            }

            return AppContentConstrainer(
              width: AppContentWidth.list,
              child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spacingXxl),
              itemCount: shifts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spacingLg),
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final String startStr = '${shift.startTime.hour}:${shift.startTime.minute.toString().padLeft(2, '0')}';
                final String endStr = '${shift.endTime.hour}:${shift.endTime.minute.toString().padLeft(2, '0')}';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusRound),
                    side: BorderSide(color: context.appGlassBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing24,
                      vertical: AppDimensions.spacingLg,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingLg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                      ),
                    ),
                    title: Text(
                      shift.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                        top: AppDimensions.spacingXs,
                      ),
                      child: Text(
                        '$startStr - $endStr',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.appOnSurfaceSecondary,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          tooltip: 'Editar',
                          onPressed: () => context.push(
                            AppRoutes.shiftEdit.replaceFirst(':shiftId', shift.id),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmDelete(context, ref, shift),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Shift shift) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar turno'),
        content: Text('¿Eliminar "${shift.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deleteShiftUseCaseProvider).call(shift.id);
      ref.invalidate(shiftsProvider);
    }
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
          Icon(Icons.event_busy, size: 64, color: context.appOnSurfaceDisabled),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'No hay turnos registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.appOnSurfaceSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Crea tu primer horario laboral \npara asignarlo a tus empleados.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceDisabled),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
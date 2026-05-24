import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/state_badge_widget.dart';

class EmployeeDashboardCard extends ConsumerWidget {
  final Employee employee;

  const EmployeeDashboardCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shiftsAsync = ref.watch(shiftsProvider);
    final attendanceAsync = ref.watch(employeeAttendanceProvider(employee.id));

    // Encontrar shift actual de la memoria si está cargado
    final shifts = shiftsAsync.valueOrNull ?? [];
    final currentShift = shifts.where((s) => s.id == employee.shiftId).firstOrNull;

    // Obtener analíticas reales
    final analyticsAsync = ref.watch(employeeDetailProvider(employee.id));

    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.analyticsDetail.replaceFirst(':employeeId', employee.id));
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Avatar circular + Nombre
              Row(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarRadiusMd,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      employee.displayName.isNotEmpty
                          ? employee.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontHeadline, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXxl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Badge de ID (simulado) o cargo
                        const SizedBox(height: AppDimensions.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm, vertical: AppDimensions.spacingXxs),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            'EMP-${employee.id.substring(0, 4).toUpperCase()}',
                            style: const TextStyle(fontSize: AppDimensions.fontXs, color: AppColors.primary, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Estado del Turno Asignado
              Row(
                children: [
                  const Icon(Icons.schedule, size: AppDimensions.iconXs, color: AppColors.grey400),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Text(
                      currentShift != null 
                        ? '${currentShift.name} (${currentShift.startTime.hour}:${currentShift.startTime.minute.toString().padLeft(2, '0')})'
                        : 'Sin turno asignado',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.spacingMd),

              // Analíticas en tiempo real
              analyticsAsync.when(
                data: (analytics) {
                  if (analytics != null && analytics.hasData) {
                    return Row(
                      children: [
                        const Icon(Icons.bar_chart, size: AppDimensions.iconXs, color: AppColors.grey400),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StateBadgeWidget(state: analytics.lastState!),
                              Text(
                                '${analytics.totalTrackedTime.inMinutes}min activos',
                                style: const TextStyle(fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.bold, color: AppColors.primary),
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return attendanceAsync.when(
                    data: (logs) {
                      if (logs.isNotEmpty) {
                        final latest = logs.first;
                        final timeFormat = DateFormat('HH:mm');
                        final attendanceLabel = latest.clockOutTime == null
                            ? 'En turno desde ${timeFormat.format(latest.clockInTime)}'
                            : 'Último acceso ${timeFormat.format(latest.clockInTime)} - ${timeFormat.format(latest.clockOutTime!)}';
                        return Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: AppDimensions.iconXs, color: AppColors.grey400),
                            const SizedBox(width: AppDimensions.spacingMd),
                            Expanded(
                              child: Text(
                                attendanceLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Icon(Icons.bar_chart, size: AppDimensions.iconXs, color: AppColors.grey400),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Text(
                            'Sin datos de actividad hoy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        height: AppDimensions.progressIndicatorSize,
                        width: AppDimensions.progressIndicatorSize,
                        child: CircularProgressIndicator(strokeWidth: AppDimensions.progressStrokeWidth),
                      ),
                    ),
                    error: (_, __) => Row(
                      children: [
                        const Icon(Icons.bar_chart, size: AppDimensions.iconXs, color: AppColors.grey400),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Text(
                          'Sin datos de actividad hoy',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: SizedBox(height: AppDimensions.progressIndicatorSize, width: AppDimensions.progressIndicatorSize, child: CircularProgressIndicator(strokeWidth: AppDimensions.progressStrokeWidth))),
                error: (e, _) => const Text('Error al cargar', style: TextStyle(color: AppColors.error, fontSize: AppDimensions.fontCaption)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
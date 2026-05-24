import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.analyticsDetail.replaceFirst(':employeeId', employee.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Avatar circular + Nombre
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      employee.displayName.isNotEmpty
                          ? employee.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EMP-${employee.id.substring(0, 4).toUpperCase()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.primary, letterSpacing: 1),
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
                  const Icon(Icons.schedule, size: 16, color: AppColors.grey400),
                  const SizedBox(width: 8),
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
              
              const SizedBox(height: 8),

              // Analíticas en tiempo real
              analyticsAsync.when(
                data: (analytics) {
                  if (analytics != null && analytics.hasData) {
                    return Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 16, color: AppColors.grey400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StateBadgeWidget(state: analytics.lastState!),
                              Text(
                                '${analytics.totalTrackedTime.inMinutes}min activos',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                            const Icon(Icons.badge_outlined, size: 16, color: AppColors.grey400),
                            const SizedBox(width: 8),
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
                          const Icon(Icons.bar_chart, size: 16, color: AppColors.grey400),
                          const SizedBox(width: 8),
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
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 16, color: AppColors.grey400),
                        const SizedBox(width: 8),
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
                loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => const Text('Error al cargar', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

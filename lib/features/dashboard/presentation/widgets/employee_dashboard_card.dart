import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';

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

    // Encontrar shift actual de la memoria si está cargado
    final shifts = shiftsAsync.valueOrNull ?? [];
    final currentShift = shifts.where((s) => s.id == employee.shiftId).firstOrNull;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
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
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
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
              // Estado Asistencia Rápida (Simulado hasta el provider detallado)
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 16, color: AppColors.grey400),
                  const SizedBox(width: 8),
                  Text(
                    'Ver Reporte Ficha',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

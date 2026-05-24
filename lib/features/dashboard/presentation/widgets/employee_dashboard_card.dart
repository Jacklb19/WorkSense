import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/employee.dart';
import '../../../camera_monitor/presentation/widgets/state_badge_widget.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/providers/shifts_provider.dart';

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
    final attendanceAsync =
        ref.watch(employeeAttendanceProvider(employee.id));

    final shifts = shiftsAsync.valueOrNull ?? [];
    final currentShift =
        shifts.where((s) => s.id == employee.shiftId).firstOrNull;

    final analyticsAsync = ref.watch(employeeDetailProvider(employee.id));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: BorderSide(
          color: AppColors.primary.withAlpha(40),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            AppRoutes.analyticsDetail
                .replaceFirst(':employeeId', employee.id),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardInnerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: AppDimensions.avatarMd / 2,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXxl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSm,
                            vertical: AppDimensions.spacingXxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            'EMP-${employee.id.substring(0, 4).toUpperCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: AppDimensions.iconXs,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Text(
                      currentShift != null
                          ? '${currentShift.name} (${currentShift.startTime.hour}:${currentShift.startTime.minute.toString().padLeft(2, '0')})'
                          : 'Sin turno asignado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              analyticsAsync.when(
                data: (analytics) {
                  if (analytics != null && analytics.hasData) {
                    return Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          size: AppDimensions.iconXs,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StateBadgeWidget(state: analytics.lastState!),
                              Text(
                                '${analytics.totalTrackedTime.inMinutes}min activos',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
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
                            : 'Ultimo acceso ${timeFormat.format(latest.clockInTime)} - ${timeFormat.format(latest.clockOutTime!)}';
                        return Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: AppDimensions.iconXs,
                              color: AppColors.textDisabled,
                            ),
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
                          const Icon(
                            Icons.bar_chart,
                            size: AppDimensions.iconXs,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Text(
                            'Sin datos de actividad hoy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        height: AppDimensions.progressIndicatorSize,
                        width: AppDimensions.progressIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (_, __) => Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          size: AppDimensions.iconXs,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Text(
                          'Sin datos de actividad hoy',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    height: AppDimensions.progressIndicatorSize,
                    width: AppDimensions.progressIndicatorSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Error al cargar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: AppDimensions.animEntrance,
          curve: Curves.easeOutCubic,
        );
  }
}

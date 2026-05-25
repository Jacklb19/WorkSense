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

  // Color del avatar basado en el primer char del nombre
  Color _avatarColor() {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
    ];
    final idx = employee.displayName.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final attendanceAsync = ref.watch(employeeAttendanceProvider(employee.id));
    final analyticsAsync = ref.watch(employeeDetailProvider(employee.id));

    final shifts = shiftsAsync.valueOrNull ?? [];
    final currentShift =
        shifts.where((s) => s.id == employee.shiftId).firstOrNull;

    final accentColor = _avatarColor();

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.analyticsDetail.replaceFirst(':employeeId', employee.id),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dividerDark),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(
              AppRoutes.analyticsDetail
                  .replaceFirst(':employeeId', employee.id),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      // Avatar con glow
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            employee.displayName.isNotEmpty
                                ? employee.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'EMP-${employee.id.substring(0, 4).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.textDisabledDark,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Shift ────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.textDisabledDark),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          currentShift != null
                              ? '${currentShift.name} · ${currentShift.startTime.hour}:${currentShift.startTime.minute.toString().padLeft(2, '0')}'
                              : 'Sin turno asignado',
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Analytics / Attendance ────────────────────────────
                  analyticsAsync.when(
                    data: (analytics) {
                      if (analytics != null && analytics.hasData) {
                        return Row(
                          children: [
                            const Icon(Icons.show_chart_rounded,
                                size: 13, color: AppColors.textDisabledDark),
                            const SizedBox(width: 5),
                            StateBadgeWidget(state: analytics.lastState!),
                            const Spacer(),
                            Text(
                              '${analytics.totalTrackedTime.inMinutes}m',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
                            final label = latest.clockOutTime == null
                                ? 'En turno · ${timeFormat.format(latest.clockInTime)}'
                                : '${timeFormat.format(latest.clockInTime)} — ${timeFormat.format(latest.clockOutTime!)}';
                            return Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    size: 13,
                                    color: AppColors.textDisabledDark),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const _NoDataRow();
                        },
                        loading: () => const SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.dividerDark,
                          ),
                        ),
                        error: (_, __) => const _NoDataRow(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 16,
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.dividerDark,
                      ),
                    ),
                    error: (_, __) => const _NoDataRow(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoDataRow extends StatelessWidget {
  const _NoDataRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.show_chart_rounded, size: 13, color: AppColors.textDisabledDark),
        SizedBox(width: 5),
        Text(
          'Sin actividad registrada hoy',
          style: TextStyle(color: AppColors.textDisabledDark, fontSize: 11),
        ),
      ],
    );
  }
}

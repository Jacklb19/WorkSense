import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/theme/app_animations.dart';
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
    final cardColor = context.appCard;
    final onSurface = context.appOnSurface;
    final onSurfaceSecondary = context.appOnSurfaceSecondary;
    final glassBorder = context.appGlassBorder;

    return Semantics(
      button: true,
      label: 'Empleado ${employee.displayName}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.analyticsDetail.replaceFirst(':employeeId', employee.id),
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
              border: Border.all(color: glassBorder),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.06),
                  blurRadius: AppDimensions.spacingXxl,
                  offset: const Offset(0, AppDimensions.spacingMd),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingXxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: AppDimensions.iconContainerSm,
                        height: AppDimensions.iconContainerSm,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: AppDimensions.spacingXxl,
                              offset: const Offset(0, AppDimensions.spacingMd),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            employee.displayName.isNotEmpty
                                ? employee.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppDimensions.fontTitleLg,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppDimensions.spacingMd),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.displayName,
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: AppDimensions.fontBodyMd,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimensions.spacingXxs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingMd, vertical: AppDimensions.spacingXxs / 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                              ),
                              child: Text(
                                'EMP-${employee.id.substring(0, 4).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontXs,
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: AppDimensions.fontCaption,
                        color: context.appOnSurfaceSecondary,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Shift ────────────────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: AppDimensions.fontCaption, color: onSurfaceSecondary),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Expanded(
                        child: Text(
                          currentShift != null
                              ? '${currentShift.name} · ${currentShift.startTime.hour}:${currentShift.startTime.minute.toString().padLeft(2, '0')}'
                              : AppStrings.noShiftAssigned,
                          style: TextStyle(
                            color: onSurfaceSecondary,
                            fontSize: AppDimensions.fontSm,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingMd),

                  // ── Analytics / Attendance ────────────────────────────
                  analyticsAsync.when(
                    data: (analytics) {
                      if (analytics != null && analytics.hasData) {
                        return Row(
                          children: [
                            Icon(Icons.show_chart_rounded,
                                size: AppDimensions.fontCaption, color: onSurfaceSecondary),
                            const SizedBox(width: AppDimensions.spacingXs),
                            StateBadgeWidget(state: analytics.lastState!),
                            const Spacer(),
                            Text(
                              '${analytics.totalTrackedTime.inMinutes}m',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSm,
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
                                Icon(Icons.badge_outlined,
                                    size: AppDimensions.fontCaption,
                                    color: onSurfaceSecondary),
                                const SizedBox(width: AppDimensions.spacingXs),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: AppDimensions.fontSm,
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
                          height: AppDimensions.spacingXxl,
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        error: (_, __) => const _NoDataRow(),
                      );
                    },
                    loading: () => const SizedBox(
                      height: AppDimensions.spacingXxl,
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
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
    ).animate().fadeIn(
          duration: AppAnimations.entrance,
          curve: AppAnimations.entranceCurve,
        );
  }
}

class _NoDataRow extends StatelessWidget {
  const _NoDataRow();

  @override
  Widget build(BuildContext context) {
    final onSurfaceSecondary = context.appOnSurfaceSecondary;
    return Row(
      children: [
        Icon(Icons.show_chart_rounded, size: AppDimensions.fontCaption, color: onSurfaceSecondary),
        SizedBox(width: AppDimensions.spacingXs),
        Text(
          AppStrings.noRegisteredToday,
          style: TextStyle(color: onSurfaceSecondary, fontSize: AppDimensions.fontSm),
        ),
      ],
    );
  }
}

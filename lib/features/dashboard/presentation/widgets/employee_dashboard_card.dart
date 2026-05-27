import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
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

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _timeFmt = DateFormat('HH:mm');

  // ✅ Getter puro — no cambia entre rebuilds; evita recomputar en cada build().
  static const _avatarColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.secondary,
    AppColors.success,
    AppColors.warning,
  ];

  Color get _accentColor {
    if (employee.displayName.isEmpty) return AppColors.primary;
    return _avatarColors[employee.displayName.codeUnitAt(0) % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final attendanceAsync = ref.watch(employeeAttendanceProvider(employee.id));
    final analyticsAsync = ref.watch(employeeDetailProvider(employee.id));

    final shifts = shiftsAsync.valueOrNull ?? [];
    final currentShift =
        shifts.where((s) => s.id == employee.shiftId).firstOrNull;

    // ✅ Getter puro, no closure ni método de instancia llamado dentro de build.
    final accentColor = _accentColor;

    // ✅ GestureDetector eliminado — Material+InkWell lo cubre completamente,
    //    añade ripple y semántica de botón sin doble invocación del onTap.
    final ac = context.appColors;
    final l10n = context.l10n;
    return Material(
      color: ac.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.analyticsDetail.replaceFirst(':employeeId', employee.id),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ac.divider),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                              style: TextStyle(
                                color: ac.textPrimary,
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
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: ac.textDisabled,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Shift ────────────────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: ac.textDisabled),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          currentShift != null
                              ? '${currentShift.name} · ${currentShift.startTime.hour}:${currentShift.startTime.minute.toString().padLeft(2, '0')}'
                              : l10n.noShiftAssigned,
                          style: TextStyle(
                            color: ac.textSecondary,
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
                            Icon(Icons.show_chart_rounded,
                                size: 13, color: ac.textDisabled),
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
                            final label = latest.clockOutTime == null
                                ? 'En turno · ${_timeFmt.format(latest.clockInTime)}'
                                : '${_timeFmt.format(latest.clockInTime)} — ${_timeFmt.format(latest.clockOutTime!)}';
                            return Row(
                              children: [
                                Icon(Icons.badge_outlined,
                                    size: 13,
                                    color: ac.textDisabled),
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
                        loading: () => SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                            backgroundColor: ac.divider,
                          ),
                        ),
                        error: (_, __) => const _NoDataRow(),
                      );
                    },
                    loading: () => SizedBox(
                      height: 16,
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: ac.divider,
                      ),
                    ),
                    error: (_, __) => const _NoDataRow(),
                  ),
                ],
              ),
            ),
        ),
      ),
    ).animate().fadeIn(
          duration: AppDimensions.animEntrance,
          curve: Curves.easeOutCubic,
        );
  }
}

class _NoDataRow extends StatelessWidget {
  const _NoDataRow();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Icon(Icons.show_chart_rounded, size: 13, color: ac.textDisabled),
        const SizedBox(width: 5),
        Text(
          context.l10n.noActivityToday,
          style: TextStyle(color: ac.textDisabled, fontSize: 11),
        ),
      ],
    );
  }
}

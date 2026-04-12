import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/avatar_initials.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);
    final userState = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: AppRadius.pillAll,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _formatDate(now),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Good morning, Admin',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                workstationsAsync.when(
                  data: (ws) => Text(
                    '${_weekdayName(now.weekday)}, ${_formatDate(now)} · ${ws.length} active workstations',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────
          Expanded(
            child: workstationsAsync.when(
              loading: () => const AppLoadingWidget(),
              error: (error, _) => _ErrorView(error: error.toString()),
              data: (workstations) {
                if (workstations.isEmpty) {
                  return _EmptyView(
                    onStartKiosk: () => context.push('/kiosk/default'),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.elevated,
                  onRefresh: () async {
                    ref.invalidate(workstationsStreamProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      // ── KPI Grid ───────────────────────────
                      _KpiGrid(workstationCount: workstations.length),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Active Employees ───────────────────
                      Text(
                        'Active employees',
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      WsCard(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            ...workstations.take(5).map((ws) {
                              final name = ws.assignedEmployeeId ?? 'Unassigned';
                              final initials = name.length >= 2
                                  ? name.substring(0, 2).toUpperCase()
                                  : '??';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.borderColor,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AvatarInitials(
                                      initials: initials,
                                      bg: AppColors.primaryDark,
                                      size: 32,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ws.name,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            ws.assignedEmployeeId != null
                                                ? 'Assigned'
                                                : 'Unoccupied',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: ws.assignedEmployeeId != null
                                            ? AppColors.stateWorking
                                            : AppColors.stateAbsent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (workstations.length > 5)
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'View all ${workstations.length} employees',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final items = workstationsAsync.valueOrNull ?? [];
          final firstId = items.isNotEmpty ? items.first.id : 'default';
          context.push('/kiosk/$firstId');
        },
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text(AppStrings.startKiosk),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _weekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final int workstationCount;
  const _KpiGrid({required this.workstationCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _KpiCard(
          value: '$workstationCount',
          subtitle: '/ $workstationCount total',
          label: 'Active',
          dotColor: AppColors.stateWorking,
        ),
        _KpiCard(
          value: '0',
          subtitle: 'warnings',
          label: 'Idle',
          dotColor: AppColors.stateInactive,
          valueColor: AppColors.stateInactive,
        ),
        _KpiCard(
          value: '0.0h',
          subtitle: 'avg today',
          label: 'Avg Hours',
        ),
        _KpiCard(
          value: '—',
          subtitle: 'attendance',
          label: 'On Time',
          valueColor: AppColors.stateWorking,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String subtitle;
  final String label;
  final Color? dotColor;
  final Color? valueColor;

  const _KpiCard({
    required this.value,
    required this.subtitle,
    required this.label,
    this.dotColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WsCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty View ──────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final VoidCallback onStartKiosk;
  const _EmptyView({required this.onStartKiosk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.noWorkstationsRegistered,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.noWorkstationsDescription,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: onStartKiosk,
              icon: const Icon(Icons.play_arrow),
              label: const Text(AppStrings.startKioskMode),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ──────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.errorLoadingData,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/status_badge.dart';
import 'package:worksense_app/shared/widgets/activity_bar_row.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email ?? 'Employee';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.elevated,
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────
              Text(
                'My Dashboard',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Good morning, $userEmail',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Section 1: Assigned Workstation ─────────
              const _AssignedWorkstationSection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Section 2: Personal Productivity ────────
              Text(
                'MY PRODUCTIVITY TODAY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PersonalProductivitySection(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Quick Access ────────────────────────────
              Text(
                'Quick access',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      emoji: '🕐',
                      label: 'My Hours',
                      onTap: () => context.push(AppRoutes.myHours),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAccessCard(
                      emoji: '📊',
                      label: 'Activity',
                      onTap: () => context.push(AppRoutes.myActivity),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAccessCard(
                      emoji: '👤',
                      label: 'Profile',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Section 3: Recent Activity ──────────────
              Text(
                'RECENT ACTIVITY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _RecentActivitySection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Access Card ─────────────────────────────────────────────
class _QuickAccessCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WsCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assigned Workstation Section ─────────────────────────────────
class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync = ref.watch(employeeAssignedWorkstationProvider);
    final theme = Theme.of(context);

    return workstationAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.verifyingWorkstation),
      error: (e, _) => WsCard(
        type: CardType.surface,
        child: Text(
          AppStrings.errorLoadingWorkstation,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      ),
      data: (workstation) {
        if (workstation == null) {
          return WsCard(
            child: Row(
              children: [
                Icon(Icons.desktop_access_disabled,
                    color: AppColors.textMuted, size: 32),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.noAssignedWorkstation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.noAssignedWorkstationDescription,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return _WorkstationStatusCard(workstation: workstation);
      },
    );
  }
}

class _WorkstationStatusCard extends StatelessWidget {
  final WorkstationRecord workstation;
  const _WorkstationStatusCard({required this.workstation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WsCard(
      type: CardType.accent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(state: ActivityState.trabajando),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  workstation.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.monitoringAssigned,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.stateWorking,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.stateWorking,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Personal Productivity Section ───────────────────────────────
class _PersonalProductivitySection extends ConsumerWidget {
  const _PersonalProductivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);
    final theme = Theme.of(context);

    return analyticsAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.calculatingTime),
      error: (e, _) => Text(
        AppStrings.couldNotLoadMetrics,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
      ),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return WsCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  AppStrings.noActivityToday,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          );
        }

        final totalDuration = analytics.totalTrackedTime;
        final workTime = analytics.stateDurations[ActivityState.trabajando] ?? Duration.zero;
        final idleTime = analytics.stateDurations[ActivityState.inactivo] ?? Duration.zero;
        final distractTime = analytics.stateDurations[ActivityState.distraido] ?? Duration.zero;
        final fatigueTime = analytics.stateDurations[ActivityState.fatiga] ?? Duration.zero;

        double pct(Duration d) =>
            totalDuration.inSeconds > 0
                ? d.inSeconds / totalDuration.inSeconds
                : 0.0;

        return WsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${_formatDuration(totalDuration)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ActivityBarRow(
                label: 'Working',
                color: AppColors.stateWorking,
                percent: pct(workTime),
              ),
              ActivityBarRow(
                label: 'Idle',
                color: AppColors.stateInactive,
                percent: pct(idleTime),
              ),
              ActivityBarRow(
                label: 'Distracted',
                color: AppColors.stateDistracted,
                percent: pct(distractTime),
              ),
              ActivityBarRow(
                label: 'Fatigue',
                color: AppColors.stateFatigue,
                percent: pct(fatigueTime),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
}

// ── Recent Activity Feed ────────────────────────────────────────
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(employeeRecentEventsProvider);
    final theme = Theme.of(context);

    return eventsAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => Text(
        AppStrings.errorLoadingHistory,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                AppStrings.noRecentEvents,
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        }

        return WsCard(
          padding: const EdgeInsets.all(0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.borderColor,
            ),
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: event.state.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: event.state.color.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.state.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatTime(event.timestamp),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (event.identificationMethod != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    final sec = time.second.toString().padLeft(2, '0');
    return '$hour:$min:$sec';
  }
}

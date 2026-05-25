import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email ?? AppStrings.employee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mySpace),
        centerTitle: false,
        actions: [
          _AnnouncementBell(ref: ref),
          const SyncIndicatorWidget(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header con gradiente ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.backgroundDark,
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.glassBorder, width: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.todaySummary,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader(label: AppStrings.assignedWorkstation,
                        icon: Icons.desktop_windows_rounded),
                    const SizedBox(height: 10),
                    const _AssignedWorkstationSection(),
                    const SizedBox(height: 24),

                    const _SectionHeader(label: AppStrings.myProductivityToday,
                        icon: Icons.bar_chart_rounded),
                    const SizedBox(height: 10),
                    const _PersonalProductivitySection(),
                    const SizedBox(height: 24),

                    const _SectionHeader(label: AppStrings.recentActivityLive,
                        icon: Icons.history_rounded),
                    const SizedBox(height: 10),
                    const _RecentActivitySection(),
                    const SizedBox(height: 24),

                    const _SectionHeader(label: 'MIS TAREAS',
                        icon: Icons.task_alt_rounded),
                    const SizedBox(height: 10),
                    const _TaskMiniWidget(),
                    const SizedBox(height: 24),

                    const _SectionHeader(label: 'ACCESOS RÁPIDOS',
                        icon: Icons.grid_view_rounded),
                    const SizedBox(height: 10),
                    const _QuickAccessCard(
                      icon: Icons.history_rounded,
                      title: 'Mi actividad',
                      subtitle: 'Ver historial personal detallado',
                      route: AppRoutes.myActivity,
                    ),
                    const SizedBox(height: 10),
                    const _QuickAccessCard(
                      icon: Icons.schedule_rounded,
                      title: 'Mis horas',
                      subtitle: 'Consultar horas, sesiones y resumen diario',
                      route: AppRoutes.myHours,
                    ),
                    const SizedBox(height: 10),
                    const _QuickAccessCard(
                      icon: Icons.person_rounded,
                      title: 'Mi perfil',
                      subtitle: 'Ver estadísticas personales y datos de cuenta',
                      route: AppRoutes.profile,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días 👋';
  if (h < 18) return 'Buenas tardes 👋';
  return 'Buenas noches 👋';
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Assigned Workstation ──────────────────────────────────────────────────────
class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync = ref.watch(employeeAssignedWorkstationProvider);

    return workstationAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.verifyingWorkstation),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudo cargar la información del puesto de trabajo. Desliza hacia abajo para reintentar.',
      ),
      data: (workstation) {
        if (workstation == null) {
          return const _NoWorkstationCard();
        }
        return _WorkstationCard(workstation: workstation);
      },
    );
  }
}

class _NoWorkstationCard extends StatelessWidget {
  const _NoWorkstationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.grey600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.desktop_access_disabled_rounded,
                color: AppColors.textDisabledDark, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noAssignedWorkstation,
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  AppStrings.noAssignedWorkstationDescription,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkstationCard extends StatelessWidget {
  final WorkstationRecord workstation;
  const _WorkstationCard({required this.workstation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.computer_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workstation.name,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      AppStrings.monitoringAssigned,
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

// ── Personal Productivity ───────────────────────────────────────────────────
class _PersonalProductivitySection extends ConsumerWidget {
  const _PersonalProductivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const AppLoadingWidget(message: AppStrings.calculatingTime),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudieron cargar tus métricas de productividad. Desliza hacia abajo para reintentar.',
      ),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(AppStrings.noActivityToday, style: TextStyle(color: AppColors.grey600)),
              ),
            ),
          );
        }

        final totalDuration = analytics.totalTrackedTime;
        final workTime = analytics.stateDurations[ActivityState.trabajando] ?? Duration.zero;
        final distractTime = analytics.stateDurations[ActivityState.distraido] ?? Duration.zero;
        final fatigueTime = analytics.stateDurations[ActivityState.fatiga] ?? Duration.zero;

        // Custom widget to draw simple bars
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total: ${_formatDuration(totalDuration)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _StatBarRow(
                  label: 'Trabajando',
                  duration: workTime,
                  total: totalDuration,
                  color: AppColors.primary,
                  icon: Icons.work,
                ),
                const SizedBox(height: 12),
                _StatBarRow(
                  label: 'Distraído',
                  duration: distractTime,
                  total: totalDuration,
                  color: AppColors.warning,
                  icon: Icons.search,
                ),
                const SizedBox(height: 12),
                _StatBarRow(
                  label: 'Fatiga',
                  duration: fatigueTime,
                  total: totalDuration,
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
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

class _StatBarRow extends StatelessWidget {
  final String label;
  final Duration duration;
  final Duration total;
  final Color color;
  final IconData icon;

  const _StatBarRow({
    required this.label,
    required this.duration,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = total.inSeconds > 0 
      ? (duration.inSeconds / total.inSeconds)
      : 0.0;
      
    String formatDuration(Duration d) {
      if (d.inMinutes < 1) return '${d.inSeconds}s';
      if (d.inHours < 1) return '${d.inMinutes}m';
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 45,
          child: Text(
            formatDuration(duration),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}


// ── Recent Activity Feed ────────────────────────────────────────────────────
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(employeeRecentEventsProvider);

    return eventsAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => const ErrorBannerWidget(
        message: 'No se pudo cargar la actividad reciente. Desliza hacia abajo para reintentar.',
      ),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text(AppStrings.noRecentEvents, style: TextStyle(color: AppColors.grey500))),
          );
        }

        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.state.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  event.state.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_formatTime(event.timestamp)),
                trailing: event.identificationMethod != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: const TextStyle(fontSize: 10, color: AppColors.grey700),
                        ),
                      )
                    : null,
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

// ── Announcement bell button ──────────────────────────────────────────────────

class _AnnouncementBell extends StatelessWidget {
  const _AnnouncementBell({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadAnnouncementsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.campaign_rounded),
          tooltip: 'Comunicados',
          onPressed: () => context.push(AppRoutes.announcements),
        ),
        if (unread > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Task Mini Widget ────────────────────────────────────────────────────────

class _TaskMiniWidget extends ConsumerWidget {
  const _TaskMiniWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksProvider);

    return tasksAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final overdue = tasks.where((t) => t.isOverdue).length;

        return GestureDetector(
          onTap: () => context.go(AppRoutes.tasks),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Row(
              children: [
                _TaskCountBadge(count: pending, label: 'Pendientes', color: AppColors.textSecondaryDark),
                const _TaskDivider(),
                _TaskCountBadge(count: inProgress, label: 'En curso', color: AppColors.primary),
                const _TaskDivider(),
                _TaskCountBadge(count: overdue, label: 'Vencidas', color: AppColors.error),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textDisabledDark),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskCountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _TaskCountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey500, fontSize: 10),
        ),
      ],
    );
  }
}

class _TaskDivider extends StatelessWidget {
  const _TaskDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.glassBorder,
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textDisabledDark,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';
import 'package:worksense_app/shared/widgets/styled/app_section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final userId = currentUser?.user?.id;
    final myTasks = ref.watch(myTasksProvider).value ?? [];
    final myLeaves = ref.watch(myLeavesProvider).value ?? [];
    final shifts = ref.watch(shiftsProvider).value ?? [];
    final employees = ref.watch(adminEmployeesProvider).value ?? [];

    final myEmployee = userId != null
        ? employees.where((e) => e.id == userId).firstOrNull
        : null;

    final myShift = myEmployee?.shiftId != null
        ? shifts.where((s) => s.id == myEmployee!.shiftId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: AppDimensions.spacing120,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(
                name: myEmployee?.displayName ??
                    currentUser?.user?.email?.split('@').first ??
                    'Empleado',
                email: currentUser?.user?.email ?? '',
                role: currentUser?.role.metadataValue ?? 'EMPLOYEE',
              ),
            ),
            title: Text(
              AppStrings.myProfile,
              style: const TextStyle(
                  color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppContentConstrainer(
                  width: AppContentWidth.dashboard,
                  center: false,
                  child: Column(
                    children: [
                      // ── Personal info card ─────────────────────────────
                      _InfoCard(children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: AppStrings.nameLabelProfile,
                          value: myEmployee?.displayName ??
                              currentUser?.user?.email?.split('@').first ??
                              '—',
                        ),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: AppStrings.emailLabelProfile,
                          value: currentUser?.user?.email ?? '—',
                        ),
                        _InfoRow(
                          icon: Icons.security_outlined,
                          label: AppStrings.roleLabelProfile,
                          value: _roleLabel(
                              currentUser?.role.metadataValue ?? 'EMPLOYEE'),
                        ),
                      ]),
                      const SizedBox(height: AppDimensions.spacingLg),

                      // ── Shift card ────────────────────────────────────
                      _InfoCard(children: [
                        _InfoRow(
                          icon: Icons.schedule,
                          label: AppStrings.shiftLabel,
                          value: myShift != null
                              ? '${myShift.name} '
                                  '(${myShift.startTime.hour.toString().padLeft(2, '0')}:'
                                  '${myShift.startTime.minute.toString().padLeft(2, '0')} – '
                                  '${myShift.endTime.hour.toString().padLeft(2, '0')}:'
                                  '${myShift.endTime.minute.toString().padLeft(2, '0')})'
                              : AppStrings.noShiftAssigned,
                        ),
                        if (myEmployee?.companyId != null)
_InfoRow(
                          icon: Icons.business_outlined,
                          label: AppStrings.companyLabel,
                            value: myEmployee!.companyId.substring(
                                0,
                                myEmployee.companyId.length > AppDimensions.spacingXxl.toInt()
                                    ? AppDimensions.spacingXxl.toInt()
                                    : myEmployee.companyId.length),
                          ),
                      ]),
                      const SizedBox(height: AppDimensions.spacingLg),

                      // ── Stats row ──────────────────────────────────────
                      const AppSectionHeader(title: AppStrings.myStatistics),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.task_alt,
                              color: AppColors.primary,
                              label: AppStrings.totalTasks,
                              value: myTasks.length.toString(),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                              label: AppStrings.completedTasks,
                              value: myTasks
                                  .where((t) => t.status == TaskStatus.done)
                                  .length
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.pending_actions,
                              color: AppColors.warning,
                              label: AppStrings.pendingTasksLabel,
                              value: myTasks
                                  .where((t) =>
                                      t.status == TaskStatus.pending ||
                                      t.status == TaskStatus.inProgress)
                                  .length
                                  .toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.event_available,
                              color: AppColors.info,
                              label: AppStrings.requestedLeaves,
                              value: myLeaves.length.toString(),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.thumb_up_outlined,
                              color: AppColors.success,
                              label: AppStrings.approvedLeaves,
                              value: myLeaves
                                  .where((l) => l.status == LeaveStatus.approved)
                                  .length
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.hourglass_empty,
                              color: AppColors.warning,
                              label: AppStrings.pendingLeaves,
                              value: myLeaves
                                  .where((l) => l.status == LeaveStatus.pending)
                                  .length
                                  .toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.scrollBottomPadding),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'ADMIN':
        return AppStrings.roleAdminDisplay;
      case 'SUPER_ADMIN':
        return AppStrings.roleSuperAdminDisplay;
      case 'CAMERA_MONITOR':
        return AppStrings.roleCameraMonitorDisplay;
      default:
        return AppStrings.roleEmployeeDisplay;
    }
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

@override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [AppColors.primary, AppColors.background]
              : const [AppColors.primary, AppColors.lightBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppDimensions.spacing48),
            CircleAvatar(
              radius: AppDimensions.loginLogoPadding,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontDisplaySm,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              name,
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppDimensions.fontHeadline,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              email,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: AppDimensions.fontCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable components ───────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final glassBorder = context.appGlassBorder;
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: children
            .expand((w) => [w, Divider(height: 1, color: glassBorder)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appOnSurface;
    final onSurfaceSecondary = context.appOnSurfaceSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: AppDimensions.iconMd),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: onSurfaceSecondary, fontSize: AppDimensions.fontXs),
                ),
                const SizedBox(height: AppDimensions.spacingXxs),
                Text(
                  value,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppDimensions.fontBodyMd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurfaceSecondary = context.appOnSurfaceSecondary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconMd),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppDimensions.fontDisplayXs,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            label,
            style: TextStyle(
              color: onSurfaceSecondary,
              fontSize: AppDimensions.fontXs,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';

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
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(
                name: myEmployee?.displayName ??
                    currentUser?.user?.email?.split('@').first ??
                    'Empleado',
                email: currentUser?.user?.email ?? '',
                role: currentUser?.role.metadataValue ?? 'EMPLOYEE',
              ),
            ),
            title: const Text(
              'Mi Perfil',
              style: TextStyle(
                  color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Personal info card ─────────────────────────────
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Nombre',
                    value: myEmployee?.displayName ??
                        currentUser?.user?.email?.split('@').first ??
                        '—',
                  ),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: currentUser?.user?.email ?? '—',
                  ),
                  _InfoRow(
                    icon: Icons.security_outlined,
                    label: 'Rol',
                    value: _roleLabel(
                        currentUser?.role.metadataValue ?? 'EMPLOYEE'),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Shift card ────────────────────────────────────
                _InfoCard(children: [
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Turno',
                    value: myShift != null
                        ? '${myShift.name} '
                            '(${myShift.startTime.hour.toString().padLeft(2, '0')}:'
                            '${myShift.startTime.minute.toString().padLeft(2, '0')} – '
                            '${myShift.endTime.hour.toString().padLeft(2, '0')}:'
                            '${myShift.endTime.minute.toString().padLeft(2, '0')})'
                        : 'Sin turno asignado',
                  ),
                  if (myEmployee?.companyId != null)
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Empresa',
                      value: myEmployee!.companyId.substring(
                          0,
                          myEmployee.companyId.length > 8
                              ? 8
                              : myEmployee.companyId.length),
                    ),
                ]),
                const SizedBox(height: 14),

                // ── Stats row ──────────────────────────────────────
                const _SectionLabel('Mis estadísticas'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.task_alt,
                        color: AppColors.primary,
                        label: 'Tareas totales',
                        value: myTasks.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        label: 'Completadas',
                        value: myTasks
                            .where((t) => t.status == TaskStatus.done)
                            .length
                            .toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                        label: 'Pendientes',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_available,
                        color: AppColors.info,
                        label: 'Permisos solicitados',
                        value: myLeaves.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.thumb_up_outlined,
                        color: AppColors.success,
                        label: 'Aprobados',
                        value: myLeaves
                            .where((l) => l.status == LeaveStatus.approved)
                            .length
                            .toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.hourglass_empty,
                        color: AppColors.warning,
                        label: 'Pendientes',
                        value: myLeaves
                            .where((l) => l.status == LeaveStatus.pending)
                            .length
                            .toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
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
        return 'Administrador';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'CAMERA_MONITOR':
        return 'Monitor de Cámara';
      default:
        return 'Empleado';
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.backgroundDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              email,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: 12,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: children
            .expand((w) => [w, const Divider(height: 1, color: AppColors.glassBorder)])
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.grey400, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF13131A);
const _kCard = Color(0xFF1A1A24);
const _kBorder = Color(0xFF2A2A3A);
const _kBlue = Color(0xFF3A82F6);
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFFBBC04);
const _kRed = Color(0xFFEA4335);
const _kOrange = Color(0xFFFF6D00);
const _kGrey = Color(0xFF9E9E9E);
const _kTextPrimary = Color(0xFFEFF0F3);
const _kTextSecondary = Color(0xFF8890A4);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);
    final currentUserState = ref.watch(currentUserProvider);
    final userRole = currentUserState.valueOrNull?.role ?? AppRole.employee;
    final canManage =
        userRole == AppRole.admin || userRole == AppRole.superAdmin;
    final userEmail = ref.watch(currentUserEmailProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _kSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 64,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'W',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'WORKSENSE',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _kBorder),
            ),
            actions: [
              const SyncIndicatorWidget(),
              IconButton(
                icon: const Icon(Icons.history_rounded,
                    color: _kTextSecondary, size: 22),
                tooltip: 'Historial',
                onPressed: () => context.push('/history'),
              ),
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.people_outline_rounded,
                      color: _kTextSecondary, size: 22),
                  tooltip: 'Empleados',
                  onPressed: () => context.push('/employees'),
                ),
                IconButton(
                  icon: const Icon(Icons.monitor_outlined,
                      color: _kTextSecondary, size: 22),
                  tooltip: 'Estaciones',
                  onPressed: () => context.push('/workstations'),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: _kTextSecondary, size: 22),
                tooltip: 'Configuración',
                onPressed: () => context.push('/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: _kTextSecondary, size: 22),
                tooltip: 'Cerrar sesión',
                onPressed: () =>
                    ref.read(loginNotifierProvider.notifier).signOut(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Header / Stats ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: workstationsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (ws) => _DashboardHeader(
                workstationCount: ws.length,
                userEmail: userEmail,
                activeCount: ws.length,
              ),
            ),
          ),

          // ── Section label ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Text(
                    'ESTACIONES DE TRABAJO',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (canManage)
                    GestureDetector(
                      onTap: () => context.push('/workstations/new'),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: _kBlue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              color: _kBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          workstationsAsync.when(
            loading: () => const SliverFillRemaining(
              child: _LoadingView(),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorView(error: err.toString()),
            ),
            data: (workstations) {
              if (workstations.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyView(canManage: canManage),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 170,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        WorkstationCard(workstation: workstations[i]),
                    childCount: workstations.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: canManage
          ? _KioskFab(onTap: () => context.push('/kiosk/default'))
          : null,
    );
  }
}

// ─── Header / Stats row ───────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final int workstationCount;
  final int activeCount;
  final String? userEmail;

  const _DashboardHeader({
    required this.workstationCount,
    required this.activeCount,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: _kBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'PANEL DE CONTROL',
                style: TextStyle(
                  color: _kTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              // Live indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _kGreen.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseDot(color: _kGreen),
                    SizedBox(width: 5),
                    Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: _kGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              _StatChip(
                label: 'Total',
                value: '$workstationCount',
                icon: Icons.monitor_outlined,
                color: _kBlue,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Activos',
                value: '$activeCount',
                icon: Icons.check_circle_outline_rounded,
                color: _kGreen,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Inactivos',
                value: '${workstationCount - activeCount}',
                icon: Icons.pause_circle_outline_rounded,
                color: _kGrey,
              ),
            ],
          ),
          if (userEmail != null) ...[
            const SizedBox(height: 16),
            const Divider(color: _kBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    color: _kTextSecondary, size: 14),
                const SizedBox(width: 6),
                Text(
                  userEmail!,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _kTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
      ),
    );
  }
}

// ─── Kiosk FAB ───────────────────────────────────────────────────────────────

class _KioskFab extends StatelessWidget {
  final VoidCallback onTap;
  const _KioskFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _kBlue,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Iniciar Kiosco',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Loading / Error ──────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool canManage;
  const _EmptyView({required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.monitor_outlined,
                color: _kTextSecondary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin estaciones registradas',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configura tus puestos de trabajo para comenzar.',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (canManage) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/workstations/new'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Agregar estación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Error al cargar datos',
            style: TextStyle(
                color: _kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(color: _kTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── WorkstationCard ─────────────────────────────────────────────────────────

class WorkstationCard extends ConsumerWidget {
  final WorkstationRecord workstation;

  const WorkstationCard({super.key, required this.workstation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEvent =
        ref.watch(lastEventByWorkstationProvider(workstation.id));

    // Use the ActivityState enum's built-in getters
    final stateColor = lastEvent?.state.color ?? _kGrey;
    final stateLabel = lastEvent?.state.label ?? 'SIN DATOS';

    return GestureDetector(
      onTap: () => context.push('/kiosk/${workstation.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.monitor_outlined,
                      color: _kBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workstation.name,
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (workstation.deviceId != null)
                          Text(
                            workstation.deviceId!,
                            style: const TextStyle(
                              color: _kTextSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Status dot
                  _PulseDot(color: stateColor),
                ],
              ),

              const Spacer(),

              // State badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: stateColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _stateIcon(lastEvent?.state),
                      color: stateColor,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (lastEvent != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatTime(lastEvent.timestamp),
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _stateIcon(ActivityState? state) {
    switch (state) {
      case ActivityState.trabajando:
        return Icons.check_circle_outline_rounded;
      case ActivityState.distraido:
        return Icons.warning_amber_rounded;
      case ActivityState.ausente:
        return Icons.person_off_outlined;
      case ActivityState.fatiga:
        return Icons.bedtime_outlined;
      case ActivityState.inactivo:
      case null:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hoy $h:$m';
    }
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_text_styles.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_dashboard_card.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/providers/theme_mode_provider.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final workstationsAsync = ref.watch(workstationsStreamProvider);
    final recentEventsAsync = ref.watch(recentEventsStreamProvider);
    final currentUserState = ref.watch(currentUserProvider);
    final userRole = currentUserState.valueOrNull?.role ?? AppRole.employee;
    final canManage =
        userRole == AppRole.admin || userRole == AppRole.superAdmin;
    final themeMode = ref.watch(themeModeProvider);
    final palette = _DashboardPalette.of(context);

    final workstationsById = <String, WorkstationRecord>{
      for (final workstation
          in workstationsAsync.valueOrNull ?? <WorkstationRecord>[])
        workstation.id: workstation,
    };
    final latestEventsByEmployee =
        _latestEventByEmployee(recentEventsAsync.valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: palette.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: palette.surface,
        edgeOffset: 92,
        onRefresh: () => _handleRefresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: palette.background,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 82,
              titleSpacing: 24,
              title: Text(
                'Comando central',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: palette.heading,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: themeMode == ThemeMode.dark
                      ? 'Cambiar a modo claro'
                      : 'Cambiar a modo oscuro',
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleLightDark();
                  },
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: palette.heading,
                  ),
                ),
                const SyncIndicatorWidget(),
                const SizedBox(width: 12),
              ],
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(),
              ),
            ),
            ...employeesAsync.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingView(),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(error: error.toString()),
                ),
              ],
              data: (employees) {
                if (employees.isEmpty) {
                  return const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(),
                    ),
                  ];
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 168),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisExtent: 180,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final employee = employees[index];
                          final latestEvent =
                              latestEventsByEmployee[employee.id];
                          final workstation = latestEvent == null
                              ? null
                              : workstationsById[latestEvent.workstationId];

                          return EmployeeDashboardCard(
                            employeeName: employee.name,
                            workstationName: workstation?.name,
                            lastStateLabel:
                                latestEvent?.state.label ?? 'SIN REGISTRO',
                            lastStateColor:
                                latestEvent?.state.color ?? AppColors.grey500,
                            lastStateIcon: _stateIcon(latestEvent?.state),
                            updatedLabel: _formatLastSeen(
                              latestEvent?.timestamp,
                              employee.createdAt,
                            ),
                            onTap: () => context.push('/employees'),
                          );
                        },
                        childCount: employees.length,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? _AdminActions(
              onStations: () => context.push('/workstations'),
              onKiosk: () => context.push('/kiosk/default'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _DashboardBottomBar(
        canManage: canManage,
        onHistory: () => context.push('/history'),
        onEmployees: () => context.push('/employees'),
        onWorkstations: () => context.push('/workstations'),
        onSettings: () => context.push('/settings'),
        onLogout: () => ref.read(loginNotifierProvider.notifier).signOut(),
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    await ref.read(syncNotifierProvider.notifier).syncNow();

    ref.invalidate(employeesStreamProvider);
    ref.invalidate(workstationsStreamProvider);
    ref.invalidate(recentEventsStreamProvider);

    await Future.wait([
      ref.refresh(employeesProvider.future),
      ref.refresh(workstationsProvider.future),
      ref.refresh(recentEventsProvider.future),
    ]);
  }

  Map<String, ActivityEvent> _latestEventByEmployee(
    List<ActivityEvent> events,
  ) {
    final latest = <String, ActivityEvent>{};
    for (final event in events) {
      final employeeId = event.employeeId;
      if (employeeId == null) continue;

      final previous = latest[employeeId];
      if (previous == null || event.timestamp.isAfter(previous.timestamp)) {
        latest[employeeId] = event;
      }
    }
    return latest;
  }

  IconData _stateIcon(ActivityState? state) {
    switch (state) {
      case ActivityState.trabajando:
        return Icons.check_circle_rounded;
      case ActivityState.distraido:
        return Icons.visibility_off_rounded;
      case ActivityState.fatiga:
        return Icons.bedtime_rounded;
      case ActivityState.ausente:
        return Icons.person_off_rounded;
      case ActivityState.inactivo:
      case null:
        return Icons.timelapse_rounded;
    }
  }

  String _formatLastSeen(DateTime? timestamp, DateTime fallback) {
    final source = timestamp ?? fallback;
    if (timestamp == null) {
      return 'Registrado ${_formatDate(source)}';
    }

    final diff = DateTime.now().difference(source);
    if (diff.inMinutes < 1) return 'Actualizado hace un momento';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado ${_formatDate(source)}';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLABORADORES',
            style: AppTextStyles.labelMedium.copyWith(
              color: palette.subtle,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus trabajadores',
            style: AppTextStyles.headlineMedium.copyWith(
              color: palette.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Consulta el estado general de cada colaborador y entra a su detalle desde una sola vista.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.subtle,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  final VoidCallback onStations;
  final VoidCallback onKiosk;

  const _AdminActions({
    required this.onStations,
    required this.onKiosk,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'view-stations-fab',
          backgroundColor: palette.surface,
          foregroundColor: palette.heading,
          elevation: 4,
          onPressed: onStations,
          icon: const Icon(Icons.desktop_windows),
          label: const Text('VER ESTACIONES'),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'reception-kiosk-fab',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: onKiosk,
          icon: const Icon(Icons.meeting_room),
          label: const Text('KIOSCO RECEPCION'),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: palette.subtle,
            ),
            const SizedBox(height: 20),
            Text(
              'Todavía no tienes colaboradores registrados',
              style: AppTextStyles.titleLarge.copyWith(
                color: palette.heading,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer empleado para comenzar a monitorear actividad y productividad.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.subtle,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/employees/new'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('REGISTRAR EMPLEADO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 18),
            Text(
              'No fue posible cargar el dashboard',
              style: AppTextStyles.titleLarge.copyWith(
                color: palette.heading,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: palette.subtle,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBottomBar extends StatelessWidget {
  final bool canManage;
  final VoidCallback onHistory;
  final VoidCallback? onEmployees;
  final VoidCallback? onWorkstations;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _DashboardBottomBar({
    required this.canManage,
    required this.onHistory,
    required this.onEmployees,
    required this.onWorkstations,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.space_dashboard_rounded,
                label: 'Inicio',
                active: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Historial',
                onTap: onHistory,
              ),
              if (canManage) ...[
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Empleados',
                  onTap: onEmployees ?? () {},
                ),
                _NavItem(
                  icon: Icons.desktop_windows_rounded,
                  label: 'Estaciones',
                  onTap: onWorkstations ?? () {},
                ),
              ],
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Config',
                onTap: onSettings,
              ),
              _NavItem(
                icon: Icons.logout_rounded,
                label: 'Salir',
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);
    final color = active ? AppColors.primary : palette.subtle;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPalette {
  final Color background;
  final Color surface;
  final Color border;
  final Color heading;
  final Color subtle;
  final Color shadow;

  const _DashboardPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.heading,
    required this.subtle,
    required this.shadow,
  });

  factory _DashboardPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return _DashboardPalette(
      background: dark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      surface: dark ? const Color(0xFF111827) : Colors.white,
      border: dark ? const Color(0xFF334155) : const Color(0xFFDDE5F0),
      heading: dark ? Colors.white : const Color(0xFF0F172A),
      subtle: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      shadow: dark ? const Color(0x00000000) : const Color(0x120F172A),
    );
  }
}

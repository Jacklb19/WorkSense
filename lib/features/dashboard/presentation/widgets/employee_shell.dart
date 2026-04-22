import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/routing/app_router.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

/// Shell reutilizable con BottomNavBar para las pantallas del empleado.
/// Recibe el `child` (la pantalla activa) y resalta el item correcto.
class EmployeeShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex; // 0=actividad, 1=rendimiento, 2=ajustes

  const EmployeeShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _EmployeeBottomBar(
        selectedIndex: selectedIndex,
        onActivity: () => context.go(AppRoutes.myActivity),
        onHours: () => context.go(AppRoutes.myHours),
        onSettings: () => context.go(AppRoutes.settings),
        onLogout: () => ref.read(loginNotifierProvider.notifier).signOut(),
      ),
    );
  }
}

class _EmployeeBottomBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onActivity;
  final VoidCallback onHours;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _EmployeeBottomBar({
    required this.selectedIndex,
    required this.onActivity,
    required this.onHours,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFDDE5F0);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.timeline_rounded,
                label: 'Actividad',
                active: selectedIndex == 0,
                onTap: onActivity,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Rendimiento',
                active: selectedIndex == 1,
                onTap: onHours,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                active: selectedIndex == 2,
                onTap: onSettings,
              ),
              _NavItem(
                icon: Icons.logout_rounded,
                label: 'Salir',
                active: false,
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
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final color = active ? AppColors.primary : subtle;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

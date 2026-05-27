import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/constants.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';

/// Admin nav — 6 items (Leaves hidden)
List<NavDestination> adminDestinations(AppLocalizations l) => [
  NavDestination(
    label: l.navDashboard,
    icon: const Icon(Icons.dashboard_outlined),
    selectedIcon: const Icon(Icons.dashboard),
    route: AppRoutes.dashboard,
  ),
  NavDestination(
    label: l.navEmployees,
    icon: const Icon(Icons.people_outline),
    selectedIcon: const Icon(Icons.people),
    route: AppRoutes.employees,
  ),
  NavDestination(
    label: l.navWorkstations,
    icon: const Icon(Icons.computer_outlined),
    selectedIcon: const Icon(Icons.computer),
    route: AppRoutes.workstations,
  ),
  NavDestination(
    label: l.navTasks,
    icon: const Icon(Icons.task_outlined),
    selectedIcon: const Icon(Icons.task),
    route: AppRoutes.tasks,
  ),
  // Leaves (hidden — branch 7 exists but is not shown in nav)
  NavDestination(
    label: l.navShifts,
    icon: const Icon(Icons.schedule_outlined),
    selectedIcon: const Icon(Icons.schedule),
    route: AppRoutes.shifts,
  ),
  NavDestination(
    label: l.navSettings,
    icon: const Icon(Icons.settings_outlined),
    selectedIcon: const Icon(Icons.settings),
    route: AppRoutes.settings,
  ),
];

/// Employee nav — 4 items (Leaves hidden)
List<NavDestination> employeeDestinations(AppLocalizations l) => [
  NavDestination(
    label: l.navHome,
    icon: const Icon(Icons.home_outlined),
    selectedIcon: const Icon(Icons.home),
    route: AppRoutes.dashboard,
  ),
  NavDestination(
    label: l.navTasks,
    icon: const Icon(Icons.task_outlined),
    selectedIcon: const Icon(Icons.task),
    route: AppRoutes.tasks,
  ),
  // Leaves (hidden — branch 7 exists but is not shown in nav)
  NavDestination(
    label: l.navActivity,
    icon: const Icon(Icons.history_outlined),
    selectedIcon: const Icon(Icons.history),
    route: AppRoutes.history,
  ),
  NavDestination(
    label: l.navSettings,
    icon: const Icon(Icons.settings_outlined),
    selectedIcon: const Icon(Icons.settings),
    route: AppRoutes.settings,
  ),
];

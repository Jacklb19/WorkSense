import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/constants.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';

/// Admin nav — 7 items
/// Branch mapping: UI 0→0, UI 1→1, UI 2→2, UI 3→6(Tasks), UI 4→7(Leaves), UI 5→5(Shifts), UI 6→4(Settings)
final List<NavDestination> adminDestinations = [
  const NavDestination(
    label: AppStrings.navDashboard,
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    route: AppRoutes.dashboard,
  ),
  const NavDestination(
    label: AppStrings.navEmployees,
    icon: Icon(Icons.people_outline),
    selectedIcon: Icon(Icons.people),
    route: AppRoutes.employees,
  ),
  const NavDestination(
    label: AppStrings.navWorkstations,
    icon: Icon(Icons.computer_outlined),
    selectedIcon: Icon(Icons.computer),
    route: AppRoutes.workstations,
  ),
  const NavDestination(
    label: 'Tareas',
    icon: Icon(Icons.task_outlined),
    selectedIcon: Icon(Icons.task),
    route: AppRoutes.tasks,
  ),
  const NavDestination(
    label: 'Permisos',
    icon: Icon(Icons.beach_access_outlined),
    selectedIcon: Icon(Icons.beach_access),
    route: AppRoutes.leaves,
  ),
  const NavDestination(
    label: 'Horarios',
    icon: Icon(Icons.schedule_outlined),
    selectedIcon: Icon(Icons.schedule),
    route: AppRoutes.shifts,
  ),
  const NavDestination(
    label: AppStrings.navSettings,
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    route: AppRoutes.settings,
  ),
];

/// Employee nav — 5 items
/// Branch mapping: UI 0→0, UI 1→6(Tasks), UI 2→7(Leaves), UI 3→3(History), UI 4→4(Settings)
final List<NavDestination> employeeDestinations = [
  const NavDestination(
    label: AppStrings.navHome,
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    route: AppRoutes.dashboard,
  ),
  const NavDestination(
    label: 'Tareas',
    icon: Icon(Icons.task_outlined),
    selectedIcon: Icon(Icons.task),
    route: AppRoutes.tasks,
  ),
  const NavDestination(
    label: 'Permisos',
    icon: Icon(Icons.beach_access_outlined),
    selectedIcon: Icon(Icons.beach_access),
    route: AppRoutes.leaves,
  ),
  const NavDestination(
    label: AppStrings.navActivity,
    icon: Icon(Icons.history_outlined),
    selectedIcon: Icon(Icons.history),
    route: AppRoutes.history,
  ),
  const NavDestination(
    label: AppStrings.navSettings,
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    route: AppRoutes.settings,
  ),
];

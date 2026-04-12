import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/constants.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';

final List<NavDestination> adminDestinations = [
  const NavDestination(
    label: AppStrings.navDashboard,
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    route: AppRoutes.dashboard, // Used as a reference
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
    label: AppStrings.navSettings,
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    route: AppRoutes.settings,
  ),
];

final List<NavDestination> employeeDestinations = [
  const NavDestination(
    label: AppStrings.navHome,
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    route: AppRoutes.dashboard,
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

import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.badgeCount = 0,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;

  /// Number shown on the badge overlay. 0 = no badge.
  final int badgeCount;

  /// Returns a copy with the given badge count applied.
  NavDestination withBadge(int count) => NavDestination(
        label: label,
        icon: icon,
        selectedIcon: selectedIcon,
        route: route,
        badgeCount: count,
      );
}

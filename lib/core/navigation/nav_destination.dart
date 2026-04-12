import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;
}

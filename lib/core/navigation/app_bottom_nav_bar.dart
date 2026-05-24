import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';

class AppBottomNavBar extends StatelessWidget {
  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  Widget _withBadge(Widget child, int count) {
    if (count <= 0) return child;
    return Badge.count(
      count: count,
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        HapticFeedback.selectionClick();
        onDestinationSelected(index);
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: AppColors.primary.withValues(alpha: 0.25),
      destinations: destinations.map((d) {
        return NavigationDestination(
          icon: _withBadge(d.icon, d.badgeCount),
          selectedIcon: _withBadge(d.selectedIcon, d.badgeCount),
          label: d.label,
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        HapticFeedback.selectionClick();
        onDestinationSelected(index);
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations.map((d) {
        return NavigationDestination(
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          label: d.label,
        );
      }).toList(),
    );
  }
}

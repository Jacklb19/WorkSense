import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import 'nav_destination.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          onDestinationSelected(index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withAlpha(40),
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 72,
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: d.label,
          );
        }).toList(),
        animationDuration: AppAnimations.normal,
      ),
    ).animate().fadeIn(duration: AppAnimations.normal);
  }
}

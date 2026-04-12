import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_text_styles.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';

/// Custom bottom navigation bar matching the WorkSense design system.
/// Dark background with top border, custom active/inactive colors.
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
      height: 83,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (index) {
            final dest = destinations[index];
            final isActive = index == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDestinationSelected(index);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      child: isActive ? dest.selectedIcon : dest.icon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dest.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

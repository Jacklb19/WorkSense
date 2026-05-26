import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import 'nav_destination.dart';

class AppBottomNavBar extends StatefulWidget {
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
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillAnimation;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      duration: AppDimensions.animNormal,
      vsync: this,
    );
    _pillAnimation = CurvedAnimation(
      parent: _pillController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pillController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  Widget _withBadge(Widget child, int count) {
    if (count <= 0) return child;
    return Badge.count(
      count: count,
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      textStyle: const TextStyle(fontSize: AppDimensions.fontXxs, fontWeight: FontWeight.bold),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.destinations.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.88)
        : AppColors.lightSurface.withValues(alpha: 0.92);
    final borderColor = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;
    final unselectedColor = isDark ? AppColors.textDisabled : AppColors.lightTextDisabled;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppDimensions.glassBlur * 2.4, sigmaY: AppDimensions.glassBlur * 2.4),
        child: Container(
          height: AppDimensions.bottomNavHeight + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(color: borderColor, width: AppDimensions.glassBorderWidth * 0.6),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: List.generate(n, (i) {
                final dest = widget.destinations[i];
                final isSelected = i == widget.currentIndex;

                return Expanded(
                  child: _NavItem(
                    destination: dest,
                    isSelected: isSelected,
                    isDark: isDark,
                    unselectedColor: unselectedColor,
                    animation: i == widget.currentIndex
                        ? _pillAnimation
                        : const AlwaysStoppedAnimation(0.0),
                    badgeWidget: _withBadge,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onDestinationSelected(i);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final bool isDark;
  final Color unselectedColor;
  final Animation<double> animation;
  final Widget Function(Widget, int) badgeWidget;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.isDark,
    required this.unselectedColor,
    required this.animation,
    required this.badgeWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    width: isSelected ? AppDimensions.iconContainerSm : AppDimensions.iconDefault + AppDimensions.spacingXxl,
                    height: AppDimensions.iconDefault + AppDimensions.spacingMd,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                          )
                        : null,
                    child: Center(
                      child: badgeWidget(
                        AnimatedSwitcher(
duration: AppDimensions.animFast,
                      child: isSelected
                              ? IconTheme(
                                  data: const IconThemeData(
                                    color: AppColors.primary,
                                    size: AppDimensions.iconDefault,
                                  ),
                                  child: destination.selectedIcon,
                                )
                              : IconTheme(
                                  data: IconThemeData(
                                    color: unselectedColor,
                                    size: AppDimensions.iconMd,
                                  ),
                                  child: destination.icon,
                                ),
                        ),
                        destination.badgeCount,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: AppDimensions.fontXs,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : unselectedColor,
                  letterSpacing: 0.2,
                ),
                child: Text(destination.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      duration: const Duration(milliseconds: 260),
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
      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.destinations.length;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.88),
            border: const Border(
              top: BorderSide(
                color: AppColors.glassBorder,
                width: 0.6,
              ),
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
  final Animation<double> animation;
  final Widget Function(Widget, int) badgeWidget;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.animation,
    required this.badgeWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: isSelected ? 52 : 40,
                  height: 32,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Center(
                    child: badgeWidget(
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSelected
                            ? IconTheme(
                                data: const IconThemeData(
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                child: destination.selectedIcon,
                              )
                            : IconTheme(
                                data: const IconThemeData(
                                  color: AppColors.textDisabledDark,
                                  size: 20,
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
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textDisabledDark,
                letterSpacing: 0.2,
              ),
              child: Text(destination.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

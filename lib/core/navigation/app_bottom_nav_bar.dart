import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme_colors.dart';
import 'nav_destination.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AppBottomNavBar
// ═══════════════════════════════════════════════════════════════════════════════
//
// Layout: [Dashboard] · [⊞ Menu] · [Settings]
//
// The first item in [destinations] is always shown on the left.
// The last  item is always shown on the right.
// Everything in between goes into the floating popup triggered by the center button.
//
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
    with TickerProviderStateMixin {
  bool _menuOpen = false;
  OverlayEntry? _overlayEntry;

  late final AnimationController _iconController;   // menu icon spin
  late final AnimationController _popupController;  // popup scale/fade

  // ── Helpers ────────────────────────────────────────────────────────────────

  NavDestination get _primary  => widget.destinations.first;
  NavDestination get _settings => widget.destinations.last;

  List<NavDestination> get _menuDests {
    if (widget.destinations.length <= 2) return [];
    return widget.destinations.sublist(1, widget.destinations.length - 1);
  }

  bool get _isPrimarySelected  => widget.currentIndex == 0;
  bool get _isSettingsSelected => widget.currentIndex == widget.destinations.length - 1;
  bool get _isMenuItemActive   => !_isPrimarySelected && !_isSettingsSelected;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _iconController  = AnimationController(
        duration: const Duration(milliseconds: 320), vsync: this);
    _popupController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    // Close the popup if the active route changed externally
    if (old.currentIndex != widget.currentIndex && _menuOpen) {
      _closeMenu(animate: false);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _iconController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  // ── Menu open / close ──────────────────────────────────────────────────────

  void _toggleMenu() {
    HapticFeedback.mediumImpact();
    _menuOpen ? _closeMenu() : _openMenu();
  }

  void _openMenu() {
    if (_menuOpen) return;
    final mq      = MediaQuery.of(context);
    final navH    = 72.0 + mq.padding.bottom;
    final screen  = mq.size;

    setState(() => _menuOpen = true);
    _iconController.forward();
    _overlayEntry = _buildOverlay(navHeight: navH, screen: screen);
    Overlay.of(context).insert(_overlayEntry!);
    _popupController.forward(from: 0);
  }

  Future<void> _closeMenu({bool animate = true}) async {
    if (!_menuOpen) return;
    if (animate) await _popupController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _iconController.reverse();
    if (mounted) setState(() => _menuOpen = false);
  }

  void _selectMenuItem(int menuIndex) {
    _closeMenu();
    // +1 because primary occupies index 0
    widget.onDestinationSelected(menuIndex + 1);
  }

  // ── Overlay builder ────────────────────────────────────────────────────────

  OverlayEntry _buildOverlay({
    required double navHeight,
    required Size screen,
  }) {
    const popupMaxW = 280.0;
    final popupW = (screen.width * 0.78).clamp(0.0, popupMaxW);
    final popupLeft = (screen.width - popupW) / 2;

    return OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: _popupController,
        builder: (ctx, __) {
          return Stack(
            children: [
              // ── Scrim ─────────────────────────────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Colors.black
                        .withValues(alpha: 0.52 * _popupController.value),
                  ),
                ),
              ),

              // ── Popup card ────────────────────────────────────────────────
              Positioned(
                bottom: navHeight + 14,
                left: popupLeft,
                width: popupW,
                child: _PopupCard(
                  destinations: _menuDests,
                  activeMenuIndex:
                      _isMenuItemActive ? widget.currentIndex - 1 : -1,
                  popupAnimation: _popupController,
                  onSelect: _selectMenuItem,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ac  = context.appColors;
    final bot = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + bot,
          decoration: BoxDecoration(
            color: ac.background.withValues(alpha: 0.90),
            border: const Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.6),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bot),
            child: Row(
              children: [
                // ── Left: primary (Dashboard / Home) ──────────────────────
                Expanded(
                  child: _NavPill(
                    destination: _primary,
                    isSelected: _isPrimarySelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_menuOpen) _closeMenu(animate: false);
                      widget.onDestinationSelected(0);
                    },
                  ),
                ),

                // ── Center: menu trigger ───────────────────────────────────
                _MenuTrigger(
                  isOpen: _menuOpen,
                  hasActiveItem: _isMenuItemActive,
                  iconController: _iconController,
                  onTap: _toggleMenu,
                ),

                // ── Right: settings ────────────────────────────────────────
                Expanded(
                  child: _NavPill(
                    destination: _settings,
                    isSelected: _isSettingsSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_menuOpen) _closeMenu(animate: false);
                      widget.onDestinationSelected(
                          widget.destinations.length - 1);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _NavPill — left / right persistent items
// ═══════════════════════════════════════════════════════════════════════════════

class _NavPill extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavPill({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon chip
            AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              width: isSelected ? 54 : 40,
              height: 32,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? IconTheme(
                          key: const ValueKey('on'),
                          data: const IconThemeData(
                              color: AppColors.primary, size: 22),
                          child: destination.selectedIcon,
                        )
                      : IconTheme(
                          key: const ValueKey('off'),
                          data: IconThemeData(
                              color: ac.textDisabled, size: 20),
                          child: destination.icon,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : ac.textDisabled,
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

// ═══════════════════════════════════════════════════════════════════════════════
// _MenuTrigger — center floating button
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuTrigger extends StatelessWidget {
  final bool isOpen;
  final bool hasActiveItem;
  final AnimationController iconController;
  final VoidCallback onTap;

  const _MenuTrigger({
    required this.isOpen,
    required this.hasActiveItem,
    required this.iconController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 88,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active-item indicator dot
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: hasActiveItem && !isOpen ? 1.0 : 0.0,
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Button pill
            AnimatedBuilder(
              animation: iconController,
              builder: (_, __) {
                final t = iconController.value;
                return Container(
                  width: 56,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary
                            .withValues(alpha: 0.12 + 0.28 * t),
                        AppColors.accent
                            .withValues(alpha: 0.08 + 0.20 * t),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: 0.18 + 0.32 * t),
                      width: 1,
                    ),
                    boxShadow: isOpen
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.28),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: isOpen
                          ? const Icon(
                              Icons.close_rounded,
                              key: ValueKey('x'),
                              color: AppColors.primary,
                              size: 20,
                            )
                          : Icon(
                              Icons.apps_rounded,
                              key: const ValueKey('grid'),
                              color: hasActiveItem
                                  ? AppColors.primary
                                  : AppColors.grey500,
                              size: 20,
                            ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    (isOpen || hasActiveItem) ? FontWeight.w700 : FontWeight.w500,
                color: (isOpen || hasActiveItem)
                    ? AppColors.primary
                    : AppColors.grey500,
                letterSpacing: 0.2,
              ),
              child: const Text('Menú', maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _PopupCard — floating menu overlay (grid layout)
// ═══════════════════════════════════════════════════════════════════════════════

class _PopupCard extends StatelessWidget {
  final List<NavDestination> destinations;
  final int activeMenuIndex;
  final Animation<double> popupAnimation;
  final ValueChanged<int> onSelect;

  const _PopupCard({
    required this.destinations,
    required this.activeMenuIndex,
    required this.popupAnimation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnim = CurvedAnimation(
      parent: popupAnimation,
      curve: Curves.easeOutBack,
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(scaleAnim),
      alignment: Alignment.bottomCenter,
      child: FadeTransition(
        opacity: CurvedAnimation(
            parent: popupAnimation, curve: Curves.easeOut),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1322).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.glassBorderBright,
                  width: 0.9,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  _PopupHeader(),

                  const SizedBox(height: 4),

                  // ── Grid of tiles ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: destinations.asMap().entries.map((e) {
                        final idx    = e.key;
                        final dest   = e.value;
                        final active = idx == activeMenuIndex;
                        return _GridTile(
                          destination: dest,
                          isActive: active,
                          delay: idx * 55,
                          onTap: () => onSelect(idx),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Popup header ──────────────────────────────────────────────────────────────

class _PopupHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Accent vertical bar
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'SECCIONES',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.grid_view_rounded,
            color: AppColors.primaryLight,
            size: 14,
          ),
        ],
      ),
    );
  }
}

// ── Grid tile ─────────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final NavDestination destination;
  final bool isActive;
  final int delay; // ms
  final VoidCallback onTap;

  const _GridTile({
    required this.destination,
    required this.isActive,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed tile width — 3 cols fit comfortably in a ~280px popup
    // (280 - 24 padding - 16 spacing) / 3 ≈ 80px
    const tileW = 78.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutCubic,
        width: tileW,
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.14)
              : const Color(0xFF141E30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.42)
                : AppColors.glassBorder.withValues(alpha: 0.9),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon with badge ───────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.primaryGradient,
                          )
                        : null,
                    color: isActive ? null : const Color(0xFF0F1829),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        color: isActive ? Colors.white : AppColors.grey500,
                        size: 21,
                      ),
                      child: isActive
                          ? destination.selectedIcon
                          : destination.icon,
                    ),
                  ),
                ),
                if (destination.badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          destination.badgeCount > 9
                              ? '9+'
                              : '${destination.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Label ─────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive
                    ? AppColors.primaryLight
                    : AppColors.textPrimaryDark.withValues(alpha: 0.80),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
                letterSpacing: 0.1,
              ),
              child: Text(
                destination.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay.ms)
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.35,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

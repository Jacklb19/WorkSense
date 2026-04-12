import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_radius.dart';

enum CardType { surface, elevated, accent, violet }

/// Reusable card component with predefined visual variants.
class WsCard extends StatelessWidget {
  final Widget child;
  final CardType type;
  final EdgeInsetsGeometry? padding;
  final Color? borderOverride;

  const WsCard({
    super.key,
    required this.child,
    this.type = CardType.surface,
    this.padding,
    this.borderOverride,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (type) {
      CardType.surface  => (AppColors.surface, AppColors.borderColor),
      CardType.elevated => (AppColors.elevated, AppColors.borderColor),
      CardType.accent   => (AppColors.accentCardBg, AppColors.primary),
      CardType.violet   => (AppColors.violetCardBg, AppColors.violet),
    };

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: borderOverride ?? border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

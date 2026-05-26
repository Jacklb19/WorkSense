import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// A gradient overlay container used at the top or bottom of the Kiosk
/// camera view to render HUD controls over the live preview.
///
/// [alignment] controls the gradient direction:
/// - [Alignment.topCenter] → dark-to-transparent (top HUD)
/// - [Alignment.bottomCenter] → dark-to-transparent (bottom HUD)
class KioskOverlayContainer extends StatelessWidget {
  const KioskOverlayContainer({
    super.key,
    required this.alignment,
    required this.child,
    this.horizontalPadding = AppDimensions.spacing24,
    this.verticalPadding = AppDimensions.spacingXxl,
  });

  /// [Alignment.topCenter] or [Alignment.bottomCenter]
  final Alignment alignment;
  final Widget child;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topCenter;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            AppColors.black.withValues(alpha: 0.8),
            AppColors.transparent,
          ],
        ),
      ),
      child: child,
    );
  }
}

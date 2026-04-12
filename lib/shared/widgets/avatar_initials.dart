import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// Circle avatar displaying initials with a configurable background.
class AvatarInitials extends StatelessWidget {
  final String initials;
  final Color bg;
  final double size;

  const AvatarInitials({
    super.key,
    required this.initials,
    this.bg = AppColors.primaryDark,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final Widget? action;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final onSurfaceSecondary = context.appOnSurfaceSecondary;

    return Semantics(
      header: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontCaption,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spacingMd + 3),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  color: onSurfaceSecondary,
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.spacingSm),
        ],
      ),
    );
  }
}
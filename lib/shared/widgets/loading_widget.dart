import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: AppDimensions.progressStrokeWidth,
              color: AppColors.primary,
            ),
          ).animate(onInit: (controller) => controller.repeat())
            .rotate(duration: 1000.ms),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class InlineLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const InlineLoadingWidget({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: AppDimensions.progressStrokeWidth,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

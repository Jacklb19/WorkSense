import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';

class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message ?? 'Cargando',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacingXxl),
              Text(
                message!,
                style: const TextStyle(color: AppColors.grey500, fontSize: AppDimensions.fontBodyMd),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const InlineLoadingWidget({
    super.key,
    this.size = AppDimensions.progressIndicatorSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: AppDimensions.progressStrokeWidth,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
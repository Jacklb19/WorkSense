import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';

class DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;
  const DateRow({super.key, required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Seleccionar fecha $label',
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// Compact uppercase section label used throughout the app
/// (e.g. "ACTIVIDAD DE HOY", "JORNADAS RECIENTES").
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.label,
    this.color = AppColors.white54,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

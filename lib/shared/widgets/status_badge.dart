import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/core/theme/app_text_styles.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

/// Pill badge that displays an ActivityState with a colored dot and label.
class StatusBadge extends StatelessWidget {
  final ActivityState state;

  const StatusBadge({super.key, required this.state});

  Color _colorFor(ActivityState s) => switch (s) {
    ActivityState.trabajando     => AppColors.stateWorking,
    ActivityState.inactivo       => AppColors.stateInactive,
    ActivityState.distraido      => AppColors.stateDistracted,
    ActivityState.fatiga         => AppColors.stateFatigue,
    ActivityState.ausente        => AppColors.stateAbsent,
    ActivityState.fueraDelArea   => AppColors.primary,
    ActivityState.noIdentificado => AppColors.violet,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            state.label,
            style: AppTextStyles.stateBadge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

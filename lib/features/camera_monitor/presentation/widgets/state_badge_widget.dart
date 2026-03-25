import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

class StateBadgeWidget extends StatelessWidget {
  final ActivityState state;
  final double? confidence;
  final bool showConfidence;
  final double fontSize;

  const StateBadgeWidget({
    super.key,
    required this.state,
    this.confidence,
    this.showConfidence = false,
    this.fontSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: state.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: state.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateIndicatorDot(color: state.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              state.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: state.color,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (showConfidence && confidence != null) ...[
            const SizedBox(width: 6),
            Text(
              '${(confidence! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: fontSize - 1,
                color: state.color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateIndicatorDot extends StatelessWidget {
  final Color color;

  const _StateIndicatorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Large state display for kiosk mode overlay
class KioskStateBadge extends StatelessWidget {
  final ActivityState state;
  final double confidence;

  const KioskStateBadge({
    super.key,
    required this.state,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.overlayBadgeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: state.color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            state.label,
            style: TextStyle(
              color: state.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

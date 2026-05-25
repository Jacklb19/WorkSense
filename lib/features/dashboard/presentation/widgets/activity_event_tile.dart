import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';

class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;
  final bool showWorkstationId;

  const ActivityEventTile({
    required this.event,
    this.showWorkstationId = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.02)),
        ),
        child: Row(
          children: [
            Semantics(
              label: event.state.label,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: event.state.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(event.state.emoji, style: const TextStyle(fontSize: AppDimensions.fontTitle)),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.state.label.toUpperCase(),
                        style: TextStyle(
                          color: event.state.color,
                          fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      if (!event.synced)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs, vertical: AppDimensions.spacingXxs),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: const Text('OFFLINE', style: TextStyle(color: AppColors.warning, fontSize: AppDimensions.fontXxs, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'CONFIANZA: ${(event.confidence * 100).round()}%',
                    style: const TextStyle(color: AppColors.white24, fontSize: AppDimensions.fontXxs, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(event.timestamp),
                  style: const TextStyle(color: AppColors.white38, fontSize: AppDimensions.fontXs, fontWeight: FontWeight.bold),
                ),
                if (showWorkstationId)
                   Text(
                    'PUESTO ${event.workstationId.split('-').last.toUpperCase()}',
                    style: const TextStyle(color: AppColors.white10, fontSize: AppDimensions.fontXxs, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'AHORA';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    return DateFormat('HH:mm').format(dt);
  }
}
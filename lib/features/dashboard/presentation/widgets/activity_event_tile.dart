import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';

class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;
  final bool showWorkstationId;

  const ActivityEventTile({
    required this.event,
    this.showWorkstationId = true,
    super.key,
  });

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceSecondary = context.appOnSurfaceSecondary;
    final glassBorder = context.appGlassBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(color: glassBorder.withValues(alpha: 0.02)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: event.state.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                event.state.emoji,
                style: const TextStyle(fontSize: AppDimensions.fontTitle),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingXs,
                            vertical: AppDimensions.spacingXxs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orangeWarning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    '${AppStrings.confidence}: ${(event.confidence * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onSurfaceSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(event.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onSurfaceSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showWorkstationId)
                  Text(
                    '${AppStrings.workstationPrefix} ${event.workstationId.split('-').last.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onSurfaceSecondary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
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
    if (diff.inMinutes < 1) return AppStrings.now;
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    return _timeFmt.format(dt);
  }
}

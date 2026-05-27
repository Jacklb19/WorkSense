import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';

class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;
  final bool showWorkstationId;

  const ActivityEventTile({
    required this.event,
    this.showWorkstationId = true,
    super.key,
  });

  // ✅ Static final — DateFormat instantiated once, not on every _formatTimestamp call.
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        decoration: BoxDecoration(
          color: ac.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ac.divider),
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
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    context.l10n.confidenceLabel((event.confidence * 100).round()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ac.textDisabled,
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
                  _formatTimestamp(event.timestamp, context.l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ac.textDisabled,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showWorkstationId)
                  Text(
                    context.l10n.workstationShort(event.workstationId.split('-').last.toUpperCase()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ac.textDisabled.withAlpha(40),
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

  String _formatTimestamp(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.nowLabel;
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    return _timeFmt.format(dt);
  }
}

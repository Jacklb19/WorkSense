import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../camera_monitor/presentation/widgets/state_badge_widget.dart';
import '../../presentation/providers/dashboard_provider.dart';

class WorkstationCard extends ConsumerWidget {
  final WorkstationRecord workstation;

  const WorkstationCard({
    required this.workstation,
    super.key,
  });

  static final _timeFmt = DateFormat('HH:mm');
  static final _dateTimeFmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastEvent = ref.watch(lastEventByWorkstationProvider(workstation.id));
    final cardColor = context.appCard;
    final glassBorder = context.appGlassBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        border: Border.all(color: glassBorder.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, AppDimensions.spacingMd),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Semantics(
          button: true,
          label: '${AppStrings.workstationPrefix} ${workstation.name}',
          child: InkWell(
            onTap: () => context.push('/kiosk/${workstation.id}'),
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.cardInnerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingLg),
                      Expanded(
                        child: Text(
                          workstation.name.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (lastEvent != null) ...[
                    StateBadgeWidget(
                      state: lastEvent.state,
                      confidence: lastEvent.confidence,
                      showConfidence: true,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: AppDimensions.iconXxs,
                          color: context.appOnSurfaceSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          _formatTimestamp(lastEvent.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.appOnSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      AppStrings.noRecentActivity,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.appOnSurfaceSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return AppStrings.justNow;
    if (diff.inMinutes < 60) return AppStrings.minutesAgo.replaceAll('\$min', '${diff.inMinutes}');
    if (diff.inHours < 24) {
      return _timeFmt.format(dt);
    }
    return _dateTimeFmt.format(dt);
  }
}
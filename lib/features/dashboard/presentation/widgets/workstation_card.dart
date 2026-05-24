import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../camera_monitor/presentation/widgets/state_badge_widget.dart';
import '../../presentation/providers/dashboard_provider.dart';

class WorkstationCard extends ConsumerWidget {
  final WorkstationRecord workstation;

  const WorkstationCard({
    required this.workstation,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEvent =
        ref.watch(lastEventByWorkstationProvider(workstation.id));
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: InkWell(
          onTap: () => context.push('/kiosk/${workstation.id}'),
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
                        color: AppColors.primary.withAlpha(20),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXxl),
                      ),
                      child: const Icon(
                        Icons.sensors,
                        color: AppColors.primary,
                        size: AppDimensions.iconMd,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingLg),
                    Expanded(
                      child: Text(
                        workstation.name.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
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
                      const Icon(
                        Icons.access_time,
                        size: AppDimensions.iconXxs,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text(
                        _formatTimestamp(lastEvent.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'SIN ACTIVIDAD RECIENTE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}

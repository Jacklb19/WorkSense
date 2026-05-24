import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/state_badge_widget.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';

class WorkstationCard extends ConsumerWidget {
  final WorkstationRecord workstation;

  const WorkstationCard({
    required this.workstation,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEvent = ref.watch(lastEventByWorkstationProvider(workstation.id));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        child: InkWell(
          onTap: () => context.push('/kiosk/${workstation.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXl),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                      ),
                      child: const Icon(Icons.sensors, color: AppColors.primary, size: AppDimensions.iconMd),
                    ),
                    const SizedBox(width: AppDimensions.spacingLg),
                    Expanded(
                      child: Text(
                        workstation.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppDimensions.fontCaption,
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
                      const Icon(Icons.access_time, size: AppDimensions.iconXxs, color: AppColors.white38),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text(
                        _formatTimestamp(lastEvent.timestamp),
                        style: const TextStyle(color: AppColors.white38, fontSize: AppDimensions.fontXs),
                      ),
                    ],
                  ),
                ] else
                  const Text(
                    'SIN ACTIVIDAD RECIENTE',
                    style: TextStyle(color: AppColors.white24, fontSize: AppDimensions.fontXs, fontWeight: FontWeight.bold),
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
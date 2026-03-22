import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/state_badge_widget.dart';

class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;
  final bool showWorkstationId;

  const ActivityEventTile({
    super.key,
    required this.event,
    this.showWorkstationId = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: event.state.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            event.state.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Row(
        children: [
          StateBadgeWidget(state: event.state),
          const SizedBox(width: 8),
          if (!event.synced)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.syncPending.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.syncPending.withOpacity(0.5)),
              ),
              child: const Text(
                'Pendiente',
                style: TextStyle(
                  color: AppColors.syncPending,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          if (showWorkstationId)
            Text(
              'Puesto: ${event.workstationId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
          Text(
            'Confianza: ${(event.confidence * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
      trailing: Text(
        _formatTimestamp(event.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.grey500,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return DateFormat('HH:mm').format(dt);
    return DateFormat('dd/MM').format(dt);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: event.state.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(event.state.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 16),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!event.synced)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('OFFLINE', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONFIANZA: ${(event.confidence * 100).round()}%',
                    style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(event.timestamp),
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                if (showWorkstationId)
                   Text(
                    'PUESTO ${event.workstationId.split('-').last.toUpperCase()}',
                    style: const TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.bold),
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

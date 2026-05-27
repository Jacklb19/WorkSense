import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.showDelete = false,
    this.onDelete,
  });

  final Announcement announcement;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = context.appColors;
    final readIds = ref.watch(readAnnouncementIdsProvider).value ?? {};
    final isRead = readIds.contains(announcement.id);
    final user = ref.watch(currentUserProvider).value;

    return Card(
      color: ac.card,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead
              ? AppColors.glassBorder
              : announcement.priority.color.withValues(alpha: 0.6),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isRead && user != null) {
            ref
                .read(announcementsNotifierProvider.notifier)
                .markRead(announcement.id);
          }
          _showDetail(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PriorityBadge(priority: announcement.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontWeight:
                            isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: announcement.priority.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (showDelete) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                style: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 12, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(announcement.createdAt),
                    style: const TextStyle(
                      color: AppColors.grey400,
                      fontSize: 11,
                    ),
                  ),
                  if (announcement.expiresAt != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.event_busy, size: 12, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      '${context.l10n.announcementExpires} ${_fmtDate(announcement.expiresAt!)}',
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => _AnnouncementDetail(
          announcement: announcement,
          scrollController: controller,
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Priority badge ────────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final AnnouncementPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priority.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, color: priority.color, size: 12),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail sheet ──────────────────────────────────────────────────────────────

class _AnnouncementDetail extends StatelessWidget {
  const _AnnouncementDetail({
    required this.announcement,
    required this.scrollController,
  });

  final Announcement announcement;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PriorityBadge(priority: announcement.priority),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmtDate(announcement.createdAt),
            style: const TextStyle(color: AppColors.grey400, fontSize: 12),
          ),
          if (announcement.expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Vence: ${_fmtDate(announcement.expiresAt!)}',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
          const Divider(height: 24, color: AppColors.glassBorder),
          Text(
            announcement.content,
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

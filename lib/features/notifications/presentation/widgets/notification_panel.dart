import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/notifications/domain/entities/app_notification.dart';
import 'package:worksense_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Bell button ───────────────────────────────────────────────────────────────

class NotificationBellButton extends ConsumerWidget {
  final bool isIconButton; // true = IconButton (AppBar), false = container btn

  const NotificationBellButton({super.key, this.isIconButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(unreadTotalProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        isIconButton
            ? IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notificaciones',
                onPressed: () => _openPanel(context),
              )
            : _ContainerBtn(onTap: () => _openPanel(context)),
        if (total > 0)
          Positioned(
            top: isIconButton ? 6 : 2,
            right: isIconButton ? 6 : 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                total > 99 ? '99+' : '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationSheet(),
    );
  }
}

class _ContainerBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ContainerBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.glassBorder)),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          size: 18,
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final companyId =
        ref.watch(currentUserProvider).valueOrNull?.companyId ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.8),
            ),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .markAllRead(companyId);
                      },
                      child: const Text(
                        'Leer todo',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.glassBorder, height: 1),

              // List
              Expanded(
                child: notifsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                  error: (_, __) => const Center(
                    child: Text('Error cargando notificaciones',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                  ),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return const _EmptyNotifications();
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceDark,
                      onRefresh: () =>
                          ref.read(notificationsProvider.notifier).refresh(),
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppColors.glassBorder,
                          height: 1,
                          indent: 60,
                        ),
                        itemBuilder: (context, i) => _NotificationTile(
                          notification: notifs[i],
                          onTap: () {
                            if (!notifs[i].isRead) {
                              ref
                                  .read(notificationsProvider.notifier)
                                  .markRead(notifs[i].id);
                            }
                            if (notifs[i].route != null &&
                                context.mounted) {
                              Navigator.of(context).pop();
                              context.push(notifs[i].route!);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tile individual ───────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile(
      {required this.notification, required this.onTap});

  static const _typeConfig = {
    'task_assigned':    (Icons.task_alt_rounded,        AppColors.primary),
    'leave_request':    (Icons.event_available_rounded,  AppColors.warning),
    'leave_approved':   (Icons.check_circle_rounded,     AppColors.success),
    'leave_rejected':   (Icons.cancel_rounded,           AppColors.error),
    'message':          (Icons.chat_bubble_outline_rounded, AppColors.secondary),
    'announcement':     (Icons.campaign_rounded,          AppColors.accent),
    'general':          (Icons.notifications_rounded,    AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[notification.type] ??
        _typeConfig['general']!;
    final icon = cfg.$1;
    final color = cfg.$2;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 13,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                      color: AppColors.grey400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin notificaciones',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

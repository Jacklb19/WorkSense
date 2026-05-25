import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/chat/data/chat_repository.dart';
import 'package:worksense_app/features/notifications/data/notification_repository.dart';
import 'package:worksense_app/features/notifications/domain/entities/app_notification.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Lista de notificaciones ───────────────────────────────────────────────────

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  Timer? _timer;

  @override
  Future<List<AppNotification>> build() async {
    // Auto-refresh cada 30 s mientras el usuario está autenticado
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final isLoggedIn =
          ref.read(currentUserProvider).valueOrNull?.user != null;
      if (isLoggedIn) refresh();
    });
    ref.onDispose(() => _timer?.cancel());

    return _fetch();
  }

  Future<List<AppNotification>> _fetch() =>
      NotificationRepository.instance.fetchMine();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markRead(String id) async {
    await NotificationRepository.instance.markRead(id);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((n) => n.id == id
              ? AppNotification(
                  id: n.id,
                  companyId: n.companyId,
                  recipientId: n.recipientId,
                  toRole: n.toRole,
                  senderId: n.senderId,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  route: n.route,
                  createdAt: n.createdAt,
                )
              : n)
          .toList(),
    );
  }

  Future<void> markAllRead(String companyId) async {
    await NotificationRepository.instance.markAllRead(companyId);
    await refresh();
  }
}

// ── Conteo no leídos (notificaciones + mensajes) ──────────────────────────────

final unreadTotalProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  final unreadNotifs = notifications.where((n) => !n.isRead).length;
  final unreadMsgs = ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;
  return unreadNotifs + unreadMsgs;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});

// ── Conteo de mensajes no leídos ──────────────────────────────────────────────

final unreadMessagesCountProvider =
    AsyncNotifierProvider<UnreadMsgsNotifier, int>(UnreadMsgsNotifier.new);

class UnreadMsgsNotifier extends AsyncNotifier<int> {
  Timer? _timer;

  @override
  Future<int> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final userId =
          ref.read(currentUserProvider).valueOrNull?.user?.id;
      if (userId != null) refresh();
    });
    ref.onDispose(() => _timer?.cancel());
    return _count();
  }

  Future<int> _count() async {
    final userId = ref.read(currentUserProvider).valueOrNull?.user?.id;
    if (userId == null) return 0;
    return ChatRepository.instance.countUnread(userId);
  }

  Future<void> refresh() async {
    state = AsyncData(await _count());
  }
}

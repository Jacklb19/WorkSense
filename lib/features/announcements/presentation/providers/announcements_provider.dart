import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/repositories/announcement_repository_impl.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/domain/repositories/announcement_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/services/notification_service.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return AnnouncementRepositoryImpl(db, syncRepo);
});

// ── Stream providers ──────────────────────────────────────────────────────────

/// All active announcements for the current company (admin + employee).
final companyAnnouncementsProvider =
    StreamProvider<List<Announcement>>((ref) {
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) return const Stream.empty();

  return ref
      .watch(announcementRepositoryProvider)
      .watchByCompany(companyId)
      .map((list) => list.where((a) => a.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
});

/// IDs of announcements already read by the current user.
final readAnnouncementIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(currentUserProvider).valueOrNull?.user?.id;
  if (userId == null) return {};
  return ref.watch(announcementRepositoryProvider).getReadIds(userId);
});

/// Count of unread announcements for the current user.
final unreadAnnouncementsCountProvider = Provider<int>((ref) {
  final all = ref.watch(companyAnnouncementsProvider).value ?? [];
  final readIds = ref.watch(readAnnouncementIdsProvider).value ?? {};
  return all.where((a) => !readIds.contains(a.id)).length;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class AnnouncementsNotifier extends StateNotifier<AsyncValue<void>> {
  AnnouncementsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final AnnouncementRepository _repo;
  final Ref _ref;

  Future<void> create({
    required String title,
    required String content,
    required AnnouncementPriority priority,
    DateTime? expiresAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _ref.read(currentUserProvider).value;
      final companyId = currentUser?.companyId;
      final userId = currentUser?.user?.id;
      if (companyId == null || userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final announcement = Announcement(
        id: const Uuid().v4(),
        companyId: companyId,
        authorId: userId,
        title: title,
        content: content,
        priority: priority,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await _repo.save(announcement);

      // Trigger local notification
      await NotificationService.instance.notifyAnnouncement(title);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markRead(String announcementId) async {
    final userId = _ref.read(currentUserProvider).valueOrNull?.user?.id;
    if (userId == null) return;
    await _repo.markRead(announcementId, userId);
    // Invalidate the read-ids cache
    _ref.invalidate(readAnnouncementIdsProvider);
  }
}

final announcementsNotifierProvider =
    StateNotifierProvider<AnnouncementsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return AnnouncementsNotifier(repo, ref);
});

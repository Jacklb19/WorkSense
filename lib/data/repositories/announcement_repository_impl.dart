import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/domain/repositories/announcement_repository.dart';
import 'sync_repository_impl.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  AnnouncementRepositoryImpl(this._db, this._syncRepo);

  @override
  Stream<List<Announcement>> watchByCompany(String companyId) =>
      _db.watchAnnouncementsByCompany(companyId)
          .map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<List<Announcement>> getByCompany(String companyId) async {
    final rows = await _db.getAnnouncementsByCompany(companyId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> save(Announcement a) async {
    await _db.transaction(() async {
      await _db.insertAnnouncement(AnnouncementRecordsCompanion(
        id: Value(a.id),
        companyId: Value(a.companyId),
        authorId: Value(a.authorId),
        title: Value(a.title),
        content: Value(a.content),
        priority: Value(a.priority.raw),
        createdAt: Value(a.createdAt),
        expiresAt: Value(a.expiresAt),
      ));

      await _syncRepo.enqueue(
        targetTable: 'announcements',
        operation: 'UPSERT',
        recordId: a.id,
        payload: a.toMap(),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await _db.deleteAnnouncement(id);
      await _syncRepo.enqueue(
        targetTable: 'announcements',
        operation: 'DELETE',
        recordId: id,
        payload: {},
      );
    });
  }

  @override
  Future<void> markRead(String announcementId, String userId) =>
      _db.markAnnouncementRead(announcementId, userId);

  @override
  Future<Set<String>> getReadIds(String userId) async {
    final rows = await _db.getReadAnnouncements(userId);
    return rows.map((r) => r.announcementId).toSet();
  }

  Announcement _mapToEntity(AnnouncementData row) => Announcement(
        id: row.id,
        companyId: row.companyId,
        authorId: row.authorId,
        title: row.title,
        content: row.content,
        priority: AnnouncementPriority.fromRaw(row.priority),
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
      );
}

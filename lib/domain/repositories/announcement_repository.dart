import 'package:worksense_app/domain/entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Stream<List<Announcement>> watchByCompany(String companyId);
  Future<List<Announcement>> getByCompany(String companyId);
  Future<void> save(Announcement announcement);
  Future<void> delete(String id);
  Future<void> markRead(String announcementId, String userId);
  Future<Set<String>> getReadIds(String userId);
}

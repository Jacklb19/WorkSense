import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.role.canManageUsers ?? false;
    final announcementsAsync = ref.watch(companyAnnouncementsProvider);
    final notifier = ref.read(announcementsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Comunicados',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              tooltip: 'Nuevo comunicado',
              onPressed: () => context.push(AppRoutes.announcementNew),
            ),
        ],
      ),
      body: announcementsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(companyAnnouncementsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final a = list[index];
                return AnnouncementCard(
                  announcement: a,
                  showDelete: isAdmin,
                  onDelete: isAdmin
                      ? () => _confirmDelete(context, ref, notifier, a)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AnnouncementsNotifier notifier,
    Announcement a,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Eliminar comunicado',
            style: TextStyle(color: AppColors.white)),
        content: Text(
          '¿Eliminar "${a.title}"?',
          style: const TextStyle(color: AppColors.grey400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.grey400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) notifier.delete(a.id);
    });
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: AppColors.grey400),
          SizedBox(height: 16),
          Text(
            'Sin comunicados activos',
            style: TextStyle(
              color: AppColors.grey400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los nuevos comunicados aparecerán aquí',
            style: TextStyle(color: AppColors.grey400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.role.canManageUsers ?? false;
    final announcementsAsync = ref.watch(companyAnnouncementsProvider);
    final notifier = ref.read(announcementsNotifierProvider.notifier);

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Comunicados',
          style: TextStyle(color: ac.textPrimary, fontWeight: FontWeight.bold),
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
            return const AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'Sin comunicados activos',
              subtitle: 'Los nuevos comunicados aparecerán aquí',
            );
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
        backgroundColor: context.appColors.card,
        title: Text('Eliminar comunicado',
            style: TextStyle(color: context.appColors.textPrimary)),
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


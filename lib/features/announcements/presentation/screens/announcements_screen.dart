import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.role.canManageUsers ?? false;
    final announcementsAsync = ref.watch(companyAnnouncementsProvider);
    final notifier = ref.read(announcementsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text(
          'Comunicados',
          style: TextStyle(color: context.appOnSurface, fontWeight: FontWeight.bold),
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
            child: AppContentConstrainer(
              width: AppContentWidth.list,
              child: ListView.builder(
              padding: const EdgeInsets.only(top: AppDimensions.spacingMd, bottom: AppDimensions.spacing80),
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
        backgroundColor: context.appCard,
        title: Text('Eliminar comunicado',
            style: TextStyle(color: context.appOnSurface)),
        content: Text(
          '¿Eliminar "${a.title}"?',
          style: TextStyle(color: context.appOnSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: context.appOnSurfaceSecondary)),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: context.appOnSurfaceDisabled),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'Sin comunicados activos',
            style: TextStyle(
              color: context.appOnSurfaceSecondary,
              fontSize: AppDimensions.fontTitle,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Los nuevos comunicados aparecerán aquí',
            style: TextStyle(color: context.appOnSurfaceDisabled, fontSize: AppDimensions.fontBody),
          ),
        ],
      ),
    );
  }
}
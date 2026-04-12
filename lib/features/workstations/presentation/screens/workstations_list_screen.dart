import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/avatar_initials.dart';
import 'package:worksense_app/shared/widgets/confidence_bar.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/async_value_widget.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';

class WorkstationsListScreen extends ConsumerWidget {
  const WorkstationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Workstations', style: theme.textTheme.titleMedium),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/workstations/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: theme.textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Count subtitle ─────────────────────────
          workstationsAsync.when(
            data: (ws) {
              final active = ws.where((w) => w.assignedEmployeeId != null).length;
              final unoccupied = ws.length - active;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$active active · $unoccupied unoccupied',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── List ───────────────────────────────────
          Expanded(
            child: workstationsAsync.when(
              loading: () => const AppLoadingWidget(),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error: $err',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (workstations) {
                if (workstations.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noWorkstationsRegistered,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: workstations.length,
                  itemBuilder: (context, index) {
                    final ws = workstations[index];
                    final hasAssignment = ws.assignedEmployeeId != null;
                    final initials = hasAssignment
                        ? (ws.assignedEmployeeId!.length >= 2
                            ? ws.assignedEmployeeId!
                                .substring(0, 2)
                                .toUpperCase()
                            : 'EE')
                        : '—';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: WsCard(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            // Status indicator bar
                            Container(
                              width: 4,
                              height: 64,
                              decoration: BoxDecoration(
                                color: hasAssignment
                                    ? AppColors.stateWorking
                                    : AppColors.borderColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: AppRadius.lg,
                                  bottomLeft: AppRadius.lg,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AvatarInitials(
                              initials: initials,
                              bg: hasAssignment
                                  ? AppColors.primaryDark
                                  : AppColors.elevated,
                              size: 32,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ws.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    hasAssignment
                                        ? 'Assigned'
                                        : 'Unoccupied',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: hasAssignment
                                          ? AppColors.textSecondary
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete action
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, ref, ws.id, ws.name),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Text(AppStrings.deleteWorkstation),
        content: Text('¿Seguro que deseas eliminar la estación "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      try {
        await ref.read(deleteWorkstationUseCaseProvider)(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.workstationDeleted)),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

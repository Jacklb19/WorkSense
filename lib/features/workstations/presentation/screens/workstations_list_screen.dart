import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/workstation.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/widgets/async_value_widget.dart';

class WorkstationsListScreen extends ConsumerWidget {
  const WorkstationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsProvider);

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          context.l10n.workstations,
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AsyncValueWidget(
        value: workstationsAsync,
        builder: (workstations) {
          if (workstations.isEmpty) {
            return const _EmptyWorkstations();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: workstations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ws = workstations[index];
              return _WorkstationCard(
                workstation: ws,
                onEdit: () => context.push(
                  AppRoutes.workstationEdit
                      .replaceFirst(':workstationId', ws.id),
                ),
                onDelete: () => _confirmDelete(context, ref, ws.id, ws.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.workstationNew),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.newWorkstationShort),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        title: Text(
          ctx.l10n.deleteWorkstation,
          style: TextStyle(color: ctx.appColors.textPrimary),
        ),
        content: Text(
          '${ctx.l10n.confirmDeleteWs} "$name"?',
          style: TextStyle(color: ctx.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(deleteWorkstationUseCaseProvider)(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.workstationDeleted)),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Workstation Card ───────────────────────────────────────────────────────────
// ✅ StatelessWidget consistente con el sistema glassmorphism del resto del app.

class _WorkstationCard extends StatelessWidget {
  final Workstation workstation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkstationCard({
    required this.workstation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final status = workstation.status ?? 'IDLE';
    final statusColor = status == 'ACTIVE'
        ? AppColors.stateWorking
        : status == 'BREAK'
            ? AppColors.warning
            : ac.textSecondary;

    return Semantics(
      label: 'Estación de trabajo: ${workstation.name}, estado: $status',
      child: Material(
        color: ac.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                // ── Icono de estado ──────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.desktop_mac_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workstation.name,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workstation.deviceId != null
                            ? 'Device: ${workstation.deviceId}'
                            : 'Sin dispositivo asignado',
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Badge de estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Acciones ─────────────────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Editar ${workstation.name}',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Editar',
                        onPressed: onEdit,
                      ),
                    ),
                    Semantics(
                      label: 'Eliminar ${workstation.name}',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error.withValues(alpha: 0.8),
                        ),
                        tooltip: 'Eliminar',
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyWorkstations extends StatelessWidget {
  const _EmptyWorkstations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.desktop_mac_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noWorkstationsReg,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

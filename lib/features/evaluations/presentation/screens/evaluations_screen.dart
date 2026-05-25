import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final role = userState.valueOrNull?.role;
    final isAdmin = role?.canManageUsers ?? false;

    return isAdmin
        ? const _AdminEvaluationsView()
        : const _EmployeeEvaluationsView();
  }
}

// ── Admin view ─────────────────────────────────────────────────────────────────

class _AdminEvaluationsView extends ConsumerWidget {
  const _AdminEvaluationsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalsAsync = ref.watch(companyEvaluationsProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Evaluaciones',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondaryDark),
            onPressed: () => ref.read(companyEvaluationsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.evaluationNew),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva evaluación'),
      ),
      body: evalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (evals) {
          if (evals.isEmpty) {
            return const _EmptyEvals(
              message: 'Sin evaluaciones aún.\nCrea la primera evaluación con el botón +',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: evals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final eval = evals[i];
              final emp = empMap[eval.employeeId];
              return _EvalCard(
                eval: eval,
                employeeName: emp?.displayName ?? eval.employeeId,
                isAdmin: true,
                onTap: () => context.push(
                  AppRoutes.evaluationDetail.replaceFirst(':evalId', eval.id),
                ),
                onDelete: () => _confirmDelete(context, ref, eval),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Evaluation eval,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Eliminar evaluación?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(companyEvaluationsProvider.notifier).delete(eval.id);
    }
  }
}

// ── Employee view ──────────────────────────────────────────────────────────────

class _EmployeeEvaluationsView extends ConsumerWidget {
  const _EmployeeEvaluationsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalsAsync = ref.watch(myEvaluationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Mis Evaluaciones',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: evalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (evals) {
          if (evals.isEmpty) {
            return const _EmptyEvals(
              message: 'Aún no tienes evaluaciones de desempeño.\nComunícate con tu supervisor.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: evals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final eval = evals[i];
              return _EvalCard(
                eval: eval,
                employeeName: null,
                isAdmin: false,
                onTap: () => context.push(
                  AppRoutes.evaluationDetail.replaceFirst(':evalId', eval.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Shared card ────────────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  final Evaluation eval;
  final String? employeeName;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _EvalCard({
    required this.eval,
    required this.employeeName,
    required this.isAdmin,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy', 'es');
    final color = eval.gradeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Grade badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  eval.grade,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin && employeeName != null)
                    Text(
                      employeeName!,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    eval.period,
                    style: TextStyle(
                      color: isAdmin
                          ? AppColors.textSecondaryDark
                          : AppColors.textPrimaryDark,
                      fontSize: isAdmin ? 12 : 14,
                      fontWeight:
                          isAdmin ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        eval.gradeLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${eval.percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFmt.format(eval.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
                if (isAdmin && onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyEvals extends StatelessWidget {
  final String message;

  const _EmptyEvals({required this.message});

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
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
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

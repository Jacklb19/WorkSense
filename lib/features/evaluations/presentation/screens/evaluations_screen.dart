import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
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
    final ac = context.appColors;
    final evalsAsync = ref.watch(companyEvaluationsProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          context.l10n.evaluations,
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: ac.textSecondary),
            onPressed: () => ref.read(companyEvaluationsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.evaluationNew),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.newEvaluation),
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
        backgroundColor: ctx.appColors.surface,
        title: Text(
          '¿Eliminar evaluación?',
          style: TextStyle(color: ctx.appColors.textPrimary),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: ctx.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(ctx.l10n.delete),
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
    final ac = context.appColors;
    final evalsAsync = ref.watch(myEvaluationsProvider);

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          'Mis Evaluaciones',
          style: TextStyle(
            color: ac.textPrimary,
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

  // ✅ DateFormat como static final — se crea UNA sola vez, no en cada build().
  static final _dateFmt = DateFormat('dd MMM yyyy', 'es');

  const _EvalCard({
    required this.eval,
    required this.employeeName,
    required this.isAdmin,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = eval.gradeColor;

    // ✅ Material + InkWell en lugar de GestureDetector:
    //    - Ripple visual al tocar (feedback táctil)
    //    - Semantics de botón propagados automáticamente por InkWell
    final ac = context.appColors;
    return Semantics(
      label: isAdmin && employeeName != null
          ? 'Evaluación de $employeeName, período ${eval.period}, calificación ${eval.gradeLabel}'
          : 'Evaluación del período ${eval.period}, calificación ${eval.gradeLabel}',
      button: true,
      child: Material(
        color: ac.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
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
                          style: TextStyle(
                            color: ac.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        eval.period,
                        style: TextStyle(
                          color: isAdmin
                              ? ac.textSecondary
                              : ac.textPrimary,
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
                            style: TextStyle(
                              color: ac.textSecondary,
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
                      _dateFmt.format(eval.createdAt),
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (isAdmin && onDelete != null)
                      // ✅ IconButton en lugar de GestureDetector:
                      //    zona táctil de 48x48 automática + Semantics + tooltip
                      Semantics(
                        label: 'Eliminar evaluación',
                        button: true,
                        child: IconButton(
                          onPressed: onDelete,
                          padding: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error.withValues(alpha: 0.7),
                          ),
                          tooltip: 'Eliminar evaluación',
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

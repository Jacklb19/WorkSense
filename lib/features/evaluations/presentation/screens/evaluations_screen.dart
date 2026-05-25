import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

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
    final theme = Theme.of(context);
    final evalsAsync = ref.watch(companyEvaluationsProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'Evaluaciones',
          style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.appOnSurfaceSecondary),
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
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
        ),
        data: (evals) {
          if (evals.isEmpty) {
            return const _EmptyEvals(
              message: 'Sin evaluaciones aún.\nCrea la primera evaluación con el botón +',
            );
          }
          return AppContentConstrainer(
            width: AppContentWidth.list,
            child: ListView.separated(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: evals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingXl),
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
          ),
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
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(
          '¿Eliminar evaluación?',
          style: theme.textTheme.titleMedium?.copyWith(color: ctx.appOnSurface),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: theme.textTheme.bodyMedium?.copyWith(color: ctx.appOnSurfaceSecondary),
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
    final theme = Theme.of(context);
    final evalsAsync = ref.watch(myEvaluationsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'Mis Evaluaciones',
          style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface),
        ),
      ),
      body: evalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
        ),
        data: (evals) {
          if (evals.isEmpty) {
            return const _EmptyEvals(
              message: 'Aún no tienes evaluaciones de desempeño.\nComunícate con tu supervisor.',
            );
          }
          return AppContentConstrainer(
            width: AppContentWidth.list,
            child: ListView.separated(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            itemCount: evals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingXl),
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
          ),
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
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy', 'es');
    final color = eval.gradeColor;

    return Semantics(
      button: true,
      label: 'Ver evaluación ${eval.period}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: context.appGlassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    eval.grade,
                    style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin && employeeName != null)
                      Text(
                        employeeName!,
                        style: theme.textTheme.labelLarge?.copyWith(color: context.appOnSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      eval.period,
                      style: TextStyle(
                        color: isAdmin
                            ? context.appOnSurfaceSecondary
                            : context.appOnSurface,
                        fontSize: isAdmin ? AppDimensions.fontCaption : AppDimensions.fontBodyMd,
                        fontWeight:
                            isAdmin ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Row(
                      children: [
                        Text(
                          eval.gradeLabel,
                          style: theme.textTheme.labelMedium?.copyWith(color: color),
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Text(
                          '${eval.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: context.appOnSurfaceSecondary,
                            fontSize: AppDimensions.fontSm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFmt.format(eval.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary),
                  ),
                  if (isAdmin && onDelete != null)
                    Semantics(
                      button: true,
                      label: 'Eliminar evaluación',
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(AppDimensions.spacingXs),
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.star_rounded,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
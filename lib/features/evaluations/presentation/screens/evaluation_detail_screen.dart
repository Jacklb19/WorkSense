import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class EvaluationDetailScreen extends ConsumerWidget {
  final String evalId;

  const EvaluationDetailScreen({super.key, required this.evalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync = ref.watch(evaluationDetailProvider(evalId));
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    return evalAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.appBackground,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.appBackground,
        body: Center(
          child: Text('Error: $e',
              style: TextStyle(color: AppColors.error)),
        ),
      ),
      data: (eval) {
        if (eval == null) {
          return Scaffold(
            backgroundColor: context.appBackground,
            appBar: AppBar(
              backgroundColor: context.appSurface,
              title: const Text('Evaluación'),
            ),
            body: Center(
              child: Text('Evaluación no encontrada',
                  style: TextStyle(color: context.appOnSurfaceSecondary)),
            ),
          );
        }

        final emp = empMap[eval.employeeId];
        final employeeName = emp?.displayName ?? eval.employeeId;
        final dateFmt = DateFormat('dd MMMM yyyy', 'es');

        return Scaffold(
          backgroundColor: context.appBackground,
          appBar: AppBar(
            backgroundColor: context.appSurface,
            title: Text(
              'Evaluación – ${eval.period}',
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.w700,
                fontSize: AppDimensions.fontTitle,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, AppDimensions.spacing20, 16, 40),
            child: AppContentConstrainer(
              width: AppContentWidth.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradeHero(eval: eval, employeeName: employeeName),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  _MetaRow(
                      icon: Icons.person_rounded,
                      label: 'Empleado',
                      value: employeeName),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _MetaRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Fecha',
                      value: dateFmt.format(eval.createdAt)),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _MetaRow(
                      icon: Icons.date_range_rounded,
                      label: 'Período',
                      value: eval.period),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  const _SectionTitle(title: 'DESGLOSE POR CRITERIO'),
                  const SizedBox(height: AppDimensions.spacingLg),
                  ...eval.criteria.map((c) {
                    final score = eval.scores[c.name] ?? 0;
                    final pct =
                        c.maxScore > 0 ? score / c.maxScore : 0.0;
                    return _CriterionRow(
                      criterion: c,
                      score: score,
                      pct: pct,
                    );
                  }),

                  if (eval.notes != null && eval.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingXxl),
                    const _SectionTitle(title: 'NOTAS DEL EVALUADOR'),
                    const SizedBox(height: AppDimensions.spacingXl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingXl),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                        border: Border.all(color: context.appGlassBorder),
                      ),
                      child: Text(
                        eval.notes!,
                        style: TextStyle(
                          color: context.appOnSurfaceSecondary,
                          fontSize: AppDimensions.fontBody,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Grade hero ─────────────────────────────────────────────────────────────────

class _GradeHero extends StatelessWidget {
  final Evaluation eval;
  final String employeeName;

  const _GradeHero({required this.eval, required this.employeeName});

  @override
  Widget build(BuildContext context) {
    final color = eval.gradeColor;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            context.appSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                eval.grade,
                style: TextStyle(
                  color: color,
                  fontSize: AppDimensions.fontDisplay,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXxl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.gradeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: AppDimensions.fontTitleLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  '${eval.percentage.toStringAsFixed(1)}% de desempeño',
                  style: TextStyle(
                    color: context.appOnSurfaceSecondary,
                    fontSize: AppDimensions.fontBody,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: LinearProgressIndicator(
                    value: eval.percentage / 100,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  '${eval.totalScore.toStringAsFixed(0)} / ${eval.maxScore.toStringAsFixed(0)} puntos',
                  style: TextStyle(
                    color: context.appOnSurfaceSecondary,
                    fontSize: AppDimensions.fontSm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Criterion row ──────────────────────────────────────────────────────────────

class _CriterionRow extends StatelessWidget {
  final EvaluationCriterion criterion;
  final double score;
  final double pct;

  const _CriterionRow({
    required this.criterion,
    required this.score,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final color = pct >= 0.9
        ? AppColors.success
        : pct >= 0.7
            ? AppColors.primary
            : pct >= 0.5
                ? AppColors.warning
                : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                criterion.name,
                style: TextStyle(
                  color: context.appOnSurface,
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)} / ${criterion.maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontSize: AppDimensions.fontCaption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta row ───────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.spacingXxl, color: context.appOnSurfaceSecondary),
        const SizedBox(width: AppDimensions.spacingMd),
        Text(
          '$label: ',
          style: TextStyle(
            color: context.appOnSurfaceSecondary,
            fontSize: AppDimensions.fontBody,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: AppDimensions.fontBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: context.appOnSurfaceSecondary,
        fontSize: AppDimensions.fontSm,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
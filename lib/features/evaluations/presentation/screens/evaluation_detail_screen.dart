import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';

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
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (eval) {
        if (eval == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceDark,
              title: const Text('Evaluación'),
            ),
            body: const Center(
              child: Text('Evaluación no encontrada',
                  style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
          );
        }

        final emp = empMap[eval.employeeId];
        final employeeName = emp?.displayName ?? eval.employeeId;
        final dateFmt = DateFormat('dd MMMM yyyy', 'es');

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            title: Text(
              'Evaluación – ${eval.period}',
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Grade card ────────────────────────────────────
                _GradeHero(eval: eval, employeeName: employeeName),
                const SizedBox(height: 24),

                // ── Meta ──────────────────────────────────────────
                _MetaRow(
                    icon: Icons.person_rounded,
                    label: 'Empleado',
                    value: employeeName),
                const SizedBox(height: 8),
                _MetaRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Fecha',
                    value: dateFmt.format(eval.createdAt)),
                const SizedBox(height: 8),
                _MetaRow(
                    icon: Icons.date_range_rounded,
                    label: 'Período',
                    value: eval.period),
                const SizedBox(height: 24),

                // ── Criteria breakdown ────────────────────────────
                const _SectionTitle(title: 'DESGLOSE POR CRITERIO'),
                const SizedBox(height: 12),
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

                // ── Notes ─────────────────────────────────────────
                if (eval.notes != null && eval.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'NOTAS DEL EVALUADOR'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      eval.notes!,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            AppColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                eval.grade,
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.gradeLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${eval.percentage.toStringAsFixed(1)}% de desempeño',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: eval.percentage / 100,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${eval.totalScore.toStringAsFixed(0)} / ${eval.maxScore.toStringAsFixed(0)} puntos',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                criterion.name,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)} / ${criterion.maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
        Icon(icon, size: 16, color: AppColors.textSecondaryDark),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 13,
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
      style: const TextStyle(
        color: AppColors.textSecondaryDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

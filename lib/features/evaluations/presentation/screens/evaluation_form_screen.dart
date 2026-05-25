import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  const EvaluationFormScreen({super.key});

  @override
  ConsumerState<EvaluationFormScreen> createState() =>
      _EvaluationFormScreenState();
}

class _EvaluationFormScreenState
    extends ConsumerState<EvaluationFormScreen> {
  final _periodCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedEmployeeId;
  final Map<String, double> _scores = {};
  bool _saving = false;

  final List<EvaluationCriterion> _criteria = List.from(defaultCriteria);

  @override
  void initState() {
    super.initState();
    for (final c in _criteria) {
      _scores[c.name] = 0;
    }
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalScore =>
      _scores.values.fold(0.0, (sum, s) => sum + s);
  double get _maxScore =>
      _criteria.fold(0.0, (sum, c) => sum + c.maxScore);

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final employees = (employeesAsync.valueOrNull ?? [])
        .where((e) => e.role == AppRole.employee)
        .toList();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'Nueva Evaluación',
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: _canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Guardar'),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: AppContentConstrainer(
          width: AppContentWidth.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: 'Empleado'),
              const SizedBox(height: AppDimensions.spacingMd),
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                dropdownColor: context.appSurface,
                decoration: _inputDeco(context, 'Seleccionar empleado'),
                style: TextStyle(color: context.appOnSurface),
                items: employees.map((e) {
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text(e.displayName),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
              const SizedBox(height: AppDimensions.spacing20),
              const _SectionHeader(title: 'Período'),
              const SizedBox(height: AppDimensions.spacingMd),
              TextField(
                controller: _periodCtrl,
                style: TextStyle(color: context.appOnSurface),
                decoration: _inputDeco(context, 'Ej: Enero 2026, Q1 2026…'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              const _SectionHeader(title: 'Criterios de evaluación'),
              const SizedBox(height: AppDimensions.spacingXs),
              _ScorePreview(
                total: _totalScore,
                max: _maxScore,
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              ..._criteria.map((c) => _CriterionSlider(
                    criterion: c,
                    value: _scores[c.name] ?? 0,
                    onChanged: (v) {
                      setState(() => _scores[c.name] = v);
                    },
                  )),
              const SizedBox(height: AppDimensions.spacing20),
              const _SectionHeader(title: 'Notas (opcional)'),
              const SizedBox(height: AppDimensions.spacingMd),
              TextField(
                controller: _notesCtrl,
                style: TextStyle(color: context.appOnSurface),
                decoration: _inputDeco(context, 'Observaciones, recomendaciones…'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave =>
      _selectedEmployeeId != null && _periodCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final companyId = currentUser?.companyId ?? '';
    final reviewerId = currentUser?.user?.id ?? '';
    if (companyId.isEmpty) return;

    setState(() => _saving = true);

    final eval = Evaluation(
      id: const Uuid().v4(),
      companyId: companyId,
      employeeId: _selectedEmployeeId!,
      reviewerId: reviewerId,
      period: _periodCtrl.text.trim(),
      criteria: _criteria,
      scores: Map.from(_scores),
      totalScore: _totalScore,
      maxScore: _maxScore,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final error =
        await ref.read(companyEvaluationsProvider.notifier).save(eval);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDeco(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: context.appOnSurfaceSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          borderSide: BorderSide(color: context.appGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          borderSide: BorderSide(color: context.appGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

// ── Criterion slider ───────────────────────────────────────────────────────────

class _CriterionSlider extends StatelessWidget {
  final EvaluationCriterion criterion;
  final double value;
  final ValueChanged<double> onChanged;

  const _CriterionSlider({
    required this.criterion,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = criterion.maxScore > 0 ? value / criterion.maxScore : 0.0;
    final color = pct >= 0.9
        ? AppColors.success
        : pct >= 0.7
            ? AppColors.primary
            : pct >= 0.5
                ? AppColors.warning
                : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXxl),
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.radiusXl, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)} / ${criterion.maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: AppDimensions.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: AppDimensions.radiusLg),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: criterion.maxScore,
              divisions: criterion.maxScore.toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score preview ──────────────────────────────────────────────────────────────

class _ScorePreview extends StatelessWidget {
  final double total;
  final double max;

  const _ScorePreview({required this.total, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? total / max : 0.0;
    final color = pct >= 0.9
        ? AppColors.success
        : pct >= 0.7
            ? AppColors.primary
            : pct >= 0.5
                ? AppColors.warning
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: color, size: AppDimensions.spacing20),
          const SizedBox(width: AppDimensions.spacingXl),
          Text(
            'Puntaje total: ',
            style: TextStyle(
              color: context.appOnSurfaceSecondary,
              fontSize: AppDimensions.fontBody,
            ),
          ),
          Text(
            '${total.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: AppDimensions.fontBodyMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: AppDimensions.fontTitleLg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: context.appOnSurfaceSecondary,
        fontSize: AppDimensions.fontSm,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
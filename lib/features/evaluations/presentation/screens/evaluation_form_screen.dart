import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  const EvaluationFormScreen({super.key});

  @override
  ConsumerState<EvaluationFormScreen> createState() =>
      _EvaluationFormScreenState();
}

class _EvaluationFormScreenState
    extends ConsumerState<EvaluationFormScreen> {
  final _periodCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
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

  bool get _canSave =>
      _selectedEmployeeId != null && _periodCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final employees = (employeesAsync.valueOrNull ?? [])
        .where((e) => e.role == AppRole.employee)
        .toList();

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        // ✅ Explicit leading button — uses context.pop() (go_router aware)
        //    so the navigation state never desyncs.
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: ac.textPrimary, size: 20),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nueva Evaluación',
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
                    child: Text(context.l10n.save),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Employee selector ────────────────────────────────
            const _SectionHeader(title: 'Empleado'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedEmployeeId,
              dropdownColor: ac.surface,
              decoration: _inputDeco('Seleccionar empleado', ac),
              style: TextStyle(color: ac.textPrimary),
              hint: Text(
                'Seleccionar empleado',
                style: TextStyle(color: ac.textSecondary),
              ),
              items: employees.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(
                    e.displayName,
                    style: TextStyle(color: ac.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedEmployeeId = v),
            ),
            const SizedBox(height: 20),

            // ── Period ───────────────────────────────────────────
            const _SectionHeader(title: 'Período'),
            const SizedBox(height: 8),
            TextField(
              controller: _periodCtrl,
              style: TextStyle(color: ac.textPrimary),
              decoration: _inputDeco('Ej: Enero 2026, Q1 2026…', ac),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── Score preview ────────────────────────────────────
            const _SectionHeader(title: 'Criterios de evaluación'),
            const SizedBox(height: 8),
            _ScorePreview(total: _totalScore, max: _maxScore),
            const SizedBox(height: 12),

            // ── Criteria sliders ─────────────────────────────────
            ..._criteria.map((c) => _CriterionSlider(
                  criterion: c,
                  value: _scores[c.name] ?? 0,
                  onChanged: (v) => setState(() => _scores[c.name] = v),
                )),
            const SizedBox(height: 20),

            // ── Notes ────────────────────────────────────────────
            const _SectionHeader(title: 'Notas (opcional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              style: TextStyle(color: ac.textPrimary),
              decoration: _inputDeco('Observaciones, recomendaciones…', ac),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final period = _periodCtrl.text.trim();
    if (_selectedEmployeeId == null || period.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final companyId  = currentUser?.companyId ?? '';
    final reviewerId = currentUser?.user?.id   ?? '';

    if (companyId.isEmpty) {
      _showError('No se pudo determinar tu empresa. Cierra sesión e intenta de nuevo.');
      return;
    }

    setState(() => _saving = true);

    final eval = Evaluation(
      id:         const Uuid().v4(),
      companyId:  companyId,
      employeeId: _selectedEmployeeId!,
      reviewerId: reviewerId,
      period:     period,
      criteria:   List.from(_criteria),
      scores:     Map.from(_scores),
      totalScore: _totalScore,
      maxScore:   _maxScore,
      notes:      _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
      createdAt:  DateTime.now(),
    );

    final error =
        await ref.read(companyEvaluationsProvider.notifier).save(eval);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _showError('Error al guardar: $error');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Evaluación guardada correctamente.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // ✅ context.pop() — go_router aware; keeps navigation state in sync.
      context.pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDeco(String hint, AppThemeColors ac) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: ac.textSecondary.withValues(alpha: 0.5)),
        filled: true,
        fillColor: ac.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                criterion.name,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)} / ${criterion.maxScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:   color,
              thumbColor:         color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              overlayColor:       color.withValues(alpha: 0.1),
              trackHeight:        4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            'Puntaje total: ',
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            '${total.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 18,
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
        color: context.appColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

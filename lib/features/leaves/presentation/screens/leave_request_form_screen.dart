import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class LeaveRequestFormScreen extends ConsumerStatefulWidget {
  const LeaveRequestFormScreen({super.key});

  @override
  ConsumerState<LeaveRequestFormScreen> createState() =>
      _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState
    extends ConsumerState<LeaveRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _type = LeaveType.personal;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          'SOLICITAR PERMISO',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: ac.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu solicitud será revisada por un administrador.',
                        style:
                            TextStyle(color: AppColors.info, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tipo ───────────────────────────────────────────────────
              const _SectionLabel('Tipo de permiso'),
              const SizedBox(height: 10),
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),

              const SizedBox(height: 24),

              // ── Fechas ─────────────────────────────────────────────────
              const _SectionLabel('Período de ausencia'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Desde',
                      value: _startDate,
                      onTap: () => _pickDate(context, isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Hasta',
                      value: _endDate,
                      onTap: () => _pickDate(context, isStart: false),
                    ),
                  ),
                ],
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_endDate!.difference(_startDate!).inDays + 1} día(s) de permiso',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),

              // ── Motivo ─────────────────────────────────────────────────
              const _SectionLabel('Motivo (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                style: TextStyle(color: ac.textPrimary),
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Explica brevemente el motivo…',
                  hintStyle: TextStyle(color: ac.textDisabled),
                  filled: true,
                  fillColor: ac.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  counterStyle:
                      TextStyle(color: ac.textDisabled),
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : () => _submit(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enviar solicitud',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));

    final firstDate = isStart ? DateTime.now() : (_startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectAbsencePeriod),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;

    // Guard: both employeeId and companyId are required for Supabase RLS.
    // If either is missing the insert would fail silently downstream.
    final employeeId = user?.user?.id ?? '';
    final companyId = user?.companyId ?? '';

    if (employeeId.isEmpty || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo determinar tu empresa. '
            'Cierra sesión, vuelve a entrar e intenta de nuevo.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final now = DateTime.now();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final request = LeaveRequest(
      id: const Uuid().v4(),
      employeeId: employeeId,
      companyId: companyId,
      type: _type,
      status: LeaveStatus.pending,
      startDate: _startDate!,
      endDate: _endDate!,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await ref
        .read(leavesNotifierProvider.notifier)
        .submitRequest(request);

    if (!mounted) return;
    setState(() => _loading = false);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada. Espera la respuesta del administrador.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final LeaveType selected;
  final ValueChanged<LeaveType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: LeaveType.values.map((t) {
            final isSelected = t == selected;
            return SizedBox(
              width: tileWidth,
              child: Material(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : context.appColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(t),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.glassBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon,
                            size: 16,
                            color: isSelected ? AppColors.primary : context.appColors.textDisabled),
                        const SizedBox(width: 8),
                        Text(
                          t.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : context.appColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value != null ? AppColors.primary : AppColors.glassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: context.appColors.textDisabled, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                value != null
                    ? _dateFmt.format(value!)
                    : 'Seleccionar',
                style: TextStyle(
                  color: value != null ? context.appColors.textPrimary : context.appColors.textDisabled,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

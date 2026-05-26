import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

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
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: const Text(
          'SOLICITAR PERMISO',
          style: TextStyle(
            color: AppColors.white,
            fontSize: AppDimensions.fontSubtitle,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacing20),
        child: AppContentConstrainer(
          width: AppContentWidth.form,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoBanner(),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildTypeSelector(),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildDatePeriodSection(),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildReasonField(),
                const SizedBox(height: AppDimensions.spacing32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18),
          SizedBox(width: AppDimensions.spacingXl),
          Expanded(
            child: Text(
              'Tu solicitud será revisada por un administrador.',
              style: TextStyle(color: AppColors.info, fontSize: AppDimensions.fontCaption),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Tipo de permiso'),
        const SizedBox(height: AppDimensions.spacingXl),
        _TypeSelector(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
      ],
    );
  }

  Widget _buildDatePeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Período de ausencia'),
        const SizedBox(height: AppDimensions.spacingXl),
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Desde',
                value: _startDate,
                onTap: () => _pickDate(context, isStart: true),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
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
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            '${_endDate!.difference(_startDate!).inDays + 1} día(s) de permiso',
            style: const TextStyle(
                color: AppColors.primary, fontSize: AppDimensions.fontCaption),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Motivo (opcional)'),
        const SizedBox(height: AppDimensions.spacingMd),
        TextFormField(
          controller: _reasonController,
          style: const TextStyle(color: AppColors.white),
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Explica brevemente el motivo…',
            hintStyle: const TextStyle(color: AppColors.white38),
            filled: true,
            fillColor: context.appSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              borderSide: BorderSide(color: context.appGlassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              borderSide: BorderSide(color: context.appGlassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            counterStyle: const TextStyle(color: AppColors.white38),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : () => _submit(context),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
        ),
        child: _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            : const Text(
                'Enviar solicitud',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: AppDimensions.fontSubtitle),
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
        const SnackBar(
          content: Text('Selecciona el período de ausencia'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    final now = DateTime.now();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final request = LeaveRequest(
      id: const Uuid().v4(),
      employeeId: user?.user?.id ?? '',
      companyId: user?.companyId ?? '',
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
      style: const TextStyle(
        color: AppColors.white70,
        fontSize: AppDimensions.fontCaption,
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.spacingXl,
      mainAxisSpacing: AppDimensions.spacingXl,
      childAspectRatio: 3,
      children: LeaveType.values.map((t) {
        final isSelected = t == selected;
        return Semantics(
          button: true,
          label: t.label,
          child: InkWell(
            onTap: () => onChanged(t),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : context.appSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.appGlassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.icon,
                      size: AppDimensions.spacingXxl,
                      color: isSelected ? AppColors.primary : AppColors.white38),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimensions.fontBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Seleccionar fecha $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            border: Border.all(
              color: value != null ? AppColors.primary : context.appGlassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.white38, fontSize: AppDimensions.fontXs),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                value != null
                    ? DateFormat('dd/MM/yyyy').format(value!)
                    : 'Seleccionar',
                style: TextStyle(
                  color: value != null ? AppColors.white : AppColors.white38,
                  fontSize: AppDimensions.fontBody,
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
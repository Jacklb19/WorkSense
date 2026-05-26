import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() =>
      _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState
    extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  DateTime? _expiresAt;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(announcementsNotifierProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            priority: _priority,
            expiresAt: _expiresAt,
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Comunicado publicado'),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text(
          'Nuevo comunicado',
          style: TextStyle(color: context.appOnSurface, fontWeight: FontWeight.bold),
        ),
        leading: BackButton(
          color: context.appOnSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppContentConstrainer(
        width: AppContentWidth.form,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing20),
            children: [
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Título'),
        const SizedBox(height: AppDimensions.spacingSm),
        TextFormField(
          controller: _titleCtrl,
          maxLength: 100,
          style: TextStyle(color: context.appOnSurface),
          decoration: _inputDecoration('Ej: Reunión obligatoria mañana'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: AppDimensions.spacingXxl),

        const _SectionLabel('Contenido'),
        const SizedBox(height: AppDimensions.spacingSm),
        TextFormField(
          controller: _contentCtrl,
          maxLines: 5,
          maxLength: 1000,
          style: TextStyle(color: context.appOnSurface),
          decoration: _inputDecoration('Detalle del comunicado...'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: AppDimensions.spacingXxl),

        const _SectionLabel('Prioridad'),
        const SizedBox(height: AppDimensions.spacingMd),
        _PrioritySelector(
          selected: _priority,
          onChanged: (p) => setState(() => _priority = p),
        ),
        const SizedBox(height: AppDimensions.spacing20),

        const _SectionLabel('Fecha de vencimiento (opcional)'),
        const SizedBox(height: AppDimensions.spacingSm),
        Semantics(
          button: true,
          label: 'Seleccionar fecha de vencimiento',
          child: InkWell(
            onTap: _pickExpiry,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                border: Border.all(color: context.appGlassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _expiresAt == null
                          ? 'Sin vencimiento'
                          : '${_expiresAt!.day.toString().padLeft(2, '0')}/'
                              '${_expiresAt!.month.toString().padLeft(2, '0')}/'
                              '${_expiresAt!.year}',
                      style: TextStyle(
                        color: _expiresAt == null
                            ? context.appOnSurfaceDisabled
                            : context.appOnSurface,
                      ),
                    ),
                  ),
                  if (_expiresAt != null)
                    Semantics(
                      button: true,
                      label: 'Limpiar fecha de vencimiento',
                      child: InkWell(
                        onTap: () => setState(() => _expiresAt = null),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        child: const Icon(Icons.clear,
                            color: AppColors.grey400, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing32),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    'Publicar comunicado',
                    style: TextStyle(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontTitle,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appOnSurfaceDisabled),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        counterStyle: TextStyle(color: context.appOnSurfaceDisabled),
      );
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  final AnnouncementPriority selected;
  final ValueChanged<AnnouncementPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spacingMd,
      runSpacing: AppDimensions.spacingMd,
      children: AnnouncementPriority.values.map((p) {
        final isSelected = p == selected;
        return Semantics(
          button: true,
          label: 'Prioridad: ${p.label}',
          child: InkWell(
            onTap: () => onChanged(p),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? p.color.withValues(alpha: 0.2)
                    : context.appSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(
                  color: isSelected ? p.color : context.appGlassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon,
                      color: isSelected ? p.color : context.appOnSurfaceDisabled,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected ? p.color : context.appOnSurfaceDisabled,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appOnSurface,
        fontWeight: FontWeight.w600,
        fontSize: AppDimensions.fontBodyMd,
      ),
    );
  }
}
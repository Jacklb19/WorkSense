import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';

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
    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Nuevo comunicado',
          style: TextStyle(color: ac.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: BackButton(
          color: ac.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ──────────────────────────────────────────────────────────
        const _SectionLabel('Título'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleCtrl,
          maxLength: 100,
          style: TextStyle(color: ac.textPrimary),
          decoration: _inputDecoration('Ej: Reunión obligatoria mañana', ac: ac),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),

        // ── Content ────────────────────────────────────────────────────────
        const _SectionLabel('Contenido'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _contentCtrl,
          maxLines: 5,
          maxLength: 1000,
          style: TextStyle(color: ac.textPrimary),
          decoration: _inputDecoration('Detalle del comunicado...', ac: ac),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),

        // ── Priority ───────────────────────────────────────────────────────
        const _SectionLabel('Prioridad'),
        const SizedBox(height: 8),
        _PrioritySelector(
          selected: _priority,
          onChanged: (p) => setState(() => _priority = p),
        ),
        const SizedBox(height: 20),

        // ── Expiry ─────────────────────────────────────────────────────────
        const _SectionLabel('Fecha de vencimiento (opcional)'),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickExpiry,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: ac.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
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
                          ? AppColors.grey400
                          : ac.textPrimary,
                    ),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(Icons.clear,
                        color: AppColors.grey400, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // ── Submit ─────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                : const Text(
                    'Publicar comunicado',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {required AppThemeColors ac}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey400),
        filled: true,
        fillColor: ac.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        counterStyle: const TextStyle(color: AppColors.grey400),
      );
}

// ── Priority selector ─────────────────────────────────────────────────────────

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  final AnnouncementPriority selected;
  final ValueChanged<AnnouncementPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnnouncementPriority.values.map((p) {
        final isSelected = p == selected;
        return Material(
          color: isSelected
              ? p.color.withValues(alpha: 0.2)
              : ac.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => onChanged(p),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? p.color : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon,
                      color: isSelected ? p.color : AppColors.grey400,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected ? p.color : AppColors.grey400,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
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

// ── Helper ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/date_row.dart';

class NewPeriodDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const NewPeriodDialog({super.key, required this.ref});

  @override
  ConsumerState<NewPeriodDialog> createState() => _NewPeriodDialogState();
}

class _NewPeriodDialogState extends ConsumerState<NewPeriodDialog> {
  final _nameCtrl = TextEditingController();
  DateTime _start = DateTime.now().copyWith(day: 1);
  DateTime _end   = DateTime.now();
  bool _loading   = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end   = DateTime(now.year, now.month + 1, 0);
    _nameCtrl.text =
        DateFormat('MMMM yyyy', 'es').format(now);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
      title: Text('Nuevo período de nómina',
          style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurface),
            decoration: InputDecoration(
              labelText: 'Nombre del período',
              labelStyle:
                  theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
              filled: true,
              fillColor: context.appCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          DateRow(
            label: 'Desde',
            date: _start,
            onPick: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _start = d);
            },
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          DateRow(
            label: 'Hasta',
            date: _end,
            onPick: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _end,
                firstDate: _start,
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _end = d);
            },
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            '${dateFmt.format(_start)} – ${dateFmt.format(_end)}',
            style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white),
                )
              : const Text('Calcular y crear'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final err = await ref.read(payrollPeriodsProvider.notifier).createPeriod(
          name:      name,
          startDate: _start,
          endDate:   _end,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Período creado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

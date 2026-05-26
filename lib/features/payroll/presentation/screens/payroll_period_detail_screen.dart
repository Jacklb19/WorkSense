import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/data/payroll_repository.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';


class PayrollPeriodDetailScreen extends ConsumerStatefulWidget {
  final String periodId;
  final PayrollPeriod period;

  const PayrollPeriodDetailScreen({
    super.key,
    required this.periodId,
    required this.period,
  });

  @override
  ConsumerState<PayrollPeriodDetailScreen> createState() =>
      _PayrollPeriodDetailScreenState();
}

class _PayrollPeriodDetailScreenState
    extends ConsumerState<PayrollPeriodDetailScreen> {
  final _currFmt = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('dd/MM/yyyy', 'es');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(payrollEntriesProvider(widget.periodId));
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final Map<String, Employee> empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    final period = widget.period;
    final isDraft = period.status == PayrollStatus.draft;
    final isApproved = period.status == PayrollStatus.approved;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period.name,
              style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w700),
            ),
            Text(
              '${_dateFmt.format(period.startDate)} – ${_dateFmt.format(period.endDate)}',
              style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary),
            ),
          ],
        ),
        actions: [
          if (isDraft)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
              child: FilledButton(
                onPressed: () => _confirmStatusChange(
                  context,
                  'Aprobar período',
                  '¿Aprobar este período de nómina? Los empleados serán notificados.',
                  PayrollStatus.approved,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
                ),
                child: Text('Aprobar', style: theme.textTheme.bodyLarge),
              ),
            ),
          if (isApproved)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
              child: FilledButton(
                onPressed: () => _confirmStatusChange(
                  context,
                  'Marcar como pagado',
                  '¿Confirmar el pago de este período?',
                  PayrollStatus.paid,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
                ),
                child: Text('Marcar pagado', style: theme.textTheme.bodyLarge),
              ),
            ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
        ),
        data: (entries) {
          return Column(
            children: [
              _SummaryBanner(
                period: period,
                entries: entries,
                currFmt: _currFmt,
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'Sin entradas en este período',
                          style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingXl, horizontal: AppDimensions.spacingXxl),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
                        itemBuilder: (ctx, i) {
                          final entry = entries[i];
                          final emp = empMap[entry.employeeId];
                          return _EntryCard(
                            entry: entry,
                            employee: emp,
                            currFmt: _currFmt,
                            isDraft: isDraft,
                            onEditDeductions: isDraft
                                ? () => _editDeductions(ctx, entry)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    String title,
    String message,
    PayrollStatus newStatus,
  ) async {
    final nav = Navigator.of(context);
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(title,
            style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
        content: Text(message,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(payrollPeriodsProvider.notifier)
          .updateStatus(widget.periodId, newStatus);
      if (mounted) nav.pop();
    }
  }

  Future<void> _editDeductions(BuildContext ctx, PayrollEntry entry) async {
    final theme = Theme.of(context);
    final ctrl = TextEditingController(
      text: entry.deductions > 0 ? entry.deductions.toStringAsFixed(0) : '',
    );
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: context.appSurface,
title: Text(
            'Editar deducciones',
            style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface),
          ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          style: TextStyle(color: context.appOnSurface),
          decoration: const InputDecoration(
            labelText: 'Deducción (COP)',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final amount = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
      await PayrollRepository.instance
          .updateEntryDeductions(entry.id, amount);
      ref.invalidate(payrollEntriesProvider(widget.periodId));
    }
  }
}

// ── Summary Banner ─────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final PayrollPeriod period;
  final List<PayrollEntry> entries;
  final NumberFormat currFmt;

  const _SummaryBanner({
    required this.period,
    required this.entries,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalNet =
        entries.fold<double>(0, (s, e) => s + e.netPay);
    final totalDed =
        entries.fold<double>(0, (s, e) => s + e.deductions);
    final totalHours =
        entries.fold<double>(0, (s, e) => s + e.hoursWorked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
            bottom: BorderSide(color: context.appGlassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Empleados',
            value: '${entries.length}',
            color: AppColors.primary,
            icon: Icons.people_rounded,
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          _Stat(
            label: 'Hrs totales',
            value: totalHours.toStringAsFixed(1),
            color: AppColors.secondary,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          _Stat(
            label: 'Deducciones',
            value: currFmt.format(totalDed),
            color: AppColors.warning,
            icon: Icons.remove_circle_outline_rounded,
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          _Stat(
            label: 'Pago neto',
            value: currFmt.format(totalNet),
            color: AppColors.success,
            icon: Icons.attach_money_rounded,
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingSm),
            decoration: BoxDecoration(
              color: period.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                  color: period.status.color.withValues(alpha: 0.3)),
            ),
            child: Text(
              period.status.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: period.status.color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.spacingXxl, color: color),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXxs),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: AppDimensions.fontBody,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Entry Card ─────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final PayrollEntry entry;
  final Employee? employee;
  final NumberFormat currFmt;
  final bool isDraft;
  final VoidCallback? onEditDeductions;

  const _EntryCard({
    required this.entry,
    required this.employee,
    required this.currFmt,
    required this.isDraft,
    this.onEditDeductions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = employee?.displayName ?? entry.employeeId;
    final initials = (employee != null)
        ? '${employee!.name.isNotEmpty ? employee!.name[0] : ''}${employee!.lastName.isNotEmpty ? employee!.lastName[0] : ''}'
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: context.appGlassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.labelLarge?.copyWith(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Row(
                  children: [
                    _MiniStat(
                      label: '${entry.hoursWorked.toStringAsFixed(1)} hrs',
                      icon: Icons.schedule,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingXl),
                    _MiniStat(
                      label: '${currFmt.format(entry.hourlyRate)}/hr',
                      icon: Icons.attach_money,
                      color: AppColors.primary,
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
                currFmt.format(entry.netPay),
                style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w800),
              ),
              if (entry.deductions > 0)
                Text(
                  '- ${currFmt.format(entry.deductions)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
              if (isDraft)
                Semantics(
                  button: true,
                  label: 'Editar deducciones',
                  child: InkWell(
                    onTap: onEditDeductions,
                    borderRadius: BorderRadius.circular(AppDimensions.spacingXs),
                    child: const Padding(
                      padding: EdgeInsets.only(top: AppDimensions.spacingXs),
                      child: Text(
                        'Editar ded.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppDimensions.fontXs,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.spacingXxl, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: AppDimensions.spacingSm),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary),
        ),
      ],
    );
  }
}
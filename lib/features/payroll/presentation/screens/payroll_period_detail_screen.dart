import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/data/payroll_repository.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
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
    final entriesAsync = ref.watch(payrollEntriesProvider(widget.periodId));
    final employeesAsync = ref.watch(adminEmployeesProvider);

    final Map<String, Employee> empMap = {
      for (final e in (employeesAsync.valueOrNull ?? [])) e.id: e,
    };

    final period = widget.period;
    final isDraft = period.status == PayrollStatus.draft;
    final isApproved = period.status == PayrollStatus.approved;

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period.name,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_dateFmt.format(period.startDate)} – ${_dateFmt.format(period.endDate)}',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (isDraft)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: () => _confirmStatusChange(
                  context,
                  'Aprobar período',
                  '¿Aprobar este período de nómina? Los empleados serán notificados.',
                  PayrollStatus.approved,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Aprobar', style: TextStyle(fontSize: 13)),
              ),
            ),
          if (isApproved)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: () => _confirmStatusChange(
                  context,
                  'Marcar como pagado',
                  '¿Confirmar el pago de este período?',
                  PayrollStatus.paid,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Marcar pagado', style: TextStyle(fontSize: 13)),
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
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (entries) {
          return Column(
            children: [
              // ── Summary banner ─────────────────────────────────────
              _SummaryBanner(
                period: period,
                entries: entries,
                currFmt: _currFmt,
              ),
              // ── Entries list ───────────────────────────────────────
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'Sin entradas en este período',
                          style: TextStyle(color: ac.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    // Capture navigator before any async gap
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        title: Text(title,
            style: TextStyle(color: ctx.appColors.textPrimary)),
        content: Text(message,
            style: TextStyle(color: ctx.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.confirm),
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
    final ctrl = TextEditingController(
      text: entry.deductions > 0 ? entry.deductions.toStringAsFixed(0) : '',
    );
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: dlgCtx.appColors.surface,
        title: Text(
          'Editar deducciones',
          style: TextStyle(color: dlgCtx.appColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          style: TextStyle(color: dlgCtx.appColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Deducción (COP)',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(dlgCtx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(dlgCtx.l10n.save),
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
    final totalNet =
        entries.fold<double>(0, (s, e) => s + e.netPay);
    final totalDed =
        entries.fold<double>(0, (s, e) => s + e.deductions);
    final totalHours =
        entries.fold<double>(0, (s, e) => s + e.hoursWorked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(
            bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Empleados',
            value: '${entries.length}',
            color: AppColors.primary,
            icon: Icons.people_rounded,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: 'Hrs totales',
            value: totalHours.toStringAsFixed(1),
            color: AppColors.secondary,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: 'Deducciones',
            value: currFmt.format(totalDed),
            color: AppColors.warning,
            icon: Icons.remove_circle_outline_rounded,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: 'Pago neto',
            value: currFmt.format(totalNet),
            color: AppColors.success,
            icon: Icons.attach_money_rounded,
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: period.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: period.status.color.withValues(alpha: 0.3)),
            ),
            child: Text(
              period.status.label.toUpperCase(),
              style: TextStyle(
                color: period.status.color,
                fontSize: 10,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
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
    final name = employee?.displayName ?? entry.employeeId;
    final initials = (employee != null)
        ? '${employee!.name.isNotEmpty ? employee!.name[0] : ''}${employee!.lastName.isNotEmpty ? employee!.lastName[0] : ''}'
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStat(
                      label: '${entry.hoursWorked.toStringAsFixed(1)} hrs',
                      icon: Icons.schedule,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
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
          // Pay info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currFmt.format(entry.netPay),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (entry.deductions > 0)
                Text(
                  '- ${currFmt.format(entry.deductions)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                  ),
                ),
              if (isDraft)
                InkWell(
                  onTap: onEditDeductions,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text(
                      'Editar ded.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        decoration: TextDecoration.underline,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

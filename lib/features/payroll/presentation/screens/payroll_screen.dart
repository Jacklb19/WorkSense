import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

final _currFmt = NumberFormat.currency(
  locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(payrollPeriodsProvider);

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Text(
          'NÓMINA',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: ac.textSecondary),
            tooltip: 'Configurar tarifas',
            onPressed: () => _openRatesConfig(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: periodsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e', style: TextStyle(color: ac.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(payrollPeriodsProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (periods) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: ac.surface,
          onRefresh: () => ref.read(payrollPeriodsProvider.notifier).refresh(),
          child: periods.isEmpty
              ? _EmptyState(onCreateTap: () => _showNewPeriodDialog(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: periods.length,
                  itemBuilder: (_, i) => _PeriodCard(period: periods[i]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPeriodDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newPeriod),
      ),
    );
  }

  // ── Dialogo nuevo período ───────────────────────────────────────────────────

  void _showNewPeriodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _NewPeriodDialog(ref: ref),
    );
  }

  // ── Config de tarifas ───────────────────────────────────────────────────────

  void _openRatesConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RatesConfigSheet(),
    );
  }
}

// ── Card de período ────────────────────────────────────────────────────────────

class _PeriodCard extends ConsumerWidget {
  final PayrollPeriod period;
  const _PeriodCard({required this.period});

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final ac = context.appColors;
    return Material(
      color: ac.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.payrollPeriod.replaceFirst(':periodId', period.id),
          extra: period,
        ),
        onLongPress: period.status == PayrollStatus.draft
            ? () => _confirmDelete(context, ref)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    period.name,
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(status: period.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_dateFmt.format(period.startDate)} – ${_dateFmt.format(period.endDate)}',
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.glassBorder, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.people_outline,
                  label: '${period.employeeCount} empleados',
                ),
                const Spacer(),
                Text(
                  _currFmt.format(period.totalGross),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Eliminar período',
            style: TextStyle(color: context.appColors.textPrimary)),
        content: Text('¿Eliminar "${period.name}"?',
            style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(payrollPeriodsProvider.notifier).deletePeriod(period.id);
    }
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final PayrollStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ac.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: ac.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined,
              size: 64, color: context.appColors.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Sin períodos de nómina',
            style: TextStyle(color: context.appColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea el primer período para calcular\nla nómina de tu equipo.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.appColors.textDisabled, fontSize: 12),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('Crear período'),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo nuevo período ─────────────────────────────────────────────────────

class _NewPeriodDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _NewPeriodDialog({required this.ref});

  @override
  ConsumerState<_NewPeriodDialog> createState() => _NewPeriodDialogState();
}

class _NewPeriodDialogState extends ConsumerState<_NewPeriodDialog> {
  final _nameCtrl = TextEditingController();
  DateTime _start = DateTime.now().copyWith(day: 1);
  DateTime _end   = DateTime.now();
  bool _loading   = false;
  // ✅ Static finals — DateFormats instantiated once, not on every build/initState.
  static final _dateFmt      = DateFormat('dd/MM/yyyy');
  static final _monthYearFmt = DateFormat('MMMM yyyy', 'es');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end   = DateTime(now.year, now.month + 1, 0); // last day of month
    _nameCtrl.text =
        _monthYearFmt.format(now);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AlertDialog(
      backgroundColor: ac.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Nuevo período de nómina',
          style: TextStyle(color: ac.textPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: ac.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nombre del período',
              labelStyle:
                  TextStyle(color: ac.textSecondary),
              filled: true,
              fillColor: ac.card,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          _DateRow(
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
          const SizedBox(height: 8),
          _DateRow(
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
          const SizedBox(height: 8),
          Text(
            '${_dateFmt.format(_start)} – ${_dateFmt.format(_end)}',
            style: TextStyle(
                color: ac.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
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

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;
  const _DateRow({required this.label, required this.date, required this.onPick});

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label,
              style: TextStyle(
                  color: ac.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Material(
            color: ac.card,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _dateFmt.format(date),
                      style: TextStyle(
                          color: ac.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Config de tarifas (bottom sheet) ─────────────────────────────────────────

class _RatesConfigSheet extends ConsumerWidget {
  const _RatesConfigSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync   = ref.watch(payrollConfigsProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: ctx.appColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Tarifas por hora',
                      style: TextStyle(
                          color: ctx.appColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder),
            Expanded(
              child: configsAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('$e',
                        style: TextStyle(
                            color: ctx.appColors.textSecondary))),
                data: (configs) {
                  final workers = (employeesAsync.valueOrNull ?? [])
                      .where((e) => e.role == AppRole.employee)
                      .toList();

                  if (workers.isEmpty) {
                    return Center(
                      child: Text('Sin empleados registrados',
                          style: TextStyle(
                              color: ctx.appColors.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: workers.length,
                    itemBuilder: (_, i) {
                      final emp = workers[i];
                      final cfg = configs
                          .where((c) => c.employeeId == emp.id)
                          .firstOrNull;
                      return _RateTile(
                          employee: emp,
                          config: cfg,
                          onSave: (rate) async {
                            final updated = PayrollConfig(
                              id: cfg?.id ??
                                  const Uuid().v4(),
                              employeeId: emp.id,
                              companyId:  emp.companyId,
                              hourlyRate: rate,
                              updatedAt:  DateTime.now(),
                            );
                            await ref
                                .read(payrollConfigsProvider.notifier)
                                .upsert(updated);
                          });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateTile extends StatefulWidget {
  final Employee employee;
  final PayrollConfig? config;
  final Future<void> Function(double rate) onSave;

  const _RateTile({
    required this.employee,
    required this.config,
    required this.onSave,
  });

  @override
  State<_RateTile> createState() => _RateTileState();
}

class _RateTileState extends State<_RateTile> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.config != null
          ? widget.config!.hourlyRate.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            radius: 20,
            child: Text(
              widget.employee.displayName.isNotEmpty
                  ? widget.employee.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.displayName,
                  style: TextStyle(
                      color: context.appColors.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('\$ / hora',
                    style: TextStyle(
                        color: context.appColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.appColors.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    TextStyle(color: context.appColors.textDisabled),
                filled: true,
                fillColor: context.appColors.card,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _saving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                  onPressed: () async {
                    final rate =
                        double.tryParse(_ctrl.text.trim()) ?? 0;
                    if (rate < 0) return;
                    setState(() => _saving = true);
                    await widget.onSave(rate);
                    if (mounted) setState(() => _saving = false);
                  },
                ),
        ],
      ),
    );
  }
}

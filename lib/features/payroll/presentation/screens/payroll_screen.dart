import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

final _currFmt = NumberFormat.currency(
  locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final periodsAsync = ref.watch(payrollPeriodsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          'NÓMINA',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.appOnSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.appOnSurfaceSecondary),
            tooltip: 'Configurar tarifas',
            onPressed: () => _openRatesConfig(context, ref),
          ),
          const SizedBox(width: AppDimensions.spacingXs),
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
              const SizedBox(height: AppDimensions.spacingLg),
              Text('Error: $e', style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
              const SizedBox(height: AppDimensions.spacingXxl),
              FilledButton(
                onPressed: () => ref.read(payrollPeriodsProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (periods) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: context.appSurface,
          onRefresh: () => ref.read(payrollPeriodsProvider.notifier).refresh(),
          child: periods.isEmpty
              ? _EmptyState(onCreateTap: () => _showNewPeriodDialog(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXxl, AppDimensions.spacingXxl, 100),
                  itemCount: periods.length,
                  itemBuilder: (_, i) => _PeriodCard(period: periods[i]),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPeriodDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo período'),
      ),
    );
  }

  void _showNewPeriodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _NewPeriodDialog(ref: ref),
    );
  }

  void _openRatesConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const _RatesConfigSheet(),
    );
  }
}

// ── Card de período ────────────────────────────────────────────────────────────

class _PeriodCard extends ConsumerWidget {
  final PayrollPeriod period;
  const _PeriodCard({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Semantics(
      button: true,
      label: 'Ver detalle de período ${period.name}',
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.payrollPeriod.replaceFirst(':periodId', period.id),
          extra: period,
        ),
        onLongPress: period.status == PayrollStatus.draft
            ? () => _confirmDelete(context, ref)
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            border: Border.all(color: context.appGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      period.name,
                      style: theme.textTheme.titleSmall?.copyWith(color: context.appOnSurface, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StatusBadge(status: period.status),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                '${dateFmt.format(period.startDate)} – ${dateFmt.format(period.endDate)}',
                style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Divider(color: context.appGlassBorder, height: 1),
              const SizedBox(height: AppDimensions.spacingLg),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${period.employeeCount} empleados',
                  ),
                  const Spacer(),
                  Text(
                    _currFmt.format(period.totalGross),
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
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
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Eliminar período',
            style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
        content: Text('¿Eliminar "${period.name}"?',
            style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(color: status.color, fontWeight: FontWeight.w700),
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.spacingXxl, color: context.appOnSurfaceSecondary),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary)),
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
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined,
              size: 64, color: context.appOnSurfaceDisabled),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'Sin períodos de nómina',
            style: theme.textTheme.titleSmall?.copyWith(color: context.appOnSurfaceSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Crea el primer período para calcular\nla nómina de tu equipo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceDisabled),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
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
            style: TextStyle(color: context.appOnSurface),
            decoration: InputDecoration(
              labelText: 'Nombre del período',
              labelStyle:
                  TextStyle(color: context.appOnSurfaceSecondary),
              filled: true,
              fillColor: context.appCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
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
          const SizedBox(height: AppDimensions.spacingMd),
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

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;
  const _DateRow({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
        Expanded(
          child: Semantics(
            button: true,
            label: 'Seleccionar fecha $label',
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: context.appCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurface),
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
    final theme = Theme.of(context);
    final configsAsync   = ref.watch(payrollConfigsProvider);
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusPill)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.appGlassBorder,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.spacing20, AppDimensions.spacingXxl, AppDimensions.spacing20, AppDimensions.spacingMd),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined,
                      color: AppColors.primary, size: AppDimensions.spacing20),
                  const SizedBox(width: AppDimensions.spacingXl),
                  Text('Tarifas por hora',
                      style: theme.textTheme.titleMedium?.copyWith(color: context.appOnSurface)),
                ],
              ),
            ),
            Divider(color: context.appGlassBorder),
            Expanded(
              child: configsAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('$e',
                        style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary))),
                data: (configs) {
                  final workers = (employeesAsync.valueOrNull ?? [])
                      .where((e) => e.role == AppRole.employee)
                      .toList();

                  if (workers.isEmpty) {
                    return Center(
                      child: Text('Sin empleados registrados',
                          style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary)),
                    );
                  }

                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(AppDimensions.spacingXxl),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            radius: AppDimensions.spacing20,
            child: Text(
              widget.employee.displayName.isNotEmpty
                  ? widget.employee.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.displayName,
                  style: theme.textTheme.labelLarge?.copyWith(color: context.appOnSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('\$ / hora',
                    style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.appOnSurface, fontSize: AppDimensions.fontBody),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    TextStyle(color: context.appOnSurfaceDisabled),
                filled: true,
                fillColor: context.appCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingMd),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
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
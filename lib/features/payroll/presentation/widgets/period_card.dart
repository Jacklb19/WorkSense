import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/info_chip.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/status_badge.dart';

final _currFmt = NumberFormat.currency(
    locale: 'es_CO', symbol: '\$', decimalDigits: 0);

class PeriodCard extends ConsumerWidget {
  final PayrollPeriod period;
  const PeriodCard({super.key, required this.period});

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
                  StatusBadge(status: period.status),
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
                  InfoChip(
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
            child: Text('Eliminar',
                style: theme.textTheme.labelLarge?.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(payrollPeriodsProvider.notifier).deletePeriod(period.id);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/empty_state.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/new_period_dialog.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/period_card.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/rates_config_sheet.dart';

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
              ? EmptyState(onCreateTap: () => _showNewPeriodDialog(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.spacingXxl, AppDimensions.spacingXxl, AppDimensions.spacingXxl, 100),
                  itemCount: periods.length,
                  itemBuilder: (_, i) => PeriodCard(period: periods[i]),
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
      builder: (_) => NewPeriodDialog(ref: ref),
    );
  }

  void _openRatesConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const RatesConfigSheet(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/app_role.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:worksense_app/features/payroll/presentation/widgets/rate_tile.dart';

class RatesConfigSheet extends ConsumerWidget {
  const RatesConfigSheet({super.key});

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
                  const Icon(Icons.payments_outlined,
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
                      return RateTile(
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

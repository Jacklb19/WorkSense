import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/employee_dashboard_card.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncNotifierProvider.notifier).sync();
          ref.invalidate(adminEmployeesProvider);
          ref.invalidate(employeeAnalyticsProvider);
          ref.invalidate(employeeDetailProvider);
          ref.invalidate(employeeAttendanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: Text(
                'Comando central',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                SyncIndicatorWidget(),
                SizedBox(width: AppDimensions.spacingXxl),
              ],
            ),
            employeesAsync.when(
              loading: () =>
                  const SliverFillRemaining(child: AppLoadingWidget()),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorView(error: error.toString()),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyState(icon: Icons.people_outline, title: 'No hay colaboradores', subtitle: 'Registra a tus empleados para administrar su asistencia.', action: FilledButton.icon(onPressed: () => context.push(AppRoutes.employeeNew), icon: const Icon(Icons.add), label: const Text('REGISTRAR EMPLEADO'))),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: AppSpacing.dashboardMaxWidth(context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COLABORADORES',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingMd),
                                Text(
                                  'Tus trabajadores',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = AppSpacing.gridCrossAxisCount(
                            context,
                            mobile: 1,
                            tablet: 2,
                            desktop: 3,
                          );
                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: AppDimensions.gridMainAxisExtent + AppDimensions.spacing20,
                              mainAxisSpacing: AppDimensions.spacingXxl,
                              crossAxisSpacing: AppDimensions.spacingXxl,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  EmployeeDashboardCard(employee: employees[index]),
                              childCount: employees.length,
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.spacing100)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'kiosk_btn',
            onPressed: () {
              context.push(AppRoutes.workstations);
            },
            icon: const Icon(Icons.desktop_windows),
            label: const Text('VER ESTACIONES'),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          FloatingActionButton.extended(
            heroTag: 'entrance_btn',
            onPressed: () => context.push(AppRoutes.entrance),
            icon: const Icon(Icons.meeting_room),
            label: const Text('KIOSCO RECEPCION'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}



class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: AppDimensions.iconEmptyState,
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              AppStrings.errorLoadingData,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.grey500,
                fontSize: AppDimensions.fontCaption,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
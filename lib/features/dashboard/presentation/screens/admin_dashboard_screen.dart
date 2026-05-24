import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../../../shared/providers/sync_state_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/styled/app_empty_state.dart';
import '../../../../shared/widgets/sync_indicator_widget.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../presentation/widgets/employee_dashboard_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email;
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
            SliverAppBar(
              floating: true,
              title: Text(
                'Comando central',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: const [
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
                    child: _EmptyEmployeesView(userEmail: userEmail),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing24,
                      ).copyWith(top: AppDimensions.spacing24),
                      sliver: SliverToBoxAdapter(
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
                    SliverPadding(
                      padding: const EdgeInsets.all(AppDimensions.spacing24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent:
                              AppDimensions.gridMaxCrossAxisExtent,
                          mainAxisExtent: AppDimensions.gridMainAxisExtent,
                          mainAxisSpacing:
                              AppDimensions.gridMainAxisSpacing,
                          crossAxisSpacing:
                              AppDimensions.gridCrossAxisSpacing,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => EmployeeDashboardCard(
                                employee: employees[index],
                              ).animate().fadeIn(
                                    delay: (index * 80).ms,
                                    duration: AppDimensions.animEntrance,
                                  ).slideY(
                                    begin: 0.05,
                                    delay: (index * 80).ms,
                                    duration: AppDimensions.animEntrance,
                                    curve: Curves.easeOutCubic,
                                  ),
                          childCount: employees.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDimensions.spacing100),
                    ),
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

class _EmptyEmployeesView extends ConsumerWidget {
  final String? userEmail;

  const _EmptyEmployeesView({this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppEmptyState(
      icon: Icons.people_outline,
      title: 'No hay colaboradores',
      subtitle: 'Registra a tus empleados para administrar su asistencia.',
      actionLabel: 'REGISTRAR EMPLEADO',
      actionIcon: Icons.add,
      onAction: () => context.push(AppRoutes.employeeNew),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: AppDimensions.iconEmptyState,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              AppStrings.errorLoadingData,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

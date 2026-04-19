import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/workstation_card.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workstationsStreamProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Comando central', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              actions: [
                const SyncIndicatorWidget(),
                IconButton(icon: const Icon(Icons.history), onPressed: () => context.push(AppRoutes.history)),
                IconButton(icon: const Icon(Icons.bar_chart_outlined), onPressed: () => context.push(AppRoutes.analytics)),
                const SizedBox(width: 8),
              ],
            ),
            
            workstationsAsync.when(
              loading: () => const SliverFillRemaining(child: AppLoadingWidget()),
              error: (error, _) => SliverFillRemaining(child: _ErrorView(error: error.toString())),
              data: (workstations) {
                if (workstations.isEmpty) {
                  return SliverFillRemaining(child: _EmptyWorkstationsView(userEmail: userEmail));
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTACIONES ACTIVAS', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text('Supervisión en tiempo real', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisExtent: 180,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => WorkstationCard(workstation: workstations[index]),
                          childCount: workstations.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
              final items = workstationsAsync.valueOrNull ?? [];
              final firstId = items.isNotEmpty ? items.first.id : 'default';
              context.push('/kiosk/$firstId');
            },
            icon: const Icon(Icons.desktop_windows),
            label: const Text('MONITOR PUESTO'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'entrance_btn',
            onPressed: () => context.push(AppRoutes.entrance),
            icon: const Icon(Icons.meeting_room),
            label: const Text('KIOSCO RECEPCIÓN'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final int workstationCount;

  const _DashboardHeader({
    required this.workstationCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.controlPanel,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$workstationCount ${workstationCount == 1 ? 'puesto' : 'puestos'} registrados',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EmptyWorkstationsView extends ConsumerWidget {
  final String? userEmail;

  const _EmptyWorkstationsView({this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monitor_outlined,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noWorkstationsRegistered,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noWorkstationsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/kiosk/default'),
              icon: const Icon(Icons.play_arrow),
              label: const Text(AppStrings.startKioskMode),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.errorLoadingData,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.grey500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/workstation_card.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);
    final theme = Theme.of(context);
    
    final currentUserState = ref.watch(currentUserProvider);
    final userRole = currentUserState.valueOrNull?.role ?? AppRole.employee;
    final canManage = userRole == AppRole.admin || userRole == AppRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkSense'),
        centerTitle: false,
        actions: [
          // Sync indicator
          const SyncIndicatorWidget(),
          const SizedBox(width: 8),

          // History
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de actividad',
            onPressed: () => context.push('/history'),
          ),

          if (canManage) ...[
            // Analytics
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: 'Analíticas',
              onPressed: () => context.push('/analytics'),
            ),
            // Employees
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Empleados',
              onPressed: () => context.push('/employees'),
            ),
            // Workstations
            IconButton(
              icon: const Icon(Icons.computer_outlined),
              tooltip: 'Puestos de Trabajo',
              onPressed: () => context.push('/workstations'),
            ),
          ],

          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: workstationsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => _ErrorView(error: error.toString()),
        data: (workstations) {
          if (workstations.isEmpty) {
            return _EmptyWorkstationsView(
              userEmail: ref.watch(currentUserEmailProvider),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(workstationsStreamProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _DashboardHeader(
                      workstationCount: workstations.length,
                      userEmail: ref.watch(currentUserEmailProvider),
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 160,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => WorkstationCard(
                        workstation: workstations[index],
                      ),
                      childCount: workstations.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: () {
          final items = workstationsAsync.valueOrNull ?? [];
          final firstId = items.isNotEmpty ? items.first.id : 'default';
          context.push('/kiosk/$firstId');
        },
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Iniciar Kiosco'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final int workstationCount;
  final String? userEmail;

  const _DashboardHeader({
    required this.workstationCount,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de Control',
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
            Icon(
              Icons.monitor_outlined,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin puestos registrados',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configura los puestos de trabajo desde\nla consola de administración.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/kiosk/default'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar modo kiosco'),
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
              'Error al cargar datos',
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

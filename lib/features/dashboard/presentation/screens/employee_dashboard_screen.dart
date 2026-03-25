import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/sync_indicator_widget.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(currentUserProvider);
    final userEmail = userState.valueOrNull?.user?.email ?? 'Empleado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Espacio'),
        centerTitle: false,
        actions: [
          const SyncIndicatorWidget(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mi historial global',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(employeeAssignedWorkstationProvider);
          ref.invalidate(employeeTodayAnalyticsProvider);
          // employeeRecentEventsProvider is a stream so it updates automatically
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Hola, $userEmail',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen de tu actividad de hoy',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Assigned Workstation
              const Text(
                'PUESTO ASIGNADO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              const _AssignedWorkstationSection(),
              const SizedBox(height: 24),

              // Section 2: Personal Productivity
              const Text(
                'MI PRODUCTIVIDAD HOY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              const _PersonalProductivitySection(),
              const SizedBox(height: 24),

              // Section 3: Recent Activity Feed
              const Text(
                'ACTIVIDAD RECIENTE (EN VIVO)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              const _RecentActivitySection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assigned Workstation ──────────────────────────────────────────────────────
class _AssignedWorkstationSection extends ConsumerWidget {
  const _AssignedWorkstationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationAsync = ref.watch(employeeAssignedWorkstationProvider);

    return workstationAsync.when(
      loading: () => const AppLoadingWidget(message: 'Verificando puesto...'),
      error: (e, _) => Card(
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Error al cargar la información del puesto.'),
        ),
      ),
      data: (workstation) {
        if (workstation == null) {
          return const _NoWorkstationCard();
        }
        return _WorkstationCard(workstation: workstation);
      },
    );
  }
}

class _NoWorkstationCard extends StatelessWidget {
  const _NoWorkstationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grey300),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.desktop_access_disabled, color: AppColors.grey500, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin puesto asignado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Espera a que un administrador te asigne a un puesto de trabajo para comenzar el monitoreo.',
                    style: TextStyle(color: AppColors.grey600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkstationCard extends StatelessWidget {
  final WorkstationRecord workstation;
  const _WorkstationCard({required this.workstation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.computer, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workstation.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Monitoreo asignado',
                        style: TextStyle(color: AppColors.grey600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Personal Productivity ───────────────────────────────────────────────────
class _PersonalProductivitySection extends ConsumerWidget {
  const _PersonalProductivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(employeeTodayAnalyticsProvider);

    return analyticsAsync.when(
      loading: () => const AppLoadingWidget(message: 'Calculando tiempo...'),
      error: (e, _) => const Text('No se pudieron obtener las métricas.'),
      data: (analytics) {
        if (analytics == null || !analytics.hasData) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('Aún no hay actividad registrada para ti el día de hoy.', style: TextStyle(color: AppColors.grey600)),
              ),
            ),
          );
        }

        final totalDuration = analytics.totalTrackedTime;
        final workTime = analytics.stateDurations[ActivityState.trabajando] ?? Duration.zero;
        final distractTime = analytics.stateDurations[ActivityState.distraido] ?? Duration.zero;
        final fatigueTime = analytics.stateDurations[ActivityState.fatiga] ?? Duration.zero;

        // Custom widget to draw simple bars
        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total: ${_formatDuration(totalDuration)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _StatBarRow(
                  label: 'Trabajando',
                  duration: workTime,
                  total: totalDuration,
                  color: AppColors.primary,
                  icon: Icons.work,
                ),
                const SizedBox(height: 12),
                _StatBarRow(
                  label: 'Distraído',
                  duration: distractTime,
                  total: totalDuration,
                  color: Colors.amber,
                  icon: Icons.search,
                ),
                const SizedBox(height: 12),
                _StatBarRow(
                  label: 'Fatiga',
                  duration: fatigueTime,
                  total: totalDuration,
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
}

class _StatBarRow extends StatelessWidget {
  final String label;
  final Duration duration;
  final Duration total;
  final Color color;
  final IconData icon;

  const _StatBarRow({
    required this.label,
    required this.duration,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = total.inSeconds > 0 
      ? (duration.inSeconds / total.inSeconds)
      : 0.0;
      
    String formatDuration(Duration d) {
      if (d.inMinutes < 1) return '${d.inSeconds}s';
      if (d.inHours < 1) return '${d.inMinutes}m';
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 45,
          child: Text(
            formatDuration(duration),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}


// ── Recent Activity Feed ────────────────────────────────────────────────────
class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(employeeRecentEventsProvider);

    return eventsAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => const Text('Error cargando historial'),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No hay eventos recientes.', style: TextStyle(color: AppColors.grey500))),
          );
        }

        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.state.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  event.state.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_formatTime(event.timestamp)),
                trailing: event.identificationMethod != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.identificationMethod!,
                          style: const TextStyle(fontSize: 10, color: AppColors.grey700),
                        ),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    final sec = time.second.toString().padLeft(2, '0');
    return '$hour:$min:$sec';
  }
}

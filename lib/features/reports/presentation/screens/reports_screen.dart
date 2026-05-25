import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/alert_log.dart';
import 'package:worksense_app/domain/entities/announcement.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/services/report_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyName =
        ref.watch(currentUserProvider).valueOrNull?.companyId ?? 'WorkSense';
    final tasksAsync = ref.watch(companyTasksProvider);
    final leavesAsync = ref.watch(companyLeavesProvider);
    final alertsAsync = ref.watch(alertLogsProvider);
    final announcementsAsync = ref.watch(companyAnnouncementsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Reportes',
          style: TextStyle(
              color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReportCard(
            icon: Icons.task_alt,
            iconColor: AppColors.primary,
            title: 'Reporte de Tareas',
            description: 'Estado, prioridad y vencimiento de todas las tareas.',
            count: tasksAsync.value?.length,
            onGenerate: tasksAsync.value == null
                ? null
                : () => _generateTasks(
                      context,
                      ref,
                      tasks: tasksAsync.value!,
                      companyName: companyName,
                    ),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.event_available,
            iconColor: AppColors.info,
            title: 'Reporte de Permisos',
            description:
                'Solicitudes de permiso: aprobadas, rechazadas y pendientes.',
            count: leavesAsync.value?.length,
            onGenerate: leavesAsync.value == null
                ? null
                : () => _generateLeaves(
                      context,
                      ref,
                      leaves: leavesAsync.value!,
                      companyName: companyName,
                    ),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            title: 'Reporte de Alertas',
            description:
                'Historial de alertas: ausencias, distracciones y fatiga.',
            count: alertsAsync.value?.length,
            onGenerate: alertsAsync.value == null
                ? null
                : () => _generateAlerts(
                      context,
                      ref,
                      alertRows: alertsAsync.value!,
                      companyName: companyName,
                    ),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.campaign_outlined,
            iconColor: AppColors.info,
            title: 'Reporte de Comunicados',
            description:
                'Comunicados publicados: urgentes, importantes e informativos.',
            count: announcementsAsync.value?.length,
            onGenerate: announcementsAsync.value == null
                ? null
                : () => _generateAnnouncements(
                      context,
                      ref,
                      announcements: announcementsAsync.value!,
                      companyName: companyName,
                    ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.grey400, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los reportes incluyen sólo datos locales sincronizados. '
                    'Para reportes completos asegúrate de estar conectado a internet.',
                    style: TextStyle(
                      color: AppColors.grey400,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTasks(
    BuildContext context,
    WidgetRef ref, {
    required List<TaskItem> tasks,
    required String companyName,
  }) async {
    await _runWithLoading(context, () async {
      await ReportService.instance.previewTasksReport(
        tasks: tasks,
        companyName: companyName,
      );
    });
  }

  Future<void> _generateLeaves(
    BuildContext context,
    WidgetRef ref, {
    required List<LeaveRequest> leaves,
    required String companyName,
  }) async {
    await _runWithLoading(context, () async {
      await ReportService.instance.previewLeavesReport(
        leaves: leaves,
        companyName: companyName,
      );
    });
  }

  Future<void> _generateAlerts(
    BuildContext context,
    WidgetRef ref, {
    required List<AlertLogData> alertRows,
    required String companyName,
  }) async {
    // Map DB rows to domain entities
    final alerts = alertRows
        .map((r) => AlertLog(
              id: r.id,
              companyId: r.companyId,
              employeeId: r.employeeId,
              workstationId: r.workstationId,
              alertType: AlertType.fromRaw(r.alertType),
              durationSeconds: r.durationSeconds,
              triggeredAt: r.triggeredAt,
              acknowledged: r.acknowledged,
            ))
        .toList();

    await _runWithLoading(context, () async {
      await ReportService.instance.previewAlertsReport(
        alerts: alerts,
        companyName: companyName,
      );
    });
  }

  Future<void> _generateAnnouncements(
    BuildContext context,
    WidgetRef ref, {
    required List<Announcement> announcements,
    required String companyName,
  }) async {
    await _runWithLoading(context, () async {
      await ReportService.instance.previewAnnouncementsReport(
        announcements: announcements,
        companyName: companyName,
      );
    });
  }

  Future<void> _runWithLoading(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error generando reporte: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.count,
    required this.onGenerate,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int? count;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (count != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count registros',
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.grey400,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text(
                        'Generar PDF',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: iconColor.withValues(alpha: 0.2),
                        foregroundColor: iconColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: iconColor.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
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

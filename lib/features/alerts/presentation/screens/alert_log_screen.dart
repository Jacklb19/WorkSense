import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/alert_log.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class AlertLogScreen extends ConsumerWidget {
  const AlertLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(alertLogsProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final unread = ref.watch(unacknowledgedAlertCountProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Row(
          children: [
            Text(
              'ALERTAS',
              style: TextStyle(
                color: context.appOnSurface,
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Text(
                  '$unread',
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () => _acknowledgeAll(context, ref),
              icon: const Icon(Icons.done_all, color: AppColors.primary, size: 16),
              label: Text(
                'Marcar todas',
                style: const TextStyle(color: AppColors.primary, fontSize: AppDimensions.fontCaption),
              ),
            ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: context.appOnSurfaceDisabled,
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),
                  Text(
                    'No hay alertas registradas',
                    style: TextStyle(
                      color: context.appOnSurfaceDisabled,
                      fontSize: AppDimensions.fontBodyMd,
                    ),
                  ),
                ],
              ),
            );
          }

          final employees = employeesAsync.valueOrNull ?? [];
          final empMap = {for (final e in employees) e.id: e};

          return AppContentConstrainer(
            width: AppContentWidth.list,
            child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              final emp = log.employeeId != null ? empMap[log.employeeId] : null;
              return _AlertLogCard(
                log: log,
                employee: emp,
                onAcknowledge: () => _acknowledge(ref, log.id),
              );
            },
          ),
          );
        },
      ),
    );
  }

  Future<void> _acknowledge(WidgetRef ref, String logId) async {
    final db = ref.read(appDatabaseProvider);
    await db.acknowledgeAlertLog(logId);
  }

  Future<void> _acknowledgeAll(BuildContext context, WidgetRef ref) async {
    final companyId = ref.read(currentUserProvider).valueOrNull?.companyId;
    if (companyId == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.acknowledgeAllAlertLogs(companyId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las alertas marcadas como leídas'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AlertLogCard extends StatelessWidget {
  final AlertLogData log;
  final Employee? employee;
  final VoidCallback onAcknowledge;

  const _AlertLogCard({
    required this.log,
    this.employee,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final alertType = AlertType.fromRaw(log.alertType);
    final fmt = DateFormat('dd/MM HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: log.acknowledged
            ? context.appCard
            : alertType.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        border: Border.all(
          color: log.acknowledged
              ? context.appGlassBorder
              : alertType.color.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: alertType.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          child: Icon(alertType.icon, color: alertType.color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alertType.label,
                style: TextStyle(
                  color: log.acknowledged ? AppColors.white70 : context.appOnSurface,
                  fontSize: AppDimensions.fontBody,
                  fontWeight: log.acknowledged
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
            if (!log.acknowledged)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: alertType.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee != null)
              Text(
                employee!.displayName,
                style: TextStyle(color: AppColors.white54, fontSize: AppDimensions.fontCaption),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 11, color: alertType.color),
                const SizedBox(width: 3),
                Text(
                  _duration(log.durationSeconds),
                  style: TextStyle(color: alertType.color, fontSize: AppDimensions.fontSm),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Text(
                  fmt.format(log.triggeredAt),
                  style:
                      TextStyle(color: context.appOnSurfaceDisabled, fontSize: AppDimensions.fontSm),
                ),
              ],
            ),
          ],
        ),
        trailing: log.acknowledged
            ? Icon(Icons.check_circle_outline,
                color: context.appOnSurfaceDisabled, size: 18)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.primary, size: 20),
                tooltip: 'Marcar como leída',
                onPressed: onAcknowledge,
              ),
      ),
    );
  }

  String _duration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}
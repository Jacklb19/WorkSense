import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/alert_log.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class AlertLogScreen extends ConsumerWidget {
  const AlertLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(alertLogsProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final unread = ref.watch(unacknowledgedAlertCountProvider);

    final ac = context.appColors;
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.surface,
        title: Row(
          children: [
            Text(
              'ALERTAS',
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
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
              label: const Text(
                'Marcar todas',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
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
                    color: ac.textDisabled.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay alertas registradas',
                    style: TextStyle(
                      color: ac.textDisabled,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final employees = employeesAsync.valueOrNull ?? [];
          final empMap = {for (final e in employees) e.id: e};

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertLogCard extends StatelessWidget {
  final AlertLogData log;
  final Employee? employee;
  final VoidCallback onAcknowledge;

  const _AlertLogCard({
    required this.log,
    this.employee,
    required this.onAcknowledge,
  });

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _fmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final alertType = AlertType.fromRaw(log.alertType);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: log.acknowledged
            ? ac.card
            : alertType.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: log.acknowledged
              ? AppColors.glassBorder
              : alertType.color.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: alertType.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(alertType.icon, color: alertType.color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alertType.label,
                style: TextStyle(
                  color: log.acknowledged ? ac.textSecondary : ac.textPrimary,
                  fontSize: 13,
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
                style: TextStyle(color: ac.textSecondary, fontSize: 12),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 11, color: alertType.color),
                const SizedBox(width: 3),
                Text(
                  _duration(log.durationSeconds),
                  style: TextStyle(color: alertType.color, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmt.format(log.triggeredAt),
                  style:
                      TextStyle(color: ac.textDisabled, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: log.acknowledged
            ? Icon(Icons.check_circle_outline,
                color: ac.textDisabled, size: 18)
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

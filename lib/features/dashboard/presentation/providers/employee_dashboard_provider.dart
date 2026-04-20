import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/admin_analytics_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Workstation Asignada ──────────────────────────────────────────────────
// Retorna la workstation a la que está asignado el usuario actual (si hay alguna)
final employeeAssignedWorkstationProvider =
    FutureProvider.autoDispose<WorkstationRecord?>((ref) async {
  final currentUserState = await ref.watch(currentUserProvider.future);
  final userId = currentUserState.user?.id;
  if (userId == null) return null;

  final workstations = await ref.watch(workstationsStreamProvider.future);

  // Buscar la primera workstation donde assignedEmployeeId coincida con el usuario
  return workstations
      .where((w) => w.assignedEmployeeId == userId)
      .firstOrNull;
});

// ── Stream de Eventos Recientes ───────────────────────────────────────────
// Muestra el feed en vivo de los últimos 10 eventos capturados para el usuario
final employeeRecentEventsProvider =
    StreamProvider.autoDispose<List<ActivityEvent>>((ref) {
  final userState = ref.watch(currentUserProvider);
  final userId = userState.valueOrNull?.user?.id;

  if (userId == null) {
    return Stream.value(const []);
  }

  // Ref watch the database via Provider
  final db = ref.watch(appDatabaseProvider);
  return db.watchActivityEntriesForEmployee(userId, limit: 10).map((rows) {
    // Map Drift entries to ActivityEvent entities
    return rows.map((row) {
      return ActivityEvent(
        id: row.id,
        employeeId: row.employeeId,
        workstationId: row.workstationId,
        state: ActivityState.values.firstWhere(
          (e) => e.name == row.state,
          orElse: () => ActivityState.ausente,
        ),
        confidence: row.confidence,
        timestamp: row.timestamp,
        synced: row.synced,
        identityConfidence: row.identityConfidence,
        identificationMethod: row.identificationMethod,
      );
    }).toList();
  });
});

// ── Analíticas del Día (Personal) ─────────────────────────────────────────
// Usa directmente el employeeDetailProvider reusando la lógica de admin_analytics_provider
final employeeTodayAnalyticsProvider =
    FutureProvider.autoDispose<EmployeeAnalytics?>((ref) async {
  final currentUserState = await ref.watch(currentUserProvider.future);
  final userId = currentUserState.user?.id;
  if (userId == null) return null;

  ref.read(analyticsDateRangeProvider.notifier).state =
      AnalyticsDateRange.today;

  return ref.watch(employeeDetailProvider(userId).future);
});

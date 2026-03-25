import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/activity_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

// ── Date Range Filter ────────────────────────────────────────────────────────

enum AnalyticsDateRange { today, thisWeek }

final analyticsDateRangeProvider =
    StateProvider<AnalyticsDateRange>((ref) => AnalyticsDateRange.today);

({DateTime from, DateTime to}) _dateRangeFor(AnalyticsDateRange range) {
  final now = DateTime.now();
  switch (range) {
    case AnalyticsDateRange.today:
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return (from: from, to: to);
    case AnalyticsDateRange.thisWeek:
      final weekday = now.weekday; // Monday = 1
      final from = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return (from: from, to: to);
  }
}

// ── Activity Repository (reuse from dashboard setup) ─────────────────────────

final _analyticsActivityRepoProvider = Provider<ActivityRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return ActivityRepositoryImpl(db, syncRepo);
});

// ── All Employee Analytics ───────────────────────────────────────────────────

final employeeAnalyticsProvider =
    FutureProvider<List<EmployeeAnalytics>>((ref) async {
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final range = _dateRangeFor(dateRange);
  final repo = ref.watch(_analyticsActivityRepoProvider);

  // 1. Fetch employees (from Supabase for admin, local as fallback)
  List<Employee> employees;
  try {
    employees = await ref.watch(adminEmployeesProvider.future);
  } catch (_) {
    employees = await ref.watch(employeesProvider.future);
  }

  // 2. Fetch all events in the date range (already filtered: employeeId != null)
  final allEvents = await repo.getEventsByDateRange(
    from: range.from,
    to: range.to,
  );

  // 3. Group events by employeeId
  final eventsByEmployee = <String, List<ActivityEvent>>{};
  for (final event in allEvents) {
    final empId = event.employeeId!;
    eventsByEmployee.putIfAbsent(empId, () => []).add(event);
  }

  // 4. Build analytics for each employee
  final results = <EmployeeAnalytics>[];
  for (final employee in employees) {
    final events = eventsByEmployee[employee.id] ?? [];
    results.add(_buildAnalytics(employee, events));
  }

  // Sort: employees with data first, then by total tracked time desc
  results.sort((a, b) {
    if (a.hasData && !b.hasData) return -1;
    if (!a.hasData && b.hasData) return 1;
    return b.totalTrackedTime.inSeconds
        .compareTo(a.totalTrackedTime.inSeconds);
  });

  return results;
});

// ── Single Employee Detail ───────────────────────────────────────────────────

final employeeDetailProvider =
    FutureProvider.family<EmployeeAnalytics?, String>(
        (ref, employeeId) async {
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final range = _dateRangeFor(dateRange);
  final repo = ref.watch(_analyticsActivityRepoProvider);

  // Find employee from Supabase list first, fallback to local
  Employee? employee;
  try {
    final remoteList = await ref.watch(adminEmployeesProvider.future);
    employee = remoteList.where((e) => e.id == employeeId).firstOrNull;
  } catch (_) {
    // ignore
  }
  if (employee == null) {
    try {
      final localList = await ref.watch(employeesProvider.future);
      employee = localList.where((e) => e.id == employeeId).firstOrNull;
    } catch (_) {
      // ignore
    }
  }
  if (employee == null) return null;

  // Fetch events for this employee within date range
  final events = await repo.getEventsForEmployee(
    employeeId,
    from: range.from,
    to: range.to,
  );

  return _buildAnalytics(employee, events);
});

// ── Build Analytics Helper ───────────────────────────────────────────────────

EmployeeAnalytics _buildAnalytics(
  Employee employee,
  List<ActivityEvent> events,
) {
  if (events.isEmpty) {
    return EmployeeAnalytics(
      employee: employee,
      stateDurations: {},
      stateCounts: {},
      totalEvents: 0,
    );
  }

  // Sort by timestamp ascending for duration calculation
  final sorted = List.of(events)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final counts = <ActivityState, int>{};
  final durations = <ActivityState, Duration>{};

  for (final event in sorted) {
    counts[event.state] = (counts[event.state] ?? 0) + 1;
  }

  // Calculate duration between consecutive events
  for (int i = 0; i < sorted.length - 1; i++) {
    final current = sorted[i];
    final next = sorted[i + 1];
    final diff = next.timestamp.difference(current.timestamp);

    // Ignore gaps > 30 min (break / app closed / end of shift)
    if (diff.inMinutes < 30) {
      durations[current.state] =
          (durations[current.state] ?? Duration.zero) + diff;
    }
  }

  // Give the last event a nominal 1-minute duration
  final lastEvent = sorted.last;
  durations[lastEvent.state] =
      (durations[lastEvent.state] ?? Duration.zero) +
          const Duration(minutes: 1);

  return EmployeeAnalytics(
    employee: employee,
    stateDurations: durations,
    stateCounts: counts,
    totalEvents: events.length,
    lastState: sorted.last.state,
    lastUpdate: sorted.last.timestamp,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/attendance_log.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/features/dashboard/domain/entities/employee_analytics.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/entrance_kiosk_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

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

final _localActivityRefreshProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) {
    return Stream.value(0);
  }
  return db
      .watchRecentActivityEntriesByCompany(companyId)
      .map((rows) => rows.length);
});

final _localAttendanceRefreshProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAttendanceLogs().map((rows) => rows.length);
});

// ── All Employee Analytics (fetches from Supabase) ───────────────────────────

final employeeAnalyticsProvider =
    FutureProvider<List<EmployeeAnalytics>>((ref) async {
  ref.watch(_localActivityRefreshProvider);
  ref.watch(_localAttendanceRefreshProvider);
  ref.watch(syncNotifierProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final range = _dateRangeFor(dateRange);
  final remote = ref.watch(supabaseDataSourceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final companyId = currentUser?.companyId;

  // 1. Fetch employees
  List<Employee> employees;
  try {
    employees = await ref.watch(adminEmployeesProvider.future);
  } catch (_) {
    employees = await ref.watch(employeesProvider.future);
  }

  // 2. Fetch events from BOTH Local and Remote
  final Map<String, ActivityEvent> mergedEvents = {};

  // A. Local Fetch
  try {
    final localRepo = ref.watch(activityRepositoryProvider);
    final localEvents = companyId == null
        ? <ActivityEvent>[]
        : await localRepo.getEventsByCompanyDateRange(
            companyId: companyId,
            from: range.from,
            to: range.to,
          );
    for (var e in localEvents) {
      mergedEvents[e.id] = e;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Error fetching local activity events: $e');
  }

  // B. Remote Fetch (Supabase)
  try {
    final rawEvents = await remote.fetchActivityEventsByDateRange(
      from: range.from,
      to: range.to,
      companyId: companyId,
    );
    final remoteEvents = rawEvents.map(_mapRemoteToActivityEvent);
    for (var e in remoteEvents) {
      mergedEvents[e.id] = e;
    }
  } catch (e, stack) {
    if (kDebugMode) debugPrint('Error fetching remote activity events: $e');
    if (kDebugMode) debugPrint('$stack');
  }

  final allEvents = mergedEvents.values.toList();

  // 3. Group events by employeeId
  final eventsByEmployee = <String, List<ActivityEvent>>{};
  for (final event in allEvents) {
    if (event.employeeId == null) continue;
    eventsByEmployee.putIfAbsent(event.employeeId!, () => []).add(event);
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

// ── Single Employee Detail (fetches from Supabase) ───────────────────────────

final employeeDetailProvider =
    FutureProvider.family<EmployeeAnalytics?, String>(
        (ref, employeeId) async {
  ref.watch(_localActivityRefreshProvider);
  ref.watch(syncNotifierProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final range = _dateRangeFor(dateRange);
  final remote = ref.watch(supabaseDataSourceProvider);

  // Find employee
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

  // Merge Local and Remote events for this employee
  final Map<String, ActivityEvent> mergedEvents = {};

  // A. Local
  try {
    final localRepo = ref.watch(activityRepositoryProvider);
    final localEvents = await localRepo.getEventsForEmployee(
      employeeId,
      from: range.from,
      to: range.to,
    );
    for (var e in localEvents) {
      mergedEvents[e.id] = e;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Error fetching local detail for $employeeId: $e');
  }

  // B. Remote
  try {
    final rawEvents = await remote.fetchActivityEventsForEmployee(
      employeeId,
      from: range.from,
      to: range.to,
    );
    final remoteEvents = rawEvents.map(_mapRemoteToActivityEvent);
    for (var e in remoteEvents) {
      mergedEvents[e.id] = e;
    }
  } catch (e, stack) {
    if (kDebugMode) debugPrint('Error fetching remote detail for $employeeId: $e');
    if (kDebugMode) debugPrint('$stack');
  }

  final events = mergedEvents.values.toList();

  return _buildAnalytics(employee, events);
});

// ── Employee Attendance Detail (fetches from Supabase) ───────────────────────

final employeeAttendanceProvider =
    FutureProvider.family<List<AttendanceLog>, String>((ref, employeeId) async {
  ref.watch(_localAttendanceRefreshProvider);
  ref.watch(syncNotifierProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final range = _dateRangeFor(dateRange);
  final remote = ref.watch(supabaseDataSourceProvider);
  final localAttendanceRepo = ref.watch(attendanceRepositoryProvider);
  final mergedLogs = <String, AttendanceLog>{};

  try {
    final localLogs = await localAttendanceRepo.getEmployeeLogs(
      employeeId,
      range.from,
      range.to,
    );
    for (final log in localLogs) {
      mergedLogs[log.id] = log;
    }
  } catch (e, stack) {
    if (kDebugMode) debugPrint('Error fetching local attendance logs for employee $employeeId: $e');
    if (kDebugMode) debugPrint('$stack');
  }

  try {
    final rawLogs = await remote.fetchAttendanceLogsForEmployee(
      employeeId,
      from: range.from,
      to: range.to,
    );
    for (final log in rawLogs.map(_mapRemoteToAttendanceLog)) {
      mergedLogs[log.id] = log;
    }
  } catch (e, stack) {
    if (kDebugMode) debugPrint('Error fetching attendance logs for employee $employeeId: $e');
    if (kDebugMode) debugPrint('$stack');
  }

  final logs = mergedLogs.values.toList()
    ..sort((a, b) => b.clockInTime.compareTo(a.clockInTime));
  return logs;
});

// ── Mapping Helpers ──────────────────────────────────────────────────────────

ActivityEvent _mapRemoteToActivityEvent(Map<String, dynamic> row) {
  return ActivityEvent(
    id: row['id'] as String,
    employeeId: row['employee_id'] as String?,
    workstationId: row['workstation_id'] as String? ?? '',
    state: ActivityState.values.firstWhere(
      (e) => e.name == row['state'],
      orElse: () => ActivityState.ausente,
    ),
    confidence: (row['confidence'] as num?)?.toDouble() ?? 0.0,
    timestamp: DateTime.parse(row['timestamp'] as String),
    synced: true,
    identityConfidence: (row['identity_confidence'] as num?)?.toDouble(),
    identificationMethod: row['identification_method'] as String?,
  );
}

AttendanceLog _mapRemoteToAttendanceLog(Map<String, dynamic> row) {
  return AttendanceLog(
    id: row['id'] as String,
    employeeId: row['employee_id'] as String,
    workstationId: row['workstation_id'] as String?,
    companyId: row['company_id'] as String,
    shiftDate: DateTime.parse(row['shift_date'] as String),
    clockInTime: DateTime.parse(row['clock_in_time'] as String),
    clockOutTime: row['clock_out_time'] != null
        ? DateTime.parse(row['clock_out_time'] as String)
        : null,
    status: AttendanceStatus.fromString(row['status'] as String? ?? 'ON_TIME'),
  );
}

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

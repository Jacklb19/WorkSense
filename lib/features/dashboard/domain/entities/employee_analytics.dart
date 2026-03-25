import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/employee.dart';

/// Analytics data for one employee over a time period.
class EmployeeAnalytics {
  final Employee employee;
  final Map<ActivityState, Duration> stateDurations;
  final Map<ActivityState, int> stateCounts;
  final int totalEvents;
  final ActivityState? lastState;
  final DateTime? lastUpdate;

  const EmployeeAnalytics({
    required this.employee,
    required this.stateDurations,
    required this.stateCounts,
    required this.totalEvents,
    this.lastState,
    this.lastUpdate,
  });

  /// Total tracked time across all states.
  Duration get totalTrackedTime =>
      stateDurations.values.fold(Duration.zero, (a, b) => a + b);

  /// Percentage (0..1) of tracked time spent in [state].
  double percentageFor(ActivityState state) {
    if (totalTrackedTime.inSeconds == 0) return 0;
    return (stateDurations[state]?.inSeconds ?? 0) /
        totalTrackedTime.inSeconds;
  }

  bool get hasData => totalEvents > 0;
}

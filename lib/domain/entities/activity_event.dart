import 'package:worksense_app/domain/entities/activity_state.dart';

class ActivityEvent {
  final String id;
  final String? employeeId;
  final String workstationId;
  final ActivityState state;
  final double confidence;
  final DateTime timestamp;
  final bool synced;

  const ActivityEvent({
    required this.id,
    this.employeeId,
    required this.workstationId,
    required this.state,
    required this.confidence,
    required this.timestamp,
    required this.synced,
  });

  ActivityEvent copyWith({
    String? id,
    String? employeeId,
    String? workstationId,
    ActivityState? state,
    double? confidence,
    DateTime? timestamp,
    bool? synced,
  }) {
    return ActivityEvent(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      workstationId: workstationId ?? this.workstationId,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'workstation_id': workstationId,
      'state': state.name,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          employeeId == other.employeeId &&
          workstationId == other.workstationId &&
          state == other.state &&
          confidence == other.confidence &&
          timestamp == other.timestamp &&
          synced == other.synced;

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        workstationId,
        state,
        confidence,
        timestamp,
        synced,
      );
}

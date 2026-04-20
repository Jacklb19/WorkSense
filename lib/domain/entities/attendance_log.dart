import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/workstation.dart';

enum AttendanceStatus {
  onTime('ON_TIME'),
  late('LATE'),
  earlyArrival('EARLY_ARRIVAL'),
  earlyDeparture('EARLY_DEPARTURE'),
  absent('ABSENT');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String val) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AttendanceStatus.onTime,
    );
  }
}

class AttendanceLog {
  final String id;
  final String employeeId;
  final String? workstationId;
  final String companyId;
  final DateTime shiftDate;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final AttendanceStatus status;

  // Transient/Relational fields
  final Employee? employee;
  final Workstation? workstation;

  const AttendanceLog({
    required this.id,
    required this.employeeId,
    this.workstationId,
    required this.companyId,
    required this.shiftDate,
    required this.clockInTime,
    this.clockOutTime,
    required this.status,
    this.employee,
    this.workstation,
  });

  bool get isOpen => clockOutTime == null;

  Duration get workedDuration {
    if (clockOutTime == null) {
      return DateTime.now().difference(clockInTime);
    }
    return clockOutTime!.difference(clockInTime);
  }

  AttendanceLog copyWith({
    String? id,
    String? employeeId,
    String? workstationId,
    String? companyId,
    DateTime? shiftDate,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    AttendanceStatus? status,
    Employee? employee,
    Workstation? workstation,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      workstationId: workstationId ?? this.workstationId,
      companyId: companyId ?? this.companyId,
      shiftDate: shiftDate ?? this.shiftDate,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      status: status ?? this.status,
      employee: employee ?? this.employee,
      workstation: workstation ?? this.workstation,
    );
  }
}

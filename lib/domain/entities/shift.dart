import 'package:flutter/material.dart' show TimeOfDay;

class Shift {
  final String id;
  final String companyId;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;
  final DateTime createdAt;

  const Shift({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    required this.createdAt,
  });

  /// Whether this shift has a configured break/lunch period.
  bool get hasBreak => breakStartTime != null && breakEndTime != null;

  /// Total theoretical work minutes excluding break.
  int get netWorkMinutes {
    final totalMinutes = _toMinutes(endTime) - _toMinutes(startTime);
    if (!hasBreak) return totalMinutes;
    final breakMinutes = _toMinutes(breakEndTime!) - _toMinutes(breakStartTime!);
    return totalMinutes - breakMinutes;
  }

  bool isTimeWithinShift(DateTime time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = _toMinutes(startTime);
    final endMinutes = _toMinutes(endTime);

    if (startMinutes <= endMinutes) {
      // Normal shift (e.g. 09:00 to 17:00)
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      // Night shift spanning midnight (e.g. 22:00 to 06:00)
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  /// Whether a given time falls inside the break window.
  bool isTimeWithinBreak(DateTime time) {
    if (!hasBreak) return false;
    final timeMinutes = time.hour * 60 + time.minute;
    return timeMinutes >= _toMinutes(breakStartTime!) &&
        timeMinutes <= _toMinutes(breakEndTime!);
  }

  Shift copyWith({
    String? id,
    String? companyId,
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
    DateTime? createdAt,
  }) {
    return Shift(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
}

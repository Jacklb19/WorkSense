import 'package:flutter/material.dart' show TimeOfDay;

class Shift {
  final String id;
  final String companyId;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime createdAt;

  const Shift({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  // Helpers for common time checks
  bool isTimeWithinShift(DateTime time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // Normal shift (e.g. 09:00 to 17:00)
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      // Night shift spanning midnight (e.g. 22:00 to 06:00)
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  Shift copyWith({
    String? id,
    String? companyId,
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? createdAt,
  }) {
    return Shift(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

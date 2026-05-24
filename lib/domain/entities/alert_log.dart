import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

// ── Enum ─────────────────────────────────────────────────────────────────────

enum AlertType {
  absence,
  distraction,
  fatigue;

  String get label {
    switch (this) {
      case AlertType.absence:     return 'Ausencia prolongada';
      case AlertType.distraction: return 'Distracción prolongada';
      case AlertType.fatigue:     return 'Fatiga detectada';
    }
  }

  String get raw {
    switch (this) {
      case AlertType.absence:     return 'ABSENCE';
      case AlertType.distraction: return 'DISTRACTION';
      case AlertType.fatigue:     return 'FATIGUE';
    }
  }

  Color get color {
    switch (this) {
      case AlertType.absence:     return AppColors.alertAbsent;
      case AlertType.distraction: return AppColors.alertDistracted;
      case AlertType.fatigue:     return AppColors.stateFatigue;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.absence:     return Icons.person_off_outlined;
      case AlertType.distraction: return Icons.visibility_off_outlined;
      case AlertType.fatigue:     return Icons.bedtime_outlined;
    }
  }

  static AlertType fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'DISTRACTION': return AlertType.distraction;
      case 'FATIGUE':     return AlertType.fatigue;
      default:            return AlertType.absence;
    }
  }
}

// ── Entity ───────────────────────────────────────────────────────────────────

class AlertLog {
  final String id;
  final String companyId;
  final String? employeeId;
  final String? workstationId;
  final AlertType alertType;
  final int durationSeconds;
  final DateTime triggeredAt;
  final bool acknowledged;

  const AlertLog({
    required this.id,
    required this.companyId,
    this.employeeId,
    this.workstationId,
    required this.alertType,
    required this.durationSeconds,
    required this.triggeredAt,
    required this.acknowledged,
  });

  String get durationLabel {
    if (durationSeconds < 60) return '${durationSeconds}s';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }

  AlertLog copyWith({
    bool? acknowledged,
  }) {
    return AlertLog(
      id: id,
      companyId: companyId,
      employeeId: employeeId,
      workstationId: workstationId,
      alertType: alertType,
      durationSeconds: durationSeconds,
      triggeredAt: triggeredAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}

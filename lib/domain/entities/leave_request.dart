import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum LeaveType {
  personal,
  medical,
  vacation,
  other;

  String get label {
    switch (this) {
      case LeaveType.personal:  return 'Personal';
      case LeaveType.medical:   return 'Médico';
      case LeaveType.vacation:  return 'Vacaciones';
      case LeaveType.other:     return 'Otro';
    }
  }

  String get raw {
    switch (this) {
      case LeaveType.personal:  return 'PERSONAL';
      case LeaveType.medical:   return 'MEDICAL';
      case LeaveType.vacation:  return 'VACATION';
      case LeaveType.other:     return 'OTHER';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveType.personal:  return Icons.person_outline;
      case LeaveType.medical:   return Icons.local_hospital_outlined;
      case LeaveType.vacation:  return Icons.beach_access_outlined;
      case LeaveType.other:     return Icons.more_horiz;
    }
  }

  static LeaveType fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'MEDICAL':   return LeaveType.medical;
      case 'VACATION':  return LeaveType.vacation;
      case 'OTHER':     return LeaveType.other;
      default:          return LeaveType.personal;
    }
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case LeaveStatus.pending:  return 'Pendiente';
      case LeaveStatus.approved: return 'Aprobado';
      case LeaveStatus.rejected: return 'Rechazado';
    }
  }

  String get raw {
    switch (this) {
      case LeaveStatus.pending:  return 'PENDING';
      case LeaveStatus.approved: return 'APPROVED';
      case LeaveStatus.rejected: return 'REJECTED';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:  return AppColors.warning;
      case LeaveStatus.approved: return AppColors.success;
      case LeaveStatus.rejected: return AppColors.error;
    }
  }

  static LeaveStatus fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'APPROVED': return LeaveStatus.approved;
      case 'REJECTED': return LeaveStatus.rejected;
      default:         return LeaveStatus.pending;
    }
  }
}

// ── Entity ───────────────────────────────────────────────────────────────────

class LeaveRequest {
  static const Object _sentinel = Object();

  final String id;
  final String employeeId;
  final String companyId;
  final LeaveType type;
  final LeaveStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String? reviewedById;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.reviewedById,
    this.reviewNote,
    required this.createdAt,
    required this.updatedAt,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? companyId,
    LeaveType? type,
    LeaveStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    Object? reason = _sentinel,
    Object? reviewedById = _sentinel,
    Object? reviewNote = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: identical(reason, _sentinel) ? this.reason : reason as String?,
      reviewedById: identical(reviewedById, _sentinel) ? this.reviewedById : reviewedById as String?,
      reviewNote: identical(reviewNote, _sentinel) ? this.reviewNote : reviewNote as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'employee_id': employeeId,
        'company_id': companyId,
        'type': type.raw,
        'status': status.raw,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'reason': reason,
        'reviewed_by_id': reviewedById,
        'review_note': reviewNote,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

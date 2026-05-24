import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum TaskStatus {
  pending,
  inProgress,
  done,
  cancelled;

  String get label {
    switch (this) {
      case TaskStatus.pending:    return 'Pendiente';
      case TaskStatus.inProgress: return 'En progreso';
      case TaskStatus.done:       return 'Completada';
      case TaskStatus.cancelled:  return 'Cancelada';
    }
  }

  String get raw {
    switch (this) {
      case TaskStatus.pending:    return 'PENDING';
      case TaskStatus.inProgress: return 'IN_PROGRESS';
      case TaskStatus.done:       return 'DONE';
      case TaskStatus.cancelled:  return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:    return AppColors.warning;
      case TaskStatus.inProgress: return AppColors.primary;
      case TaskStatus.done:       return AppColors.success;
      case TaskStatus.cancelled:  return AppColors.grey500;
    }
  }

  static TaskStatus fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'IN_PROGRESS': return TaskStatus.inProgress;
      case 'DONE':        return TaskStatus.done;
      case 'CANCELLED':   return TaskStatus.cancelled;
      default:            return TaskStatus.pending;
    }
  }
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent;

  String get label {
    switch (this) {
      case TaskPriority.low:    return 'Baja';
      case TaskPriority.normal: return 'Normal';
      case TaskPriority.high:   return 'Alta';
      case TaskPriority.urgent: return 'Urgente';
    }
  }

  String get raw {
    switch (this) {
      case TaskPriority.low:    return 'LOW';
      case TaskPriority.normal: return 'NORMAL';
      case TaskPriority.high:   return 'HIGH';
      case TaskPriority.urgent: return 'URGENT';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:    return AppColors.grey400;
      case TaskPriority.normal: return AppColors.info;
      case TaskPriority.high:   return AppColors.warning;
      case TaskPriority.urgent: return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:    return Icons.keyboard_arrow_down;
      case TaskPriority.normal: return Icons.remove;
      case TaskPriority.high:   return Icons.keyboard_arrow_up;
      case TaskPriority.urgent: return Icons.priority_high;
    }
  }

  static TaskPriority fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'LOW':    return TaskPriority.low;
      case 'HIGH':   return TaskPriority.high;
      case 'URGENT': return TaskPriority.urgent;
      default:       return TaskPriority.normal;
    }
  }
}

// ── Entity ───────────────────────────────────────────────────────────────────

class TaskItem {
  static const Object _sentinel = Object();

  final String id;
  final String companyId;
  final String assignedToId;
  final String createdById;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.companyId,
    required this.assignedToId,
    required this.createdById,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.done &&
      status != TaskStatus.cancelled;

  TaskItem copyWith({
    String? id,
    String? companyId,
    String? assignedToId,
    String? createdById,
    String? title,
    Object? description = _sentinel,
    TaskStatus? status,
    TaskPriority? priority,
    Object? dueDate = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      assignedToId: assignedToId ?? this.assignedToId,
      createdById: createdById ?? this.createdById,
      title: title ?? this.title,
      description: identical(description, _sentinel) ? this.description : description as String?,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: identical(dueDate, _sentinel) ? this.dueDate : dueDate as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'assigned_to_id': assignedToId,
        'created_by_id': createdById,
        'title': title,
        'description': description,
        'status': status.raw,
        'priority': priority.raw,
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

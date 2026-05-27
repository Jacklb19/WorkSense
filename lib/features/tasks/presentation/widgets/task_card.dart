import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/domain/entities/task_item.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final String? employeeName;
  final bool isAdmin;
  final VoidCallback? onTap;
  final void Function(TaskStatus)? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.employeeName,
    this.isAdmin = false,
    this.onTap,
    this.onStatusChanged,
  });

  // ✅ Static final — DateFormat instantiated once, not on every build.
  static final _dueDateFmt = DateFormat('dd/MM/yy');

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;

    final ac = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  // Priority chip
                  _PriorityBadge(priority: task.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.status),
                ],
              ),

              // ── Description ──────────────────────────────────────────────
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 10),

              // ── Footer ───────────────────────────────────────────────────
              Row(
                children: [
                  // Assigned to (admin view)
                  if (isAdmin && employeeName != null) ...[
                    Icon(Icons.person_outline, size: 13, color: ac.textDisabled),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        employeeName!,
                        style: TextStyle(color: ac.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Due date
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: overdue ? AppColors.error : ac.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _dueDateFmt.format(task.dueDate!),
                      style: TextStyle(
                        color: overdue ? AppColors.error : ac.textSecondary,
                        fontSize: 11,
                        fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (overdue) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '¡Vencida!',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],

                  const Spacer(),

                  // Quick status change for employee
                  if (!isAdmin && task.status != TaskStatus.done && task.status != TaskStatus.cancelled)
                    _QuickStatusButton(task: task, onStatusChanged: onStatusChanged),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: priority.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 10, color: priority.color),
          const SizedBox(width: 3),
          Text(
            priority.label.toUpperCase(),
            style: TextStyle(
              color: priority.color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickStatusButton extends StatelessWidget {
  final TaskItem task;
  final void Function(TaskStatus)? onStatusChanged;

  const _QuickStatusButton({required this.task, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final nextStatus = task.status == TaskStatus.pending
        ? TaskStatus.inProgress
        : TaskStatus.done;
    final label = task.status == TaskStatus.pending ? 'Iniciar' : 'Completar';
    final color = task.status == TaskStatus.pending ? AppColors.primary : AppColors.success;

    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onStatusChanged?.call(nextStatus),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

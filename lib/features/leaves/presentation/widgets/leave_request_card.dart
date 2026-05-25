import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final String? employeeName;
  final bool isAdmin;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  const LeaveRequestCard({
    super.key,
    required this.request,
    this.employeeName,
    this.isAdmin = false,
    this.onApprove,
    this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yy', 'es');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: request.type.icon == Icons.local_hospital_outlined
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(request.type.icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isAdmin && employeeName != null)
                        Text(
                          employeeName!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),

            const SizedBox(height: 12),

            // ── Date range ────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  '${fmt.format(request.startDate)} → ${fmt.format(request.endDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${request.durationDays} día${request.durationDays == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Reason ────────────────────────────────────────────────────
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.reason!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Review note ───────────────────────────────────────────────
            if (request.reviewNote != null && request.reviewNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: request.status.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: request.status.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined,
                        size: 12, color: request.status.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.reviewNote!,
                        style: TextStyle(
                          color: request.status.color,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Admin actions ─────────────────────────────────────────────
            if (isAdmin && request.status == LeaveStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Rechazar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Aprobar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            // ── Employee delete (pending only) ────────────────────────────
            if (!isAdmin && request.status == LeaveStatus.pending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Cancelar solicitud'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LeaveStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

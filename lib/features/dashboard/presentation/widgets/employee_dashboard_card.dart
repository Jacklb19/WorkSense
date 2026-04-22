import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_text_styles.dart';

class EmployeeDashboardCard extends StatelessWidget {
  final String employeeName;
  final String? workstationName;
  final String lastStateLabel;
  final Color lastStateColor;
  final IconData lastStateIcon;
  final String updatedLabel;
  final VoidCallback onTap;

  const EmployeeDashboardCard({
    required this.employeeName,
    required this.lastStateLabel,
    required this.lastStateColor,
    required this.lastStateIcon,
    required this.updatedLabel,
    required this.onTap,
    this.workstationName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF111827) : Colors.white;
    final border = dark ? const Color(0xFF334155) : const Color(0xFFDDE5F0);
    final titleColor = dark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent = dark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF8);
    final shadow = dark ? const Color(0x00000000) : const Color(0x120F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            workstationName ?? 'Sin estación asignada',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: subtitleColor,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: lastStateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lastStateIcon,
                        size: 16,
                        color: lastStateColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastStateLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: lastStateColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  updatedLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/payroll.dart';

class RateTile extends StatefulWidget {
  final Employee employee;
  final PayrollConfig? config;
  final Future<void> Function(double rate) onSave;

  const RateTile({
    super.key,
    required this.employee,
    required this.config,
    required this.onSave,
  });

  @override
  State<RateTile> createState() => _RateTileState();
}

class _RateTileState extends State<RateTile> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.config != null
          ? widget.config!.hourlyRate.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            radius: AppDimensions.spacing20,
            child: Text(
              widget.employee.displayName.isNotEmpty
                  ? widget.employee.displayName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.displayName,
                  style: theme.textTheme.labelLarge?.copyWith(color: context.appOnSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('\$ / hora',
                    style: theme.textTheme.labelSmall?.copyWith(color: context.appOnSurfaceSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: theme.textTheme.bodyLarge?.copyWith(color: context.appOnSurface),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceDisabled),
                filled: true,
                fillColor: context.appCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingMd),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          _saving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                  onPressed: () async {
                    final rate =
                        double.tryParse(_ctrl.text.trim()) ?? 0;
                    if (rate < 0) return;
                    setState(() => _saving = true);
                    await widget.onSave(rate);
                    if (mounted) setState(() => _saving = false);
                  },
                ),
        ],
      ),
    );
  }
}

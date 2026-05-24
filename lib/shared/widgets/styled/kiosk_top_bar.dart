import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/shared/widgets/styled/kiosk_overlay_container.dart';

/// Top HUD bar rendered over the kiosk camera preview.
/// Shows the WORKSENSE brand, workstation ID chip, and a close/back button.
class KioskTopBar extends StatelessWidget {
  const KioskTopBar({
    super.key,
    required this.workstationId,
    required this.isProcessing,
    required this.onBack,
  });

  final String workstationId;
  final bool isProcessing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return KioskOverlayContainer(
      alignment: Alignment.topCenter,
      horizontalPadding: AppDimensions.spacing24,
      verticalPadding: AppDimensions.spacingXxl,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Semantics(
              label: 'Cerrar monitor',
              button: true,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.close, color: AppColors.white70),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            const Text(
              'WORKSENSE',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: AppDimensions.fontTitle,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Flexible(
              child: _WorkstationChip(workstationId: workstationId),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkstationChip extends StatelessWidget {
  const _WorkstationChip({required this.workstationId});

  final String workstationId;

  @override
  Widget build(BuildContext context) {
    final displayId = workstationId.length > 8
        ? '${workstationId.substring(0, 8)}…'
        : workstationId;

    return Semantics(
      label: 'Puesto de trabajo: $workstationId',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing10,
          vertical: AppDimensions.spacingXs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary20,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: Text(
          displayId,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

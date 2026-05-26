import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/activity_overlay_painter.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/camera_preview_widget.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/state_badge_widget.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/employee_scan_screen.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class KioskScreen extends ConsumerStatefulWidget {
  final String? workstationId;

  const KioskScreen({super.key, this.workstationId});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> with WidgetsBindingObserver {
  Timer? _syncTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    if (widget.workstationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(kioskProvider.notifier).setWorkstationId(widget.workstationId!);
      });
    }

    _initCamera();
    
    // Periodic sync: push activity events to Supabase every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.read(syncNotifierProvider.notifier).sync();
      }
    });
  }

  Future<void> _initCamera() async {
    final status = await [Permission.camera, Permission.locationWhenInUse].request();

    if (status[Permission.camera] != PermissionStatus.granted) {
      if (mounted) ref.read(kioskProvider.notifier).setError(AppStrings.cameraPermissionDenied);
      return;
    }

    final cameras = await ref.read(availableCamerasProvider.future);
    if (!mounted) return;

    final workstationId = ref.read(kioskProvider).workstationId;
    await ref.read(kioskProvider.notifier).loadProfileAndInit(cameras, workstationId);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    try {
      ref.read(kioskProvider.notifier).stopCamera();
    } catch (_) {}
    // Trigger one final sync before leaving
    try {
      ref.read(syncNotifierProvider.notifier).sync();
    } catch (_) {}
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kioskState = ref.watch(kioskProvider);
    final controller = ref.read(kioskProvider.notifier).cameraController;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showExitConfirmation(context);
        if (confirmed && context.mounted) {
          await ref.read(kioskProvider.notifier).stopCamera();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (kioskState.error != null)
              CameraErrorWidget(message: kioskState.error!, onRetry: _initCamera)
            else if (!kioskState.isEmployeeScanned)
              _NoProfileView(
                workstationId: kioskState.workstationId,
                assignedEmployeeId: kioskState.assignedEmployeeId,
                onScanComplete: _initCamera,
              )
            else if (kioskState.workstationStatus != 'ACTIVE')
              _WaitingStandbyView(status: kioskState.workstationStatus)
            else if (controller != null && kioskState.cameraInitialized)
              CameraPreviewWidget(controller: controller)
            else
              const _LoadingView(),

            // Only draw the activity overlay when an enrolled employee is present.
            // Without this guard, the SizedBox.expand() child blocks all taps on
            // the enrollment UI and the landmark painter draws over its text.
            if (kioskState.cameraInitialized && kioskState.isEmployeeScanned)
              IgnorePointer(
                child: CustomPaint(
                  painter: ActivityOverlayPainter(
                    state: kioskState.currentState,
                    confidence: kioskState.confidence,
                    poses: kioskState.poses,
                    faces: kioskState.faces,
                    imageSize: kioskState.imageSize,
                    identificationMethod: kioskState.identificationMethod,
                    identityConfidence: kioskState.identityConfidence,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),

            // OVERLAYS
            if (kioskState.sessionStatus == SessionStatus.entryPending)
              _SessionActionOverlay(
                title: 'BIENVENIDO',
                subtitle: AppStrings.facialRecognitionSuccess,
                icon: Icons.face_retouching_natural,
                color: AppColors.primary,
                actionLabel: 'INICIAR SESIÓN',
                onConfirm: ref.read(kioskProvider.notifier).approveEntry,
                onCancel: ref.read(kioskProvider.notifier).cancelApproval,
              )
            else if (kioskState.sessionStatus == SessionStatus.exitPending)
              _SessionActionOverlay(
                title: AppStrings.finishQuestion,
                subtitle: AppStrings.confirmClockOut,
                icon: Icons.logout,
                color: AppColors.orangeWarning,
                actionLabel: AppStrings.clockOut,
                onConfirm: ref.read(kioskProvider.notifier).approveExit,
                onCancel: ref.read(kioskProvider.notifier).cancelApproval,
              )
            else if (kioskState.sessionStatus == SessionStatus.active) ...[
                Positioned(top: 0, left: 0, right: 0, 
                  child: _KioskTopHUD(
                    workstationId: kioskState.workstationId,
                    isProcessing: kioskState.isProcessing,
                    onBack: () async {
                      final ok = await _showExitConfirmation(context);
                      if (ok && context.mounted) {
                        await ref.read(kioskProvider.notifier).stopCamera();
                        if (context.mounted) context.pop();
                      }
                    },
                  ),
                ),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: _KioskBottomHUD(
                    state: kioskState.currentState,
                    confidence: kioskState.confidence,
                    onExit: ref.read(kioskProvider.notifier).requestExit,
                  ),
                ),
            ] else if (kioskState.workstationStatus == 'ACTIVE' && kioskState.isEmployeeScanned) ...[
               Positioned(top: AppDimensions.spacing64, left: 0, right: 0,
                 child: _IdentifyingHUD(isProcessing: kioskState.isProcessing),
               ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentifyingHUD extends StatelessWidget {
  final bool isProcessing;
  const _IdentifyingHUD({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20, vertical: AppDimensions.spacing10),
        decoration: BoxDecoration(
          color: AppColors.overlayBadgeBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusContainer),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProcessing) ...[
               const SizedBox(width: AppDimensions.spacingLg, height: AppDimensions.spacingLg, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight)),
               const SizedBox(width: AppDimensions.spacingXxl),
            ],
            Semantics(
              liveRegion: true,
              label: AppStrings.scannerActive,
              child: const Text(AppStrings.scannerActive, style: TextStyle(color: AppColors.white, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskTopHUD extends StatelessWidget {
  final String workstationId;
  final bool isProcessing;
  final VoidCallback onBack;

  const _KioskTopHUD({required this.workstationId, required this.isProcessing, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacingXxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.black.withValues(alpha: 0.8), AppColors.transparent]),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: AppStrings.closeMonitor,
              child: IconButton(onPressed: onBack, icon: const Icon(Icons.close, color: AppColors.white70)),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            const Text(AppStrings.worksenseBrand, style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: AppDimensions.fontTitle, letterSpacing: 1.0)),
            const Spacer(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing10, vertical: AppDimensions.spacingXs),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
                child: Text(
                  workstationId.length > 8 ? '${workstationId.substring(0, 8)}…' : workstationId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: AppDimensions.fontXs, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskBottomHUD extends StatelessWidget {
  final ActivityState state;
  final double confidence;
  final VoidCallback onExit;

  const _KioskBottomHUD({required this.state, required this.confidence, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [AppColors.black.withValues(alpha: 0.8), AppColors.transparent]),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadgeWidget(state: state, confidence: confidence, showConfidence: true),
            const SizedBox(height: AppDimensions.spacingLg),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.spacing44,
              child: Semantics(
                button: true,
                label: AppStrings.exitButton,
                child: FilledButton.icon(
                  onPressed: onExit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white10,
                  ),
                  icon: const Icon(Icons.power_settings_new, size: AppDimensions.iconSm),
                  label: const Text(AppStrings.exitButton, style: TextStyle(fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionActionOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SessionActionOverlay({
    required this.title, required this.subtitle, required this.icon,
    required this.color, required this.actionLabel, required this.onConfirm, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 2)),
                child: Icon(icon, size: AppDimensions.iconEmptyStateLg, color: color),
              ),
              const SizedBox(height: AppDimensions.spacing32),
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(subtitle, style: const TextStyle(color: AppColors.white70, fontSize: AppDimensions.fontTitle)),
              const SizedBox(height: AppDimensions.spacing56),
              Semantics(
                button: true,
                label: actionLabel,
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, AppDimensions.iconEmptyStateLg)),
                  child: Text(actionLabel, style: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              Semantics(
                button: true,
                label: AppStrings.cancel,
                child: TextButton(onPressed: onCancel, child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.white38))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Container(color: AppColors.black, child: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
}

class _NoProfileView extends StatelessWidget {
  final String workstationId;
  final String? assignedEmployeeId;
  final VoidCallback onScanComplete;

  const _NoProfileView({required this.workstationId, required this.assignedEmployeeId, required this.onScanComplete});

  @override
  Widget build(BuildContext context) {
    final hasEmployee = assignedEmployeeId != null;
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.all(AppDimensions.spacing40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasEmployee ? Icons.face : Icons.person_off, size: AppDimensions.iconLogo, color: hasEmployee ? AppColors.primary : AppColors.white24),
            const SizedBox(height: AppDimensions.spacing32),
            Text(hasEmployee ? 'ENROLAMIENTO PENDIENTE' : 'SIN ASIGNACIÓN', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: AppDimensions.fontTitleLg, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(hasEmployee ? AppStrings.scanningRequired : AppStrings.noEmployeeAssignedKiosk, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white60, fontSize: AppDimensions.fontBodyMd)),
            const SizedBox(height: AppDimensions.spacing48),
            if (hasEmployee)
              FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text(AppStrings.facialCapture),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeScanScreen(
                      workstationId: workstationId,
                      employeeId: assignedEmployeeId!,
                      onComplete: onScanComplete,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showExitConfirmation(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.exitKioskTitle),
      content: const Text(AppStrings.exitKioskMessage),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.exitButton)),
      ],
    ),
  ) ?? false;
}

class _WaitingStandbyView extends StatelessWidget {
  final String status;

  const _WaitingStandbyView({required this.status});

  @override
  Widget build(BuildContext context) {
    bool isBreak = status == 'BREAK';
    return Container(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBreak ? Icons.free_breakfast : Icons.bedtime, 
              size: AppDimensions.iconLogo, 
              color: isBreak ? AppColors.orangeWarning : AppColors.primary
            ),
            const SizedBox(height: AppDimensions.spacing32),
            Semantics(
              liveRegion: true,
              label: isBreak ? AppStrings.pauseLabel : AppStrings.waitingLabel,
              child: Text(
                isBreak ? AppStrings.pauseLabel : AppStrings.waitingLabel,
                style: const TextStyle(
                  color: AppColors.white, 
                  fontSize: AppDimensions.fontDisplayXs, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              isBreak 
                ? AppStrings.pauseByBreak 
                : AppStrings.waitingForScan,
              style: const TextStyle(color: AppColors.white70, fontSize: AppDimensions.fontTitle),
            ),
            const SizedBox(height: AppDimensions.spacing64),
            const CircularProgressIndicator(color: AppColors.white24),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:worksense_app/core/theme/app_colors.dart';
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
      if (mounted) ref.read(kioskProvider.notifier).setError('Permiso de cámara denegado.');
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
        backgroundColor: Colors.black,
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

            if (kioskState.cameraInitialized)
              CustomPaint(
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

            // OVERLAYS
            if (kioskState.sessionStatus == SessionStatus.entryPending)
              _SessionActionOverlay(
                title: 'BIENVENIDO',
                subtitle: 'Rostro reconocido con éxito',
                icon: Icons.face_retouching_natural,
                color: AppColors.primary,
                actionLabel: 'INICIAR SESIÓN',
                onConfirm: ref.read(kioskProvider.notifier).approveEntry,
                onCancel: ref.read(kioskProvider.notifier).cancelApproval,
              )
            else if (kioskState.sessionStatus == SessionStatus.exitPending)
              _SessionActionOverlay(
                title: '¿FINALIZAR?',
                subtitle: 'Confirmar cierre de jornada',
                icon: Icons.logout,
                color: Colors.orange,
                actionLabel: 'CERRAR SESIÓN',
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
            ] else if (kioskState.workstationStatus == 'ACTIVE') ...[
               Positioned(top: 64, left: 0, right: 0,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.overlayBadgeBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProcessing) ...[
               const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight)),
               const SizedBox(width: 12),
            ],
            const Text('SCANNER ACTIVO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.close, color: Colors.white70)),
            const SizedBox(width: 8),
            const Text('WORKSENSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
            const Spacer(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
                child: Text(
                  workstationId.length > 8 ? '${workstationId.substring(0, 8)}…' : workstationId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadgeWidget(state: state, confidence: confidence, showConfidence: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: onExit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white10,
                ),
                icon: const Icon(Icons.power_settings_new, size: 18),
                label: const Text('SALIR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 2)),
                child: Icon(icon, size: 64, color: color),
              ),
              const SizedBox(height: 32),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 56),
              FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 64)),
                child: Text(actionLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onCancel, child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
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
  Widget build(BuildContext context) => Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
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
      color: Colors.black,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasEmployee ? Icons.face : Icons.person_off, size: 80, color: hasEmployee ? AppColors.primary : Colors.white24),
            const SizedBox(height: 32),
            Text(hasEmployee ? 'ENROLAMIENTO PENDIENTE' : 'SIN ASIGNACIÓN', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Text(hasEmployee ? 'Se requiere una captura facial inicial para habilitar el reconocimiento en tiempo real.' : 'No hay un empleado asignado a este puesto de trabajo.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 48),
            if (hasEmployee)
              FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('EMPEZAR CAPTURA'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeScanScreen(workstationId: workstationId, employeeId: assignedEmployeeId!, onComplete: () { Navigator.pop(context); onScanComplete(); }))),
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
      title: const Text('SALIR DEL SISTEMA'),
      content: const Text('¿Está seguro que desea cerrar la sesión del monitor?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SALIR')),
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
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBreak ? Icons.free_breakfast : Icons.bedtime, 
              size: 80, 
              color: isBreak ? Colors.orange : AppColors.primary
            ),
            const SizedBox(height: 32),
            Text(
              isBreak ? 'EN PAUSA' : 'EN ESPERA',
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isBreak 
                ? 'El monitoreo está pausado por descanso.' 
                : 'Esperando escaneo en el Kiosco de Entrada...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(color: Colors.white24),
          ],
        ),
      ),
    );
  }
}


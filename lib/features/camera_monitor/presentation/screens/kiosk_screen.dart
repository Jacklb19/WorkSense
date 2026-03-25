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
import 'package:worksense_app/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/employee_scan_screen.dart';

class KioskScreen extends ConsumerStatefulWidget {
  final String? workstationId;

  const KioskScreen({super.key, this.workstationId});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen>
    with WidgetsBindingObserver {
  bool _cameraStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Kiosk en portrait — la cámara apunta a la persona frente al dispositivo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Set workstation if provided
    if (widget.workstationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(kioskProvider.notifier)
            .setWorkstationId(widget.workstationId!);
      });
    }

    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();

    if (status[Permission.camera] != PermissionStatus.granted) {
      if (mounted) {
        ref.read(kioskProvider.notifier).setError(
              'Permiso de cámara denegado. Actívalo en configuración.',
            );
      }
      return;
    }

    final cameras = await ref.read(availableCamerasProvider.future);
    if (!mounted) return;

    final workstationId = ref.read(kioskProvider).workstationId;
    final hasProfile = await ref
        .read(kioskProvider.notifier)
        .loadProfileAndInit(cameras, workstationId);

    if (!mounted) return;

    if (!hasProfile) {
      // Sin perfil → mostrar pantalla de escaneo
      // El equipo de routing se encarga de la navegación desde aquí.
      // Por ahora marcamos la cámara como no iniciada y dejamos el estado noIdentificado.
      setState(() => _cameraStarted = false);
    } else {
      setState(() => _cameraStarted = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    final controller = ref.read(kioskProvider.notifier).cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (appState == AppLifecycleState.inactive) {
      controller.stopImageStream().catchError((_) {});
    } else if (appState == AppLifecycleState.resumed) {
      if (!controller.value.isStreamingImages) {
        _initCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Forzar detención de cámara antes de que Riverpod haga dispose del notifier
    try {
      ref.read(kioskProvider.notifier).stopCamera();
    } catch (_) {}

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]); // Restaurar todas las orientaciones al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar alertas MVP en pantalla
    ref.listen<AlertMessage?>(alertsProvider, (previous, current) {
      if (current != null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: current.backgroundColor,
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    current.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Limpiamos la alerta inmediatamente para permitir futuras notificaciones
        ref.read(alertsProvider.notifier).clearAlert();
      }
    });

    final kioskState = ref.watch(kioskProvider);
    final controller = ref.read(kioskProvider.notifier).cameraController;

    return PopScope(
      canPop: false, // Bloquear back del sistema completamente
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Ya se procesó, ignorar

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
            // Camera preview
            if (kioskState.error != null)
              CameraErrorWidget(
                message: kioskState.error!,
                onRetry: _initCamera,
              )
            else if (controller != null && kioskState.cameraInitialized)
              CameraPreviewWidget(controller: controller)
            else if (!kioskState.isEmployeeScanned)
              _NoProfileView(
                workstationId: kioskState.workstationId,
                assignedEmployeeId: kioskState.assignedEmployeeId,
                onScanComplete: _initCamera,
              )
            else
              const _LoadingView(),

            // AI overlay
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

            // Top AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _KioskAppBar(
                workstationId: kioskState.workstationId,
                isProcessing: kioskState.isProcessing,
              ),
            ),

            // Bottom info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomInfoPanel(
                state: kioskState.currentState,
                confidence: kioskState.confidence,
                frameCount: kioskState.frameCount,
                lastEventTime: kioskState.lastEventTime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Iniciando monitoreo...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskAppBar extends ConsumerWidget {
  final String workstationId;
  final bool isProcessing;

  const _KioskAppBar({
    required this.workstationId,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text(
              'WorkSense',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  workstationId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isProcessing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () async {
                final confirmed = await _showExitConfirmation(context);
                if (confirmed && context.mounted) {
                  await ref.read(kioskProvider.notifier).stopCamera();
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
              tooltip: 'Volver al dashboard',
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
          title: const Text('Salir del modo kiosco'),
          content: const Text('¿Deseas cerrar sesión y salir del monitoreo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir'),
            ),
          ],
        ),
      ) ??
      false;
}

// ── Vista cuando no hay perfil biométrico registrado ──────────────────────────

class _NoProfileView extends StatelessWidget {
  final String workstationId;
  final String? assignedEmployeeId;
  final VoidCallback onScanComplete;

  const _NoProfileView({
    required this.workstationId,
    required this.assignedEmployeeId,
    required this.onScanComplete,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmployee = assignedEmployeeId != null;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasEmployee ? Icons.face_retouching_natural : Icons.person_off,
              size: 72,
              color: hasEmployee ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              hasEmployee
                  ? 'Empleado sin perfil biométrico'
                  : 'Estación sin empleado asignado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasEmployee
                  ? 'Escanea al empleado para que la cámara pueda reconocerlo y seguirlo.'
                  : 'Asigna un empleado a esta estación desde el panel de administración.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 40),
            if (hasEmployee)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 22),
                  label: const Text(
                    'Escanear empleado',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeScanScreen(
                        workstationId: workstationId,
                        employeeId: assignedEmployeeId!,
                        onComplete: () {
                          Navigator.pop(context);
                          onScanComplete();
                        },
                      ),
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

class _BottomInfoPanel extends StatelessWidget {
  final ActivityState state;
  final double confidence;
  final int frameCount;
  final DateTime? lastEventTime;

  const _BottomInfoPanel({
    required this.state,
    required this.confidence,
    required this.frameCount,
    this.lastEventTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: KioskStateBadge(
                state: state,
                confidence: confidence,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Frames: $frameCount',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                if (lastEventTime != null)
                  Text(
                    'Último evento: ${_formatTime(lastEventTime!)}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

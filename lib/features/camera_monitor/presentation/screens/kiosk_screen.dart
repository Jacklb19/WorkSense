import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/activity_overlay_painter.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/camera_preview_widget.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/state_badge_widget.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

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
    final cameras = await ref.read(availableCamerasProvider.future);
    if (mounted) {
      await ref.read(kioskProvider.notifier).initializeCamera(cameras);
      setState(() {
        _cameraStarted = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    final controller =
        ref.read(kioskProvider.notifier).cameraController;
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
    final kioskState = ref.watch(kioskProvider);
    final controller =
        ref.read(kioskProvider.notifier).cameraController;

    return Scaffold(
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
          else
            const _LoadingView(),

          // AI overlay
          if (kioskState.cameraInitialized)
            CustomPaint(
              painter: ActivityOverlayPainter(
                state: kioskState.currentState,
                confidence: kioskState.confidence,
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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(
                workstationId,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            if (isProcessing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white70),
              onPressed: () async {
                final confirmed = await _confirmExit(context);
                if (confirmed && context.mounted) {
                  await ref.read(loginNotifierProvider.notifier).signOut();
                }
              },
              tooltip: 'Salir del modo kiosco',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Salir del modo kiosco'),
            content: const Text(
                '¿Deseas cerrar sesión y salir del monitoreo?'),
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
          children: [
            KioskStateBadge(
              state: state,
              confidence: confidence,
            ),
            const Spacer(),
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

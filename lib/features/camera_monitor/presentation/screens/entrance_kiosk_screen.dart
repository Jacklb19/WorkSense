import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/entrance_kiosk_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/widgets/camera_preview_widget.dart';

class EntranceKioskScreen extends ConsumerStatefulWidget {
  const EntranceKioskScreen({super.key});

  @override
  ConsumerState<EntranceKioskScreen> createState() =>
      _EntranceKioskScreenState();
}

class _EntranceKioskScreenState extends ConsumerState<EntranceKioskScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camerasAsync = ref.watch(availableCamerasProvider);
    final kioskState = ref.watch(entranceKioskProvider);
    final kioskNotifier = ref.read(entranceKioskProvider.notifier);

    // Initial camera setup
    ref.listen(availableCamerasProvider, (previous, next) {
      if (next.hasValue && !kioskState.cameraInitialized) {
        kioskNotifier.initializeCamera(next.value!);
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Background
            if (kioskState.cameraInitialized && kioskNotifier.cameraController != null)
              CameraPreviewWidget(controller: kioskNotifier.cameraController!)
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            // Background gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.15),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/kiosk_waiting'),
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white54, size: 20),
                        ),
                        const Expanded(
                          child: Column(
                            children: [
                              Text(
                                'WORKSENSE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 4,
                                ),
                              ),
                              Text(
                                'CONTROL DE ACCESOS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Scanner frame
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        width: 240,
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary
                                .withOpacity(_pulseAnim.value * 0.9),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(_pulseAnim.value * 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: kioskState.faceDetected 
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              kioskState.identifiedEmployeeId != null 
                                  ? Icons.how_to_reg_rounded
                                  : Icons.face_rounded,
                              size: 72,
                              color: kioskState.faceDetected 
                                  ? AppColors.primary.withOpacity(0.8)
                                  : Colors.white12,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              kioskState.faceDetected
                                  ? 'MANTÉN TU ROSTRO\nQUIETO'
                                  : 'COLOCA TU ROSTRO\nEN EL MARCO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kioskState.faceDetected 
                                    ? AppColors.primary.withOpacity(0.9)
                                    : Colors.white24,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Status bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (kioskState.isScanning)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white38,
                            ),
                          )
                        else if (kioskState.identifiedEmployeeId != null)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.stateWorking, size: 22)
                        else
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          kioskState.statusMessage,
                          style: TextStyle(
                            color: kioskState.identifiedEmployeeId != null
                                ? AppColors.stateWorking
                                : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Note: camera integration requires ML Kit hardware
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'Este modo requiere hardware con cámara',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/entrance_kiosk_provider.dart';

class EntranceKioskScreen extends ConsumerStatefulWidget {
  const EntranceKioskScreen({super.key});

  @override
  ConsumerState<EntranceKioskScreen> createState() => _EntranceKioskScreenState();
}

class _EntranceKioskScreenState extends ConsumerState<EntranceKioskScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _welcomeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _welcomeScaleAnimation;
  late Animation<double> _welcomeFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initScanner();
  }

  void _initAnimations() {
    // Pulsing scanner border animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Welcome overlay animation
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _welcomeScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.elasticOut),
    );
    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeIn),
    );
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) return;

    final cameras = await availableCameras();
    if (mounted) {
      await ref.read(entranceKioskProvider.notifier).initialize(cameras);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entranceKioskProvider);
    final controller = ref.read(entranceKioskProvider.notifier).cameraController;

    // Trigger welcome animation when phase changes
    ref.listen<EntranceKioskState>(entranceKioskProvider, (prev, next) {
      if (next.phase == KioskPhase.welcome && prev?.phase != KioskPhase.welcome) {
        _welcomeController.forward(from: 0.0);
      }
      if (next.phase == KioskPhase.scanning && prev?.phase != KioskPhase.scanning) {
        _welcomeController.reset();
      }
    });

    final isWelcome = state.phase == KioskPhase.welcome;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (controller != null && controller.value.isInitialized)
            Transform.scale(
              scale: 1.1,
              child: Center(
                child: CameraPreview(controller),
              ),
            ),
            
          // Dark Overlay – heavier during welcome
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: isWelcome
                ? Colors.black.withOpacity(0.75)
                : Colors.black.withOpacity(0.4),
          ),

          // Scanner HUD (visible when scanning or cooldown)
          if (!isWelcome) _buildScannerHUD(state),

          // Welcome Overlay (visible when recognized)
          if (isWelcome) _buildWelcomeOverlay(state),
        ],
      ),
    );
  }

  Widget _buildScannerHUD(EntranceKioskState state) {
    final isDetecting = state.statusMessage.startsWith('Detectando');
    final borderColor = state.phase == KioskPhase.cooldown
        ? AppColors.warning
        : isDetecting
            ? AppColors.feedbackCapturing
            : AppColors.primary;

    return SafeArea(
      child: Column(
        children: [
          _TopBar(),
          const Spacer(),
          
          // Scanner target with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor.withOpacity(_pulseAnimation.value),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.2 * _pulseAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: state.phase == KioskPhase.cooldown
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.warning,
                          strokeWidth: 3,
                        ),
                      )
                    : null,
              );
            },
          ),
          
          const Spacer(),
          
          // Status Message
          Container(
            margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), 
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDetecting)
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.feedbackCapturing,
                    ),
                  )
                else
                  Icon(
                    state.phase == KioskPhase.scanning
                        ? Icons.face_retouching_natural
                        : Icons.hourglass_top,
                    color: Colors.white70,
                    size: 28,
                  ),
                   
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    state.statusMessage,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay(EntranceKioskState state) {
    return FadeTransition(
      opacity: _welcomeFadeAnimation,
      child: ScaleTransition(
        scale: _welcomeScaleAnimation,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success check icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF43A047),
                          Color(0xFF2E7D32),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Welcome text
                  const Text(
                    '¡ÉXITO!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Message From Kiosk Status
                  Text(
                    state.statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Workstation info card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.desktop_mac_rounded,
                            color: AppColors.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESTACIÓN DE TRABAJO',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.matchedWorkstationName ?? 'Activada',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Acceso Autorizado · Puedes pasar',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WORKSENSE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('Kiosco de Acceso Frontal', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}

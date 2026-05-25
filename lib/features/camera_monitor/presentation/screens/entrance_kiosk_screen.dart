import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
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

  /// Controla si el overlay blanco de flash está activo.
  bool _isFlashing = false;

  /// Brillo guardado antes de activar el flash — restaurado al apagarlo.
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initScanner();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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

  // ── Flash de pantalla ────────────────────────────────────────────────────────

  /// Maximiza brillo y muestra el overlay blanco para iluminar el rostro
  /// del usuario durante la verificación biométrica.
  Future<void> _activateFlash() async {
    if (_isFlashing || !mounted) return;
    setState(() => _isFlashing = true);
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {
      // screen_brightness no disponible — el overlay blanco igual ayuda.
    }
  }

  /// Restaura el brillo original y oculta el overlay blanco.
  Future<void> _restoreFlash() async {
    if (!_isFlashing) return;
    if (mounted) setState(() => _isFlashing = false);
    try {
      final saved = _originalBrightness;
      if (saved != null) {
        _originalBrightness = null;
        await ScreenBrightness().setScreenBrightness(saved);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _restoreFlash(); // Siempre restaurar brillo al salir de la pantalla.
    _pulseController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entranceKioskProvider);
    final controller = ref.read(entranceKioskProvider.notifier).cameraController;

    // ── Escuchar cambios de fase ─────────────────────────────────────────────
    ref.listen<EntranceKioskState>(entranceKioskProvider, (prev, next) {
      // Flash ON → fase verifying (blink superado, analizando identidad)
      if (next.phase == KioskPhase.verifying &&
          prev?.phase != KioskPhase.verifying) {
        _activateFlash();
      }
      // Flash OFF → salida de verifying (éxito o rechazo)
      if (next.phase != KioskPhase.verifying &&
          prev?.phase == KioskPhase.verifying) {
        _restoreFlash();
      }

      // Animación de bienvenida
      if (next.phase == KioskPhase.welcome &&
          prev?.phase != KioskPhase.welcome) {
        _welcomeController.forward(from: 0.0);
      }
      if (next.phase == KioskPhase.scanning &&
          prev?.phase != KioskPhase.scanning) {
        _welcomeController.reset();
      }
    });

    final isWelcome = state.phase == KioskPhase.welcome;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1 ── Camera Preview
          if (controller != null && controller.value.isInitialized)
            Transform.scale(
              scale: 1.1,
              child: Center(child: CameraPreview(controller)),
            ),

          // 2 ── Dark overlay (más opaco durante bienvenida)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: isWelcome
                ? AppColors.black.withValues(alpha: 0.75)
                : AppColors.black.withValues(alpha: 0.4),
          ),

          // 3 ── Flash overlay blanco (activo solo en fase verifying)
          //      Posicionado ENCIMA del overlay oscuro pero DEBAJO del HUD
          //      para que el HUD siga siendo visible durante el flash.
          //      IgnorePointer: el overlay no absorbe toques.
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isFlashing ? 0.72 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: const ColoredBox(color: AppColors.white),
            ),
          ),

          // 4 ── HUD principal (scanner o bienvenida) — siempre encima
          if (!isWelcome) _buildScannerHUD(state),
          if (isWelcome) _buildWelcomeOverlay(state),
        ],
      ),
    );
  }

  // ── Scanner HUD ──────────────────────────────────────────────────────────────

  Widget _buildScannerHUD(EntranceKioskState state) {
    final isVerifying = state.phase == KioskPhase.verifying;
    final borderColor = state.phase == KioskPhase.cooldown
        ? AppColors.warning
        : isVerifying
            ? AppColors.feedbackCapturing
            : AppColors.primary;

    return SafeArea(
      child: Column(
        children: [
          _TopBar(),
          const Spacer(),

          // Marco de escaneo con animación de pulso
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor.withValues(alpha: _pulseAnimation.value),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(
                        alpha: 0.2 * _pulseAnimation.value,
                      ),
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
                    : isVerifying
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.feedbackCapturing,
                              strokeWidth: 3,
                            ),
                          )
                        : null,
              );
            },
          ),

          const Spacer(),

          // Indicador de flash activo (pequeño chip sobre el status card)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isFlashing
                ? Padding(
                    key: const ValueKey('flash-chip'),
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacing10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingXs),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        border: Border.all(
                            color: AppColors.white30, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on_rounded,
                              color: AppColors.white70, size: AppDimensions.iconSm),
                          const SizedBox(width: AppDimensions.spacingSm),
                          Text(
                            'Iluminación activa',
                            style: TextStyle(
                              color: AppColors.white70,
                              fontSize: AppDimensions.fontCaption,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-flash')),
          ),

          // Tarjeta de estado
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacing40, left: AppDimensions.spacing20, right: AppDimensions.spacing20),
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacing32, vertical: AppDimensions.spacing24),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              border: Border.all(
                color: context.appGlassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isVerifying)
                  const SizedBox(
                    width: AppDimensions.spacingXxl,
                    height: AppDimensions.spacingXxl,
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
                    color: AppColors.white70,
                    size: AppDimensions.iconLg,
                  ),
                const SizedBox(width: AppDimensions.spacingXxl),
                Expanded(
                  child: Text(
                    state.statusMessage,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimensions.fontTitleLg,
                      fontWeight: FontWeight.bold,
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

  // ── Welcome Overlay ──────────────────────────────────────────────────────────

  Widget _buildWelcomeOverlay(EntranceKioskState state) {
    return FadeTransition(
      opacity: _welcomeFadeAnimation,
      child: ScaleTransition(
        scale: _welcomeScaleAnimation,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: AppDimensions.iconEmptyStateLg,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing32),

                  Text(
                    AppStrings.success,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimensions.fontTitle,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingLg),

                  Text(
                    state.statusMessage,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimensions.fontDisplayXs,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDimensions.spacing24),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacingXxl),
                    decoration: BoxDecoration(
                      color: context.appCard.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spacing10),
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                          ),
                          child: Icon(
                            Icons.desktop_mac_rounded,
                            color: AppColors.success,
                            size: AppDimensions.iconLg,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingXxl),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.workstation,
                              style: const TextStyle(
                                color: AppColors.white54,
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingXs),
                            Text(
                              state.matchedWorkstationName ?? 'Activada',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: AppDimensions.fontTitleLg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacing20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing20, vertical: AppDimensions.spacing10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusContainer),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: AppDimensions.iconSm,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Text(
                          'Acceso Autorizado · Puedes pasar',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: AppDimensions.fontBodyMd,
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
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppStrings.closeMonitor,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXxl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.worksenseBrand,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontDisplayXs,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                AppStrings.kioskAccessFrontal,
                style: const TextStyle(color: AppColors.white70, fontSize: AppDimensions.fontBodyMd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
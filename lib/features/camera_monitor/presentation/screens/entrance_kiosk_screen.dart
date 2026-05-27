import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/entrance_kiosk_provider.dart';

class EntranceKioskScreen extends ConsumerStatefulWidget {
  const EntranceKioskScreen({super.key});

  @override
  ConsumerState<EntranceKioskScreen> createState() =>
      _EntranceKioskScreenState();
}

class _EntranceKioskScreenState extends ConsumerState<EntranceKioskScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _welcomeController;
  late AnimationController _scanController;   // scan line sweep
  late Animation<double> _pulseAnimation;
  late Animation<double> _welcomeScaleAnimation;
  late Animation<double> _welcomeFadeAnimation;

  bool _isFlashing = false;
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initScanner();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _welcomeScaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
          parent: _welcomeController, curve: Curves.elasticOut),
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

  Future<void> _activateFlash() async {
    if (_isFlashing || !mounted) return;
    setState(() => _isFlashing = true);
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (_) {}
  }

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
    _restoreFlash();
    _pulseController.dispose();
    _welcomeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entranceKioskProvider);
    final controller =
        ref.read(entranceKioskProvider.notifier).cameraController;

    ref.listen<EntranceKioskState>(entranceKioskProvider, (prev, next) {
      if (next.phase == KioskPhase.verifying &&
          prev?.phase != KioskPhase.verifying) {
        _activateFlash();
      }
      if (next.phase != KioskPhase.verifying &&
          prev?.phase == KioskPhase.verifying) {
        _restoreFlash();
      }
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1 ── Camera preview
          if (controller != null && controller.value.isInitialized)
            Transform.scale(
              scale: 1.1,
              child: Center(child: CameraPreview(controller)),
            ),

          // 2 ── Adaptive dark overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: isWelcome
                ? Colors.black.withValues(alpha: 0.80)
                : Colors.black.withValues(alpha: 0.42),
          ),

          // 3 ── Flash overlay
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isFlashing ? 0.70 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: const ColoredBox(color: Colors.white),
            ),
          ),

          // 4 ── Scanner HUD
          if (!isWelcome)
            _ScannerHUD(
              state: state,
              isFlashing: _isFlashing,
              pulseAnimation: _pulseAnimation,
              scanAnimation: _scanController,
            ),

          // 5 ── Welcome overlay
          if (isWelcome)
            _WelcomeOverlay(
              state: state,
              scaleAnimation: _welcomeScaleAnimation,
              fadeAnimation: _welcomeFadeAnimation,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Scanner HUD
// ═══════════════════════════════════════════════════════════════════════════════

class _ScannerHUD extends StatelessWidget {
  final EntranceKioskState state;
  final bool isFlashing;
  final Animation<double> pulseAnimation;
  final AnimationController scanAnimation;

  const _ScannerHUD({
    required this.state,
    required this.isFlashing,
    required this.pulseAnimation,
    required this.scanAnimation,
  });

  Color get _phaseColor {
    switch (state.phase) {
      case KioskPhase.verifying:
        return AppColors.secondary;
      case KioskPhase.cooldown:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────────────────
          _KioskTopBar(onBack: () => context.pop()),

          const Spacer(),

          // ── Phase status chip ────────────────────────────────────────────────
          _PhaseChip(state: state, phaseColor: _phaseColor),

          const SizedBox(height: 20),

          // ── Scan frame ──────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final frameW = constraints.maxWidth * 0.62;
              final frameH = frameW * 1.4;
              return _ScanFrame(
                width: frameW,
                height: frameH,
                phaseColor: _phaseColor,
                pulseAnimation: pulseAnimation,
                scanAnimation: scanAnimation,
                isVerifying: state.phase == KioskPhase.verifying,
                isCooldown: state.phase == KioskPhase.cooldown,
              );
            },
          ),

          const Spacer(),

          // ── Flash chip ───────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isFlashing
                ? Padding(
                    key: const ValueKey('flash'),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              color: AppColors.textOnCamera70, size: 13),
                          SizedBox(width: 6),
                          Text(
                            'Iluminación activa',
                            style: TextStyle(
                              color: AppColors.textOnCamera70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-flash')),
          ),

          // ── Status card ──────────────────────────────────────────────────────
          _StatusCard(state: state, phaseColor: _phaseColor),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _KioskTopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _KioskTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),

              // Brand
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.accentLight],
                ).createShader(b),
                child: const Text(
                  'WORKSENSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const Spacer(),

              // Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'RECEPCIÓN',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phase chip ────────────────────────────────────────────────────────────────

class _PhaseChip extends StatelessWidget {
  final EntranceKioskState state;
  final Color phaseColor;
  const _PhaseChip({required this.state, required this.phaseColor});

  String get _label {
    switch (state.phase) {
      case KioskPhase.initializing:
        return 'INICIANDO SISTEMA';
      case KioskPhase.scanning:
        return 'ESCÁNER ACTIVO';
      case KioskPhase.verifying:
        return 'VERIFICANDO IDENTIDAD';
      case KioskPhase.welcome:
        return 'ACCESO AUTORIZADO';
      case KioskPhase.cooldown:
        return 'PREPARANDO ESCÁNER';
    }
  }

  IconData get _icon {
    switch (state.phase) {
      case KioskPhase.initializing:
        return Icons.hourglass_top_rounded;
      case KioskPhase.scanning:
        return Icons.radar_rounded;
      case KioskPhase.verifying:
        return Icons.manage_accounts_rounded;
      case KioskPhase.welcome:
        return Icons.check_circle_rounded;
      case KioskPhase.cooldown:
        return Icons.timer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: phaseColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.20),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.phase == KioskPhase.verifying ||
              state.phase == KioskPhase.initializing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.8, color: phaseColor),
            )
          else
            Icon(_icon, color: phaseColor, size: 13),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              color: phaseColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan frame ────────────────────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  final double width;
  final double height;
  final Color phaseColor;
  final Animation<double> pulseAnimation;
  final AnimationController scanAnimation;
  final bool isVerifying;
  final bool isCooldown;

  const _ScanFrame({
    required this.width,
    required this.height,
    required this.phaseColor,
    required this.pulseAnimation,
    required this.scanAnimation,
    required this.isVerifying,
    required this.isCooldown,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnimation, scanAnimation]),
      builder: (_, __) {
        final pulse = pulseAnimation.value;
        final scan = scanAnimation.value;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Outer glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.18 * pulse),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Corner brackets
              _CornerBracket(top: 0, left: 0,
                  isTopLeft: true, color: phaseColor, pulse: pulse),
              _CornerBracket(top: 0, right: 0,
                  isTopRight: true, color: phaseColor, pulse: pulse),
              _CornerBracket(bottom: 0, left: 0,
                  isBottomLeft: true, color: phaseColor, pulse: pulse),
              _CornerBracket(bottom: 0, right: 0,
                  isBottomRight: true, color: phaseColor, pulse: pulse),

              // Scan line (hidden during verifying/cooldown)
              if (!isVerifying && !isCooldown)
                Positioned(
                  top: scan * height,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          phaseColor.withValues(alpha: 0.85),
                          phaseColor.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.2, 0.8, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withValues(alpha: 0.55),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

              // Verifying spinner
              if (isVerifying || isCooldown)
                Center(
                  child: CircularProgressIndicator(
                    color: phaseColor,
                    strokeWidth: 2.5,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Corner bracket ────────────────────────────────────────────────────────────

class _CornerBracket extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  final Color color;
  final double pulse;

  const _CornerBracket({
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: CustomPaint(
        size: const Size(32, 32),
        painter: _BracketPainter(
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
          color: color.withValues(alpha: (0.55 + 0.45 * pulse).clamp(0, 1)),
          strokeWidth: 2.8,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTopLeft, isTopRight, isBottomLeft, isBottomRight;
  final Color color;
  final double strokeWidth;

  const _BracketPainter({
    required this.isTopLeft,
    required this.isTopRight,
    required this.isBottomLeft,
    required this.isBottomRight,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    if (isTopLeft) {
      path.moveTo(0, h);
      path.lineTo(0, 0);
      path.lineTo(w, 0);
    } else if (isTopRight) {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
    } else if (isBottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, h);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w, h);
      path.lineTo(w, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final EntranceKioskState state;
  final Color phaseColor;
  const _StatusCard({required this.state, required this.phaseColor});

  IconData get _icon {
    if (state.phase == KioskPhase.verifying) {
      return Icons.manage_accounts_rounded;
    }
    if (state.phase == KioskPhase.cooldown) {
      return Icons.hourglass_top_rounded;
    }
    return Icons.face_retouching_natural_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: phaseColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.phase == KioskPhase.verifying)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: phaseColor),
                )
              else
                Icon(_icon, color: phaseColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    state.statusMessage,
                    key: ValueKey(state.statusMessage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Welcome overlay
// ═══════════════════════════════════════════════════════════════════════════════

class _WelcomeOverlay extends StatelessWidget {
  final EntranceKioskState state;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const _WelcomeOverlay({
    required this.state,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Success ring ─────────────────────────────────────────
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.success, AppColors.successDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.45),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── ÉXITO label ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.28)),
                    ),
                    child: const Text(
                      '¡ACCESO AUTORIZADO!',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Employee name / message ───────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      state.statusMessage,
                      key: ValueKey(state.statusMessage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Workstation card ─────────────────────────────────────
                  if (state.matchedWorkstationName != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  AppColors.success.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                    Icons.desktop_mac_rounded,
                                    color: AppColors.success,
                                    size: 26),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'ESTACIÓN DE TRABAJO',
                                    style: TextStyle(
                                      color: AppColors.textOnCamera60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    state.matchedWorkstationName!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Bottom badge ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Puedes pasar · Cierra en 5 seg.',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
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

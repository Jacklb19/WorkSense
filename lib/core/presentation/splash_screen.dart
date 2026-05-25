import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

// ── Splash overlay ────────────────────────────────────────────────────────────
// Se muestra encima de toda la app durante el arranque.
// Al terminar la animación llama a [onDone] y desaparece.

class SplashOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const SplashOverlay({super.key, required this.onDone});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _master;

  // ── Intervals dentro del controller de 3400 ms ───────────────────────────
  // Ojo – aparición
  late final Animation<double> _eyeScale;
  late final Animation<double> _eyeFade;
  // Pupila – scan
  late final Animation<double> _pupilX;
  // Parpadeo
  late final Animation<double> _blink;
  // Glow
  late final Animation<double> _glow;
  // Texto
  late final Animation<double> _textFade;
  // Fade-out global
  late final Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    );

    // Ojo entra: 0 → 620 ms
    _eyeScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.18, curve: Curves.elasticOut),
      ),
    );
    _eyeFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOut),
      ),
    );

    // Glow: crece mientras aparece, se mantiene
    _glow = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.04, 0.30, curve: Curves.easeOut),
      ),
    );

    // Scan: izquierda (620-950ms) → derecha (950-1350ms) → centro (1350-1600ms)
    //   lo modelamos como una secuencia con TweenSequence
    _pupilX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 18),     // 0–18% → estático
      TweenSequenceItem(                                              // 18–28% scan izq
          tween: Tween(begin: 0.0, end: -1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 10),
      TweenSequenceItem(                                              // 28–40% scan der
          tween: Tween(begin: -1.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 12),
      TweenSequenceItem(                                              // 40–47% regresa
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 7),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 53),     // resto estático
    ]).animate(_master);

    // Parpadeo: cierra (1600-1800ms) y abre (1800-2050ms)
    _blink = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 47),      // abierto
      TweenSequenceItem(                                               // cierre
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 6),
      TweenSequenceItem(                                               // apertura
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 7),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),      // abierto resto
    ]).animate(_master);

    // Texto: 1900-2400ms
    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.56, 0.70, curve: Curves.easeOut),
      ),
    );

    // Fade-out global: 2800-3400ms
    _overlayFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.82, 1.0, curve: Curves.easeInOut),
      ),
    );

    _master.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        return Opacity(
          opacity: _overlayFade.value,
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Stack(
              children: [
                // ── Blobs decorativos ────────────────────────────────
                _BackgroundBlobs(progress: _glow.value),

                // ── Contenido centrado ───────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ojo animado
                      FadeTransition(
                        opacity: _eyeFade,
                        child: ScaleTransition(
                          scale: _eyeScale,
                          child: SizedBox(
                            width: 200,
                            height: 120,
                            child: CustomPaint(
                              painter: _EyePainter(
                                blinkAmount: _blink.value,
                                pupilX: _pupilX.value,
                                glowIntensity: _glow.value,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Marca
                      FadeTransition(
                        opacity: _textFade,
                        child: const _BrandText(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Eye painter ───────────────────────────────────────────────────────────────

class _EyePainter extends CustomPainter {
  final double blinkAmount;   // 0 abierto → 1 cerrado
  final double pupilX;        // -1 izq … +1 der
  final double glowIntensity; // 0 → 1

  const _EyePainter({
    required this.blinkAmount,
    required this.pupilX,
    required this.glowIntensity,
  });

  // Forma de ojo (lente almendrado)
  Path _eyePath(double cx, double cy, double ew, double eh) {
    final p = Path();
    p.moveTo(cx - ew / 2, cy);
    p.cubicTo(cx - ew * 0.28, cy - eh, cx + ew * 0.28, cy - eh, cx + ew / 2, cy);
    p.cubicTo(cx + ew * 0.28, cy + eh, cx - ew * 0.28, cy + eh, cx - ew / 2, cy);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ew = size.width * 0.88;
    final eh = size.height * 0.46;

    // ── Glow externo ─────────────────────────────────────────
    final glowRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ew * 1.7,
      height: eh * 3.2,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.28 * glowIntensity),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(glowRect),
    );

    // ── Parpadeo: squish vertical ─────────────────────────────
    canvas.save();
    canvas.translate(cx, cy);
    final squish = 1.0 - blinkAmount * 0.96;
    canvas.scale(1.0, squish);
    canvas.translate(-cx, -cy);

    // ── Clip al contorno del ojo ──────────────────────────────
    canvas.save();
    canvas.clipPath(_eyePath(cx, cy, ew, eh));

    // Esclerótica (blanco con tinte azul)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFDCE8FF), Color(0xFFBDD0F0)],
          radius: 1.2,
        ).createShader(Rect.fromCenter(
            center: Offset(cx, cy), width: ew, height: eh * 2)),
    );

    // Posición del iris con offset de scan
    final irisR = eh * 0.78;
    final irisCx = cx + pupilX * ew * 0.17;
    final irisCy = cy;
    final irisCenter = Offset(irisCx, irisCy);

    // Iris – gradiente radial electric blue
    canvas.drawCircle(
      irisCenter,
      irisR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.25),
          colors: [
            Color(0xFF93C5FD), // azul claro centro
            Color(0xFF4F8EF7), // electric blue mid
            Color(0xFF2563EB), // deep blue
            Color(0xFF0A1040), // borde muy oscuro
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ).createShader(
            Rect.fromCircle(center: irisCenter, radius: irisR)),
    );

    // Anillo exterior del iris (textura)
    canvas.drawCircle(
      irisCenter,
      irisR,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Anillo de seguridad biométrico – punteado
    final ringR = irisR * 0.88;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(irisCenter, ringR, dotPaint);

    // Pupila
    canvas.drawCircle(
      irisCenter,
      irisR * 0.40,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF05071A), Color(0xFF0A0E2A)],
        ).createShader(Rect.fromCircle(
            center: irisCenter, radius: irisR * 0.40)),
    );

    // Reflejo corneal (dos puntos: grande + pequeño)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(irisCx - irisR * 0.26, irisCy - irisR * 0.30),
        width: irisR * 0.34,
        height: irisR * 0.20,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.68),
    );
    canvas.drawCircle(
      Offset(irisCx + irisR * 0.18, irisCy - irisR * 0.38),
      irisR * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    canvas.restore(); // desclip

    // ── Contorno del ojo (visible encima del clip) ────────────
    canvas.drawPath(
      _eyePath(cx, cy, ew, eh),
      Paint()
        ..color = AppColors.primary.withValues(
            alpha: 0.55 + 0.35 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Pestañas superiores – 5 arcos simples
    final lashPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final t = (i + 1) / 6.0;
      final lashX = cx - ew / 2 + ew * t;
      final lashY = cy - eh * (1 - 4 * (t - 0.5) * (t - 0.5));
      canvas.drawLine(
        Offset(lashX, lashY),
        Offset(lashX + (t - 0.5) * 8, lashY - 10),
        lashPaint,
      );
    }

    canvas.restore(); // deshacer squish
  }

  @override
  bool shouldRepaint(_EyePainter old) =>
      blinkAmount != old.blinkAmount ||
      pupilX != old.pupilX ||
      glowIntensity != old.glowIntensity;
}

// ── Texto de marca ────────────────────────────────────────────────────────────

class _BrandText extends StatelessWidget {
  const _BrandText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accentLight],
          ).createShader(bounds),
          child: const Text(
            'WORKSENSE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'BIOMETRIC CONTROL INTERFACE',
          style: TextStyle(
            color: AppColors.textDisabledDark.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 32),
        // Barra de carga sutil
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.dividerDark,
            color: AppColors.primary,
            minHeight: 2,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// ── Blobs decorativos (mismos que login) ─────────────────────────────────────

class _BackgroundBlobs extends StatelessWidget {
  final double progress; // 0 → 1 (sincronizado con glow)
  const _BackgroundBlobs({required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned(
          top: -100 + 30 * math.sin(progress * math.pi),
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primary.withValues(alpha: 0.22 * progress),
                AppColors.primary.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accent.withValues(alpha: 0.18 * progress),
                AppColors.accent.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.5,
          right: size.width * 0.1,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.secondary.withValues(alpha: 0.14 * progress),
                AppColors.secondary.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

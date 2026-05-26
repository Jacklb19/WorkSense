import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _entranceController;
  late final AnimationController _bgController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginNotifierProvider);

    ref.listen<AsyncValue<bool>>(isAuthenticatedProvider, (_, next) {
      next.whenData((isAuth) {
        if (isAuth && mounted) context.go('/dashboard');
      });
    });

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AppContentConstrainer(
                  width: AppContentWidth.form,
                  center: false,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          _BrandSection(),
                          const SizedBox(height: 48),
                          _GlassCard(
                            child: _LoginForm(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onTogglePassword: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              loginState: loginState,
                              onSubmit: _handleLogin,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            'WORKSENSE SYSTEM v2.0',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: context.appOnSurfaceDisabled,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacing32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -120 + 60 * math.sin(t * 2 * math.pi),
              left: -80 + 40 * math.cos(t * 2 * math.pi),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 + 50 * math.cos(t * 2 * math.pi + 1),
              right: -60 + 30 * math.sin(t * 2 * math.pi + 1),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.30),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              right: -40 + 20 * math.sin(t * 2 * math.pi + 2),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.20),
                      AppColors.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: AppDimensions.loginLogoSize,
          height: AppDimensions.loginLogoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.loginLogoRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.remove_red_eye_rounded,
            color: context.appOnPrimary,
            size: 38,
          ),
        ),

        const SizedBox(height: AppDimensions.spacing20),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accentLight],
          ).createShader(bounds),
          child: Text(
            'WORKSENSE',
            style: TextStyle(
              color: context.appOnSurface,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'BIOMETRIC CONTROL INTERFACE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appOnSurfaceDisabled.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.appGlassBorder,
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: child,
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final LoginState loginState;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.loginState,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar sesión',
            style: theme.textTheme.titleLarge?.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Ingresa tus credenciales de acceso',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.appOnSurfaceSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: context.appOnSurface, fontSize: AppDimensions.fontSubtitle),
            decoration: _inputDecoration(
              context: context,
              hint: 'correo@empresa.com',
              label: 'Correo de acceso',
              prefixIcon: Icons.alternate_email_rounded,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
          ),

          const SizedBox(height: AppDimensions.spacingXxl),

          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: TextStyle(color: context.appOnSurface, fontSize: AppDimensions.fontSubtitle),
            decoration: _inputDecoration(
              context: context,
              hint: '••••••••',
              label: 'Contraseña',
              prefixIcon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: context.appOnSurfaceSecondary,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            onFieldSubmitted: (_) => onSubmit(),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: loginState.errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spacingLg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
child: Text(
                                loginState.errorMessage!,
                                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.error),
                              ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          _GradientButton(
            isLoading: loginState.isLoading,
            onPressed: loginState.isLoading ? null : onSubmit,
            label: 'INICIAR SESIÓN',
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required String label,
    required IconData prefixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(prefixIcon, size: 20, color: context.appOnSurfaceSecondary),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: context.appBackground.withValues(alpha: 0.5),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceDisabled),
      labelStyle: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary),
      floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        borderSide: BorderSide(color: context.appDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingXxl),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  const _GradientButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: AppColors.primaryGradient,
              )
            : null,
        color: onPressed == null ? context.appDivider : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCardLg),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: context.appOnPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
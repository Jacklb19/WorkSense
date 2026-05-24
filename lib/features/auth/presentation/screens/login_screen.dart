import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    final loginState = ref.watch(loginNotifierProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<bool>>(isAuthenticatedProvider, (_, next) {
      next.whenData((isAuth) {
        if (isAuth && mounted) context.go('/dashboard');
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.loginMaxWidth,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: AppDimensions.spacing56),
                    _buildLoginForm(theme, loginState),
                    const SizedBox(height: AppDimensions.spacing48),
                    Text(
                      'WORKSENSE SYSTEM v2.0',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: AppDimensions.loginLogoSize,
          height: AppDimensions.loginLogoSize,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                BorderRadius.circular(AppDimensions.loginLogoRadius),
            border: Border.all(
              color: AppColors.primary.withAlpha(50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(30),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.remove_red_eye,
            color: AppColors.primary,
            size: AppDimensions.iconHuge,
          ),
        ).animate().fadeIn(
              duration: AppDimensions.animEntrance,
            ).slideY(
              begin: -0.05,
              duration: AppDimensions.animEntrance,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: AppDimensions.spacing24),
        Text(
          'WORKSENSE',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
        ).animate().fadeIn(
              delay: AppDimensions.animNormal,
              duration: AppDimensions.animEntrance,
            ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'BIOMETRIC CONTROL INTERFACE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary.withAlpha(120),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
        ).animate().fadeIn(
              delay: AppDimensions.animSlow,
              duration: AppDimensions.animEntrance,
            ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme, LoginState loginState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'CORREO DE ACCESO',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ).animate().fadeIn(
                delay: AppDimensions.animSlow,
                duration: AppDimensions.animEntrance,
              ),
          const SizedBox(height: AppDimensions.spacing20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'CONTRASENNA',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ).animate().fadeIn(
                delay: AppDimensions.animEntrance,
                duration: AppDimensions.animEntrance,
              ),
          if (loginState.errorMessage != null) ...[
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(
              loginState.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacing40),
          _buildLoginButton(loginState),
        ],
      ),
    );
  }

  Widget _buildLoginButton(LoginState loginState) {
    return Container(
      width: double.infinity,
      height: AppDimensions.buttonMinHeightLg,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientButton),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: InkWell(
          onTap: loginState.isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: Center(
            child: AnimatedSwitcher(
              duration: AppDimensions.animNormal,
              child: loginState.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      key: ValueKey('text'),
                      'INICIAR SESION',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          delay: AppDimensions.animEntrance + AppDimensions.animNormal,
          duration: AppDimensions.animEntrance,
        ).moveY(
          begin: 10,
          delay: AppDimensions.animEntrance + AppDimensions.animNormal,
          duration: AppDimensions.animEntrance,
          curve: Curves.easeOutCubic,
        );
  }
}

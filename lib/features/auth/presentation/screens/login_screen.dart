import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

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
    
    ref.listen<AsyncValue<bool>>(isAuthenticatedProvider, (_, next) {
      next.whenData((isAuth) {
        if (isAuth && mounted) context.go('/dashboard');
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppDimensions.loginMaxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: AppDimensions.spacing56),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'CORREO DE ACCESO',
                              prefixIcon: Icon(Icons.alternate_email, size: AppDimensions.iconMd),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                          ),
                          const SizedBox(height: AppDimensions.spacing20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'CONTRASEÑA',
                              prefixIcon: const Icon(Icons.lock_outline, size: AppDimensions.iconMd),
                              suffixIcon: IconButton(
                                tooltip: 'Mostrar contraseña',
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: AppDimensions.iconSm),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                          ),
                          if (loginState.errorMessage != null) ...[
                            const SizedBox(height: AppDimensions.spacingXxl),
                            Text(loginState.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error, fontSize: AppDimensions.fontCaption)),
                          ],
                          const SizedBox(height: AppDimensions.spacing40),
                          FilledButton(
                            onPressed: loginState.isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                            child: loginState.isLoading
                                ? SizedBox(height: AppDimensions.progressIndicatorSize, width: AppDimensions.progressIndicatorSize, child: CircularProgressIndicator(strokeWidth: AppDimensions.progressStrokeWidth, color: AppColors.white))
                                : const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing48),
                    const Text('WORKSENSE SYSTEM v2.0', style: TextStyle(color: AppColors.white10, fontSize: AppDimensions.fontXs, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(AppDimensions.loginLogoRadius),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: const Icon(Icons.remove_red_eye, color: AppColors.primary, size: AppDimensions.iconHuge),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        const Text(
          'WORKSENSE',
          style: TextStyle(color: AppColors.white, fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w900, letterSpacing: 4),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'BIOMETRIC CONTROL INTERFACE',
          style: TextStyle(color: AppColors.primary.withValues(alpha: 0.5), fontSize: AppDimensions.fontXs, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ],
    );
  }
}

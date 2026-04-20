import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

// ─── Design tokens (Figma) ────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF13131A);
const _kCard = Color(0xFF1A1A24);
const _kBorder = Color(0xFF2A2A3A);
const _kBlue = Color(0xFF3A82F6);
const _kBlueDim = Color(0xFF1E3A6E);
const _kGreen = Color(0xFF10B981);
const _kTextPrimary = Color(0xFFEFF0F3);
const _kTextSecondary = Color(0xFF8890A4);
const _kTabInactive = Color(0xFF1E1E2D);

enum _LoginRole { admin, employee, kiosk }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  _LoginRole _selectedRole = _LoginRole.admin;

  // Pulse animation for the status dot
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseCtrl.dispose();
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
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background decorative grid
          const Positioned.fill(child: _GridBackground()),
          // Glowing orb behind card
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(color: _kBlue.withValues(alpha: 0.18), size: 400),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildCard(loginState),
                      const SizedBox(height: 20),
                      _buildStatusFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo square
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.40),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'W',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'WORKSENSE',
          style: TextStyle(
            color: _kTextPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'WORKFORCE INTELLIGENCE',
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ── Main Card ───────────────────────────────────────────────────────────────

  Widget _buildCard(LoginState loginState) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role selector
              _buildRoleSelector(),
              const SizedBox(height: 28),

              // Email label + field
              _buildFieldLabel('CORPORATE EMAIL'),
              const SizedBox(height: 8),
              _buildEmailField(),
              const SizedBox(height: 20),

              // Password label + field
              _buildFieldLabel('ACCESS KEY'),
              const SizedBox(height: 8),
              _buildPasswordField(),

              // Error message
              if (loginState.errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorBanner(loginState.errorMessage!),
              ],

              const SizedBox(height: 28),

              // Sign In button
              _buildSignInButton(loginState),

              const SizedBox(height: 16),

              // Forgot password
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: _kTextPrimary,
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

  // ── Role Selector ───────────────────────────────────────────────────────────

  Widget _buildRoleSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kTabInactive,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: _LoginRole.values.map((role) {
          final isActive = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isActive ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: _kBlue.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),]
                      : null,
                ),
                child: Center(
                  child: Text(
                    role.name[0].toUpperCase() + role.name.substring(1),
                    style: TextStyle(
                      color: isActive ? Colors.white : _kTextSecondary,
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Field Label ─────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _kTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  // ── Shared input decoration ─────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _kTextSecondary.withValues(alpha: 0.6), fontSize: 14),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }

  // ── Email Field ─────────────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      decoration: _inputDecoration(
        hint: 'name@worksense.ai',
        suffix: const Icon(
          Icons.alternate_email_rounded,
          color: _kTextSecondary,
          size: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingresa tu correo.';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
          return 'Correo inválido.';
        }
        return null;
      },
    );
  }

  // ── Password Field ──────────────────────────────────────────────────────────

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
      decoration: _inputDecoration(
        hint: '••••••••',
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _kTextSecondary,
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
        if (value.length < 6) return 'Mínimo 6 caracteres.';
        return null;
      },
    );
  }

  // ── Sign In Button ──────────────────────────────────────────────────────────

  Widget _buildSignInButton(LoginState loginState) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loginState.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          disabledBackgroundColor: _kBlueDim,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: _kBlue.withValues(alpha: 0.5),
        ),
        child: loginState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  // ── Error Banner ────────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Footer (with Cloud Icon) ─────────────────────────────────────────

  Widget _buildStatusFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing green dot
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreen,
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: _pulseAnim.value),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Cloud sync icon
          const Icon(
            Icons.cloud_done_outlined,
            color: _kBlue,
            size: 14,
          ),
          const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'SYSTEM ONLINE: INTELLIGENCE UNIT WS-9410',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Grid ──────────────────────────────────────────────────────────

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E30).withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ─── Glow Orb ─────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

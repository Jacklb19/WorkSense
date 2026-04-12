import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/app_text_field.dart';
import 'package:worksense_app/shared/widgets/primary_button.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() =>
      _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employee';
  bool _hasListened = false;
  int _currentStep = 0; // 0=Info, 1=Account, 2=Biometric

  bool get _isEditing => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeFormNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(employeeFormNotifierProvider.notifier).saveEmployee(
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          existingId: widget.employeeId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(employeeFormNotifierProvider);
    final theme = Theme.of(context);

    // Listen for successful save and navigate back
    ref.listen<EmployeeFormState>(employeeFormNotifierProvider, (_, next) {
      if (next.saved && !_hasListened) {
        _hasListened = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? AppStrings.employeeUpdated
                  : AppStrings.employeeAdded,
            ),
            backgroundColor: AppColors.stateWorking,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  Text(
                    _isEditing ? 'Edit Employee' : 'New Employee',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: formState.isLoading ? null : _handleSubmit,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: formState.isLoading
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step Progress Bar ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            right: i < 2 ? AppSpacing.xs : 0,
                          ),
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? AppColors.primary
                                : AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stepLabel('Info', 0),
                      _stepLabel('Account', 1),
                      _stepLabel('Biometric', 2),
                    ],
                  ),
                ],
              ),
            ),

            // ── Form Content ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      AppTextField(
                        label: 'Full Name',
                        hint: 'John Doe',
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.nameRequired;
                          }
                          if (value.trim().length < 2) {
                            return AppStrings.nameMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Last Name
                      AppTextField(
                        label: 'Last Name',
                        hint: 'Smith',
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.lastNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Email
                      AppTextField(
                        label: 'Email',
                        hint: 'john@company.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.emailRequired2;
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value.trim())) {
                            return AppStrings.emailInvalid2;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Password
                      AppTextField(
                        label: 'Password',
                        hint: '••••••••',
                        obscure: true,
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!_isEditing &&
                              (value == null || value.isEmpty)) {
                            return AppStrings.passwordRequiredNew;
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return AppStrings.passwordMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Role
                      Text(
                        'ROLE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Row(
                          children: ['employee', 'admin'].map((role) {
                            final isSelected = _selectedRole == role;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRole = role),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      role == 'employee'
                                          ? 'Employee'
                                          : 'Admin',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ── Error ──────────────────────────────
                      if (formState.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  formState.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.x3l),

                      // Submit
                      PrimaryButton(
                        label: _isEditing ? 'Save Changes' : 'Add Employee',
                        loading: formState.isLoading,
                        onTap: formState.isLoading ? null : _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String text, int step) {
    final isActive = step <= _currentStep;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
    );
  }
}

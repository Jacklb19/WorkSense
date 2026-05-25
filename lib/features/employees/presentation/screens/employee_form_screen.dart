import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/domain/entities/app_role.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/utils/app_snack_bar.dart';
import 'package:worksense_app/shared/widgets/styled/app_section_header.dart';
import 'package:worksense_app/shared/widgets/loading_indicator.dart';

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
  AppRole _selectedRole = AppRole.employee;
  String? _selectedShiftId;
  bool _hasListened = false;
  bool _dataLoaded = false;

  bool get _isEditing => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeFormNotifierProvider.notifier).reset();
      _loadExistingEmployee();
    });
  }

  Future<void> _loadExistingEmployee() async {
    if (!_isEditing || _dataLoaded) return;

    try {
      final employees = await ref.read(adminEmployeesProvider.future);
      final employee =
          employees.where((e) => e.id == widget.employeeId).firstOrNull;

      if (employee != null && mounted) {
        setState(() {
          _nameController.text = employee.name;
          _lastNameController.text = employee.lastName;
          _emailController.text = employee.email;
          _selectedRole = employee.role;
          _selectedShiftId = employee.shiftId;
          _dataLoaded = true;
        });
      }
    } catch (_) {
      // Keep the form editable even if the preload fails.
    }
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
          shiftId: _selectedShiftId,
          existingId: widget.employeeId,
        );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.deleteEmployeeTitle),
            content: const Text(AppStrings.deleteEmployeeConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  AppStrings.delete,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await ref
        .read(employeeFormNotifierProvider.notifier)
        .deleteEmployee(widget.employeeId!);

    if (mounted) {
      AppSnackBar.showSuccess(context, AppStrings.employeeDeleted);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(employeeFormNotifierProvider);
    final shiftsAsync = ref.watch(shiftsProvider);

    ref.listen<EmployeeFormState>(employeeFormNotifierProvider, (_, next) {
      if (next.saved && !_hasListened) {
        _hasListened = true;
        AppSnackBar.showSuccess(context, _isEditing ? AppStrings.employeeUpdated : AppStrings.employeeAdded);
        context.pop();
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(_isEditing ? 'Editar Perfil' : 'Nuevo Ingreso'),
          ),
          SliverPadding(
            padding: AppSpacing.formPadding(context),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppSpacing.formMaxWidth(context)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const AppSectionHeader(title: 'IDENTIDAD'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppDimensions.spacing40),
                    const AppSectionHeader(title: 'CREDENCIALES'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@'))
                              ? AppStrings.emailInvalid2
                              : null,
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: AppDimensions.spacingXxl),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: AppStrings.passwordTempLabel,
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6)
                                ? AppStrings.passwordMinLength
                                : null,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacingXxl),
                    DropdownButtonFormField<AppRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: AppStrings.roleLabel,
                        prefixIcon: Icon(Icons.security_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AppRole.employee,
                          child: Text(AppStrings.roleEmployee),
                        ),
                        DropdownMenuItem(
                          value: AppRole.admin,
                          child: Text(AppStrings.roleAdmin),
                        ),
                        DropdownMenuItem(
                          value: AppRole.cameraMonitor,
                          child: Text('Monitor de camara'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    shiftsAsync.when(
                      data: (shifts) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedShiftId,
                          decoration: const InputDecoration(
                            labelText: 'Turno / Horario',
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin Asignar (Libre)'),
                            ),
                            ...shifts.map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.name} (${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')})',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedShiftId = val),
                        );
                      },
loading: () =>
                           const Center(child: AppLoadingIndicator()),
                      error: (e, _) => Text(
                        'Error cargando turnos: $e',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing56),
                    FilledButton(
                      onPressed: formState.isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg),
                      ),
                      child: formState.isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: AppDimensions.progressStrokeWidth,
                            )
: Text(
                            _isEditing
                                ? AppStrings.saveChanges
                                : AppStrings.registerEmployee,
                          ),
                    ),
                    if (formState.errorMessage != null) ...[
                      const SizedBox(height: AppDimensions.spacingXxl),
                      Text(
                        formState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: AppDimensions.fontBody,
                        ),
                      ),
                    ],
                    if (_isEditing) ...[
                      const SizedBox(height: AppDimensions.spacing32),
                      OutlinedButton.icon(
                        onPressed: formState.isLoading ? null : _handleDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'ELIMINAR EMPLEADO',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
                          side: const BorderSide(color: AppColors.error),
),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
}

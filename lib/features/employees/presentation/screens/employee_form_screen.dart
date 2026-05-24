import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/styled/app_section_header.dart';
import '../../../dashboard/presentation/providers/shifts_provider.dart';
import '../providers/employees_provider.dart';

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
          _selectedShiftId = employee.shiftId;
          _dataLoaded = true;
        });
      }
    } catch (_) {}
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
    final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar colaborador'),
            content: const Text(
                'Estas seguro de que deseas eliminar permanentemente este colaborador? Esta accion eliminara su acceso y todos sus datos de asistencia.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar',
                    style: TextStyle(color: AppColors.error)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador eliminado'),
          backgroundColor: AppColors.success,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Colaborador actualizado'
                : 'Colaborador registrado'),
            backgroundColor: AppColors.success,
          ),
        );
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
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.formHorizontalPadding,
              vertical: AppDimensions.formVerticalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppSectionHeader(title: 'IDENTIDAD'),
                    const SizedBox(height: AppDimensions.spacing20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Campo requerido'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Campo requerido'
                          : null,
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: AppDimensions.spacing40),
                      const AppSectionHeader(title: 'CREDENCIALES'),
                      const SizedBox(height: AppDimensions.spacing20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email invalido'
                            : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contrasenna Temporal',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6)
                                ? 'Minimo 6 caracteres'
                                : null,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacingXxl),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.security_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'employee', child: Text('Empleado')),
                        DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    shiftsAsync.when(
                      data: (shifts) {
                        return DropdownButtonFormField<String>(
                          value: _selectedShiftId,
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
                                    '${s.name} (${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')})'),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedShiftId = val),
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) => Text(
                        'Error cargando turnos: $e',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing56),
                    FilledButton(
                      onPressed:
                          formState.isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          AppDimensions.buttonMinHeightLg,
                        ),
                      ),
                      child: formState.isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2)
                          : Text(_isEditing
                              ? 'GUARDAR CAMBIOS'
                              : 'REGISTRAR EMPLEADO'),
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
                        onPressed: formState.isLoading
                            ? null
                            : _handleDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        label: const Text(
                          'ELIMINAR EMPLEADO',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 50),
                          side: const BorderSide(
                              color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

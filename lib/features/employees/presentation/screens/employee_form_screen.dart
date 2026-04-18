import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
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

  bool get _isEditing => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    // Reset form state when screen opens
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

    ref.listen<EmployeeFormState>(employeeFormNotifierProvider, (_, next) {
      if (next.saved && !_hasListened) {
        _hasListened = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Colaborador actualizado' : 'Colaborador registrado'),
            backgroundColor: Colors.green,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('IDENTIDAD', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 40),
                    Text('CREDENCIALES', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña Temporal', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => (!_isEditing && (v == null || v.length < 6)) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.security_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'employee', child: Text('Empleado')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 56),
                    FilledButton(
                      onPressed: formState.isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                      child: formState.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                        : Text(_isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR EMPLEADO'),
                    ),
                    if (formState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(formState.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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

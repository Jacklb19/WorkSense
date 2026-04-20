import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

class EmployeesListScreen extends ConsumerWidget {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.employees),
      ),
      body: employeesAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return const _EmptyEmployeesView();
          }

          return ListView.separated(
            itemCount: employees.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(employee.name),
                subtitle: Text(
                  'Registrado el ${DateFormat('dd/MM/yyyy').format(employee.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                onTap: () => _navigateToEdit(context, ref, employee.id),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        _navigateToEdit(context, ref, employee.id);
                        break;
                      case 'delete':
                        await _confirmAndDelete(
                            context, ref, employee.id, employee.name);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.delete,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.employeeNew);
          ref.invalidate(adminEmployeesProvider);
        },
        tooltip: AppStrings.addEmployee,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, WidgetRef ref, String employeeId) {
    final route = AppRoutes.employeeEdit.replaceFirst(':employeeId', employeeId);
    context.push(route).then((_) {
      ref.invalidate(adminEmployeesProvider);
    });
  }

  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.deleteEmployee),
            content:
                Text('¿Eliminar a "$name"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(employeeFormNotifierProvider.notifier)
          .deleteEmployee(id);
      ref.invalidate(adminEmployeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" eliminado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _EmptyEmployeesView extends StatelessWidget {
  const _EmptyEmployeesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noEmployees,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.addEmployeeHint,
            style: TextStyle(color: AppColors.grey400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

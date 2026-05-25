import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(adminEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.employees),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.cardDark,
              ),
            ),
          ),
        ),
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
          // Apply search filter
          final filtered = _query.isEmpty
              ? employees
              : employees
                  .where((e) =>
                      e.displayName.toLowerCase().contains(_query) ||
                      e.email.toLowerCase().contains(_query))
                  .toList();

          if (employees.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: AppStrings.noEmployees,
              subtitle: AppStrings.addEmployeeHint,
            );
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off,
                      size: 48, color: AppColors.grey300),
                  const SizedBox(height: 12),
                  Text(
                    'Sin resultados para "$_query"',
                    style: const TextStyle(
                        color: AppColors.grey500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final employee = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    employee.displayName.isNotEmpty
                        ? employee.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(employee.displayName),
                subtitle: Text(
                  employee.email.isNotEmpty
                      ? employee.email
                      : 'Registrado el ${DateFormat('dd/MM/yyyy').format(employee.createdAt)}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontCaption,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => _navigateToEdit(context, ref, employee.id),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        _navigateToEdit(context, ref, employee.id);
                      case 'delete':
                        await _confirmAndDelete(
                            context, ref, employee.id, employee.displayName);
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
                          SizedBox(width: AppDimensions.spacingMd),
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
                          SizedBox(width: AppDimensions.spacingMd),
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
    final route =
        AppRoutes.employeeEdit.replaceFirst(':employeeId', employeeId);
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
            content: Text(
                'Eliminar a "$name"? Esta accion no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
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

      // Force sync so Supabase reflects the delete before reload
      await ref.read(syncNotifierProvider.notifier).sync();

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

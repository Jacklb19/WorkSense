import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/core/theme/app_radius.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/shared/widgets/ws_card.dart';
import 'package:worksense_app/shared/widgets/avatar_initials.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:intl/intl.dart';

class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  String _searchQuery = '';
  int _filterIndex = 0; // 0=All, 1=Active, 2=Enrolled

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          // ── Top Bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Team', style: theme.textTheme.titleMedium),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/employees/new');
                      ref.invalidate(adminEmployeesProvider);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: theme.textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Search Bar ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.focusColor, width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Filter Chips ───────────────────────────
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: List.generate(3, (i) {
                  final labels = ['All', 'Active', 'Enrolled'];
                  final isSelected = _filterIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.infoBg
                              : Colors.transparent,
                          borderRadius: AppRadius.pillAll,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderColor,
                          ),
                        ),
                        child: Text(
                          labels[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Employee List ──────────────────────────
          Expanded(
            child: employeesAsync.when(
              loading: () => const AppLoadingWidget(),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error: $error',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(adminEmployeesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (employees) {
                // Filter by search query
                final filtered = employees.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyEmployeesView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final employee = filtered[index];
                    final initials = employee.name.length >= 2
                        ? employee.name.substring(0, 2).toUpperCase()
                        : employee.name.toUpperCase();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: WsCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: AppRadius.lgAll,
                          onTap: () {
                            // Navigate to detail if route exists
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                AvatarInitials(
                                  initials: initials,
                                  bg: AppColors.primaryDark,
                                  size: 32,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Registered ${DateFormat('dd/MM/yy').format(employee.createdAt)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                // Enrolled badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: AppRadius.pillAll,
                                  ),
                                  child: Text(
                                    'Enrolled',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.stateWorking,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  color: AppColors.elevated,
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final confirmed = await _confirmDelete(
                                          context, employee.name);
                                      if (confirmed) {
                                        await ref
                                            .read(employeeFormNotifierProvider
                                                .notifier)
                                            .deleteEmployee(employee.id);
                                        ref.invalidate(adminEmployeesProvider);
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: AppColors.error,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppStrings.delete,
                                            style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.elevated,
            title: Text(AppStrings.deleteEmployee),
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
  }
}

class _EmptyEmployeesView extends StatelessWidget {
  const _EmptyEmployeesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.noEmployees,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.addEmployeeHint,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

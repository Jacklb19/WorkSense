import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = userState?.role == AppRole.admin ||
        userState?.role == AppRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'TAREAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Pendientes'),
            Tab(text: 'En progreso'),
            Tab(text: 'Completadas'),
          ],
          onTap: (i) {
            setState(() {
              _filterStatus = switch (i) {
                1 => TaskStatus.pending,
                2 => TaskStatus.inProgress,
                3 => TaskStatus.done,
                _ => null,
              };
            });
          },
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => context.push(AppRoutes.taskNew),
            ),
        ],
      ),
      body: isAdmin
          ? _AdminTasksList(filterStatus: _filterStatus)
          : _EmployeeTasksList(filterStatus: _filterStatus),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.taskNew),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ── Admin view ─────────────────────────────────────────────────────────────────

class _AdminTasksList extends ConsumerWidget {
  final TaskStatus? filterStatus;

  const _AdminTasksList({this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(companyTasksProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (tasks) {
        final filtered = filterStatus != null
            ? tasks.where((t) => t.status == filterStatus).toList()
            : tasks;

        final employees = employeesAsync.valueOrNull ?? [];
        final employeeMap = {for (final e in employees) e.id: e};

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(syncNotifierProvider.notifier).sync(),
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            child: ListView(
              children: [_EmptyState(filterStatus: filterStatus, isAdmin: true)],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(syncNotifierProvider.notifier).sync(),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final task = filtered[i];
              final emp = employeeMap[task.assignedToId];
              return TaskCard(
                task: task,
                employeeName: emp?.displayName,
                isAdmin: true,
                onTap: () => context.push(
                  AppRoutes.taskEdit.replaceFirst(':taskId', task.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Employee view ──────────────────────────────────────────────────────────────

class _EmployeeTasksList extends ConsumerWidget {
  final TaskStatus? filterStatus;

  const _EmployeeTasksList({this.filterStatus});

  Future<void> _doRefresh(WidgetRef ref) =>
      ref.read(syncNotifierProvider.notifier).sync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (tasks) {
        final filtered = filterStatus != null
            ? tasks.where((t) => t.status == filterStatus).toList()
            : tasks;

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _doRefresh(ref),
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceDark,
            child: ListView(
              children: [_EmptyState(filterStatus: filterStatus, isAdmin: false)],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _doRefresh(ref),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final task = filtered[i];
              return TaskCard(
                task: task,
                isAdmin: false,
                onStatusChanged: (newStatus) =>
                    _changeStatus(context, ref, task, newStatus),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    TaskStatus newStatus,
  ) async {
    await ref.read(tasksNotifierProvider.notifier).updateStatus(task.id, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea marcada como "${newStatus.label}"'),
          backgroundColor: newStatus.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final TaskStatus? filterStatus;
  final bool isAdmin;

  const _EmptyState({this.filterStatus, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final message = filterStatus != null
        ? 'No hay tareas ${filterStatus!.label.toLowerCase()}'
        : isAdmin
            ? 'No has asignado tareas aún'
            : 'No tienes tareas asignadas';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          if (isAdmin && filterStatus == null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.taskNew),
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text(
                'Crear primera tarea',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

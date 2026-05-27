import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/task_repository_impl.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/domain/repositories/task_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/features/notifications/data/notification_repository.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return TaskRepositoryImpl(db, syncRepo);
});

// ── Stream providers ──────────────────────────────────────────────────────────

/// Admin: todas las tareas de la empresa
final companyTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) return Stream.value([]);
  return repo.watchTasksByCompany(companyId);
});

/// Employee: solo mis tareas
final myTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserProvider).valueOrNull?.user?.id;
  if (userId == null) return Stream.value([]);
  return repo.watchTasksByEmployee(userId);
});

/// Conteo de tareas pendientes del empleado (badge)
final myPendingTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(myTasksProvider).valueOrNull ?? [];
  return tasks
      .where((t) =>
          t.status == TaskStatus.pending || t.status == TaskStatus.inProgress)
      .length;
});

/// Conteo de tareas pendientes de la empresa (badge admin)
final companyPendingTasksCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(companyTasksProvider).valueOrNull ?? [];
  return tasks
      .where((t) =>
          t.status == TaskStatus.pending || t.status == TaskStatus.inProgress)
      .length;
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repo;
  final String _companyId;

  TasksNotifier(this._repo, this._companyId)
      : super(const AsyncValue.data(null));

  Future<void> saveTask(TaskItem task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.saveTask(task));
    if (state is AsyncData) {
      try {
        await NotificationRepository.instance.pushToUser(
          recipientId: task.assignedToId,
          companyId: _companyId,
          type: 'task_assigned',
          title: '📋 Nueva tarea asignada',
          body: task.title,
          route: '/tasks',
        );
      } catch (_) {}
    }
  }

  Future<void> updateStatus(
    String taskId,
    TaskStatus status, {
    String? taskTitle,
    String? assignedToId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateTaskStatus(taskId, status));
    if (state is AsyncData) {
      try {
        if (status == TaskStatus.done) {
          // Notify admin that a task was completed
          await NotificationRepository.instance.pushToAdmins(
            companyId: _companyId,
            type: 'task_completed',
            title: '✅ Tarea completada',
            body: taskTitle != null
                ? '"$taskTitle" fue marcada como completada'
                : 'Una tarea fue marcada como completada',
            route: '/tasks',
          );
        }
      } catch (_) {}
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteTask(taskId));
  }
}

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final companyId =
      ref.read(currentUserProvider).valueOrNull?.companyId ?? '';
  return TasksNotifier(repo, companyId);
});

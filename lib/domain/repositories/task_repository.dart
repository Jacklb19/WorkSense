import 'package:worksense_app/domain/entities/task_item.dart';

abstract interface class TaskRepository {
  // ── Lecturas ──────────────────────────────────────────────────────────────
  Future<List<TaskItem>> getTasksByCompany(String companyId);
  Future<List<TaskItem>> getTasksByEmployee(String employeeId);
  Stream<List<TaskItem>> watchTasksByCompany(String companyId);
  Stream<List<TaskItem>> watchTasksByEmployee(String employeeId);
  Future<TaskItem?> getTaskById(String id);

  // ── Escrituras ────────────────────────────────────────────────────────────
  Future<void> saveTask(TaskItem task);
  Future<void> updateTaskStatus(String taskId, TaskStatus status);
  Future<void> deleteTask(String taskId);
}

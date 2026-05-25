import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/domain/repositories/task_repository.dart';
import 'sync_repository_impl.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;
  final SyncRepositoryImpl _syncRepo;

  TaskRepositoryImpl(this._db, this._syncRepo);

  @override
  Future<List<TaskItem>> getTasksByCompany(String companyId) async {
    final rows = await _db.getTasksByCompany(companyId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<TaskItem>> getTasksByEmployee(String employeeId) async {
    final rows = await _db.getTasksByEmployee(employeeId);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<TaskItem>> watchTasksByCompany(String companyId) =>
      _db.watchTasksByCompany(companyId).map((rows) => rows.map(_mapToEntity).toList());

  @override
  Stream<List<TaskItem>> watchTasksByEmployee(String employeeId) =>
      _db.watchTasksByEmployee(employeeId).map((rows) => rows.map(_mapToEntity).toList());

  @override
  Future<TaskItem?> getTaskById(String id) async {
    final row = await _db.getTaskById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    await _db.transaction(() async {
      await _db.insertTask(TaskRecordsCompanion(
        id: Value(task.id),
        companyId: Value(task.companyId),
        assignedToId: Value(task.assignedToId),
        createdById: Value(task.createdById),
        title: Value(task.title),
        description: Value(task.description),
        status: Value(task.status.raw),
        priority: Value(task.priority.raw),
        dueDate: Value(task.dueDate),
        createdAt: Value(task.createdAt),
        updatedAt: Value(task.updatedAt),
      ));

      await _syncRepo.enqueue(
        targetTable: 'tasks',
        operation: 'UPSERT',
        recordId: task.id,
        payload: task.toMap(),
      );
    });
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _db.transaction(() async {
      await _db.updateTaskStatus(taskId, status.raw);

      await _syncRepo.enqueue(
        targetTable: 'tasks',
        operation: 'PATCH',
        recordId: taskId,
        payload: {
          'status': status.raw,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _db.transaction(() async {
      await _db.deleteTask(taskId);

      await _syncRepo.enqueue(
        targetTable: 'tasks',
        operation: 'DELETE',
        recordId: taskId,
        payload: {},
      );
    });
  }

  TaskItem _mapToEntity(TaskData row) {
    return TaskItem(
      id: row.id,
      companyId: row.companyId,
      assignedToId: row.assignedToId,
      createdById: row.createdById,
      title: row.title,
      description: row.description,
      status: TaskStatus.fromRaw(row.status),
      priority: TaskPriority.fromRaw(row.priority),
      dueDate: row.dueDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

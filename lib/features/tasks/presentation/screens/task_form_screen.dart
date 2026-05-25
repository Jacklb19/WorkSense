import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
// adminEmployeesProvider hace merge local + remoto Supabase, por lo que
// incluye empleados recién creados aunque aún no hayan sincronizado a Drift.
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  /// Si se pasa [taskId], se edita la tarea existente; si no, se crea una nueva.
  final String? taskId;

  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _assignedToId;
  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  TaskStatus _status = TaskStatus.pending;
  bool _loading = false;

  TaskItem? _original;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
    }
  }

  Future<void> _loadTask() async {
    final repo = ref.read(taskRepositoryProvider);
    final task = await repo.getTaskById(widget.taskId!);
    if (task != null && mounted) {
      setState(() {
        _original = task;
        _titleController.text = task.title;
        _descController.text = task.description ?? '';
        _assignedToId = task.assignedToId;
        _priority = task.priority;
        _dueDate = task.dueDate;
        _status = task.status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // adminEmployeesProvider = merge local Drift + Supabase remoto.
    // Garantiza que los empleados recién creados aparezcan aunque aún
    // no hayan sincronizado a la DB local.
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final isEdit = widget.taskId != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          isEdit ? 'EDITAR TAREA' : 'NUEVA TAREA',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_off_outlined,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo cargar la lista de empleados.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verifica tu conexión e intenta de nuevo.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(adminEmployeesProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        data: (employees) => _buildForm(context, employees),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Employee> employees) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ────────────────────────────────────────────────────
            const _SectionLabel('Título'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('¿Qué debe hacerse?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
              maxLength: 120,
            ),

            const SizedBox(height: 20),

            // ── Descripción ───────────────────────────────────────────────
            const _SectionLabel('Descripción (opcional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Detalles adicionales…'),
              maxLines: 3,
              maxLength: 400,
            ),

            const SizedBox(height: 20),

            // ── Asignar empleado ──────────────────────────────────────────
            const _SectionLabel('Asignar a'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _assignedToId,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Selecciona un empleado'),
              items: employees.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text(e.displayName),
                );
              }).toList(),
              validator: (v) =>
                  v == null ? 'Selecciona un empleado' : null,
              onChanged: (v) => setState(() => _assignedToId = v),
            ),

            const SizedBox(height: 20),

            // ── Prioridad ─────────────────────────────────────────────────
            const _SectionLabel('Prioridad'),
            const SizedBox(height: 8),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),

            const SizedBox(height: 20),

            // ── Fecha límite ──────────────────────────────────────────────
            const _SectionLabel('Fecha límite (opcional)'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDueDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.glassBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                          : 'Sin fecha límite',
                      style: TextStyle(
                        color:
                            _dueDate != null ? Colors.white : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close,
                            color: Colors.white38, size: 16),
                      ),
                  ],
                ),
              ),
            ),

            // ── Status (edit only) ────────────────────────────────────────
            if (widget.taskId != null) ...[
              const SizedBox(height: 20),
              const _SectionLabel('Estado'),
              const SizedBox(height: 8),
              _StatusSelector(
                selected: _status,
                onChanged: (s) => setState(() => _status = s),
              ),
            ],

            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : () => _submit(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.taskId != null ? 'Guardar cambios' : 'Crear tarea',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    final companyId = user?.companyId ?? '';
    final now = DateTime.now();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final task = TaskItem(
      id: _original?.id ?? const Uuid().v4(),
      companyId: companyId,
      assignedToId: _assignedToId!,
      createdById: _original?.createdById ?? (user?.user?.id ?? ''),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _dueDate,
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(tasksNotifierProvider.notifier).saveTask(task);

    if (!mounted) return;
    setState(() => _loading = false);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(widget.taskId != null
            ? 'Tarea actualizada'
            : 'Tarea creada y asignada'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Eliminar tarea',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar esta tarea?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      await ref
          .read(tasksNotifierProvider.notifier)
          .deleteTask(widget.taskId!);
      if (!mounted) return;
      navigator.pop();
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        counterStyle: const TextStyle(color: Colors.white38),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? p.color.withValues(alpha: 0.2)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? p.color
                      : AppColors.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(p.icon,
                      size: 16,
                      color: isSelected ? p.color : Colors.white38),
                  const SizedBox(height: 4),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected ? p.color : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final TaskStatus selected;
  final ValueChanged<TaskStatus> onChanged;

  const _StatusSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      TaskStatus.pending,
      TaskStatus.inProgress,
      TaskStatus.done,
      TaskStatus.cancelled,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final isSelected = s == selected;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? s.color.withValues(alpha: 0.2)
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? s.color : AppColors.glassBorder,
              ),
            ),
            child: Text(
              s.label,
              style: TextStyle(
                color: isSelected ? s.color : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

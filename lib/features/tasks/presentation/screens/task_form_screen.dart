import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/entities/task_item.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/styled/app_content_constrainer.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
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
    final employeesAsync = ref.watch(adminEmployeesProvider);
    final isEdit = widget.taskId != null;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text(
          isEdit ? 'EDITAR TAREA' : 'NUEVA TAREA',
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: AppDimensions.fontSubtitle,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appOnSurface),
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
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_off_outlined,
                    color: AppColors.error, size: 40),
                const SizedBox(height: AppDimensions.spacingLg),
                Text(
                  'No se pudo cargar la lista de empleados.',
                  style: TextStyle(
                      color: context.appOnSurface,
                      fontSize: AppDimensions.fontSubtitle,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Verifica tu conexión e intenta de nuevo.',
                  style: TextStyle(color: context.appOnSurfaceSecondary, fontSize: AppDimensions.fontBody),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacing20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(adminEmployeesProvider),
                  icon: const Icon(Icons.refresh, size: AppDimensions.spacingXxl),
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
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      child: AppContentConstrainer(
        width: AppContentWidth.form,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Título'),
              const SizedBox(height: AppDimensions.spacingMd),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: context.appOnSurface),
                decoration: _inputDecoration(context, '¿Qué debe hacerse?'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
                maxLength: 120,
              ),

              const SizedBox(height: AppDimensions.spacing20),

              const _SectionLabel('Descripción (opcional)'),
              const SizedBox(height: AppDimensions.spacingMd),
              TextFormField(
                controller: _descController,
                style: TextStyle(color: context.appOnSurface),
                decoration: _inputDecoration(context, 'Detalles adicionales…'),
                maxLines: 3,
                maxLength: 400,
              ),

              const SizedBox(height: AppDimensions.spacing20),

              const _SectionLabel('Asignar a'),
              const SizedBox(height: AppDimensions.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _assignedToId,
                dropdownColor: context.appSurface,
                style: TextStyle(color: context.appOnSurface),
                decoration: _inputDecoration(context, 'Selecciona un empleado'),
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

              const SizedBox(height: AppDimensions.spacing20),

              const _SectionLabel('Prioridad'),
              const SizedBox(height: AppDimensions.spacingMd),
              _PrioritySelector(
                selected: _priority,
                onChanged: (p) => setState(() => _priority = p),
              ),

              const SizedBox(height: AppDimensions.spacing20),

              const _SectionLabel('Fecha límite (opcional)'),
              const SizedBox(height: AppDimensions.spacingMd),
              Semantics(
                button: true,
                label: 'Seleccionar fecha límite',
                child: InkWell(
                  onTap: () => _pickDueDate(context),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingXl),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appGlassBorder),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    ),
                    child: Row(
                      children: [
Icon(Icons.event_outlined,
                            color: context.appOnSurfaceSecondary, size: 18),
                         const SizedBox(width: AppDimensions.spacingXl),
                         Text(
                           _dueDate != null
                               ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                               : 'Sin fecha límite',
                           style: TextStyle(
                             color:
                                 _dueDate != null ? context.appOnSurface : context.appOnSurfaceDisabled,
                            fontSize: AppDimensions.fontBodyMd,
                          ),
                        ),
                        const Spacer(),
                        if (_dueDate != null)
                          Semantics(
                            button: true,
                            label: 'Limpiar fecha',
                            child: InkWell(
                              onTap: () => setState(() => _dueDate = null),
                              borderRadius: BorderRadius.circular(AppDimensions.spacingXs),
                              child: Icon(Icons.close,
                                  color: context.appOnSurfaceDisabled, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.taskId != null) ...[
                const SizedBox(height: AppDimensions.spacing20),
                const _SectionLabel('Estado'),
                const SizedBox(height: AppDimensions.spacingMd),
                _StatusSelector(
                  selected: _status,
                  onChanged: (s) => setState(() => _status = s),
                ),
              ],

              const SizedBox(height: AppDimensions.spacing32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : () => _submit(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          widget.taskId != null ? 'Guardar cambios' : 'Crear tarea',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: AppDimensions.fontSubtitle),
                        ),
                ),
              ),
            ],
          ),
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
        backgroundColor: context.appSurface,
        title: Text('Eliminar tarea',
            style: TextStyle(color: context.appOnSurface)),
        content: Text('¿Seguro que quieres eliminar esta tarea?',
            style: TextStyle(color: context.appOnSurfaceSecondary)),
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

  InputDecoration _inputDecoration(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appOnSurfaceDisabled),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          borderSide: BorderSide(color: context.appGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          borderSide: BorderSide(color: context.appGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        counterStyle: TextStyle(color: context.appOnSurfaceDisabled),
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
      style: TextStyle(
        color: context.appOnSurfaceSecondary,
        fontSize: AppDimensions.fontCaption,
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
          child: Semantics(
            button: true,
            label: p.label,
            child: InkWell(
              onTap: () => onChanged(p),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              child: Container(
                margin: const EdgeInsets.only(right: AppDimensions.spacingMd),
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: isSelected
                      ? p.color.withValues(alpha: 0.2)
                      : context.appSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  border: Border.all(
                    color: isSelected
                        ? p.color
                        : context.appGlassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(p.icon,
                        size: AppDimensions.spacingXxl,
                        color: isSelected ? p.color : context.appOnSurfaceDisabled),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      p.label,
                      style: TextStyle(
                        color: isSelected ? p.color : context.appOnSurfaceDisabled,
                        fontSize: AppDimensions.spacing10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
      spacing: AppDimensions.spacingMd,
      runSpacing: AppDimensions.spacingMd,
      children: statuses.map((s) {
        final isSelected = s == selected;
        return Semantics(
          button: true,
          label: s.label,
          child: InkWell(
            onTap: () => onChanged(s),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl, vertical: AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: isSelected
                    ? s.color.withValues(alpha: 0.2)
                    : context.appSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(
                  color: isSelected ? s.color : context.appGlassBorder,
                ),
              ),
              child: Text(
                s.label,
                style: TextStyle(
                  color: isSelected ? s.color : context.appOnSurfaceDisabled,
                  fontSize: AppDimensions.fontCaption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
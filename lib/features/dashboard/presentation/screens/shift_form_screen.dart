import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:uuid/uuid.dart';

class ShiftFormScreen extends ConsumerStatefulWidget {
  const ShiftFormScreen({super.key});

  @override
  ConsumerState<ShiftFormScreen> createState() => _ShiftFormScreenState();
}

class _ShiftFormScreenState extends ConsumerState<ShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _hasBreak = false;
  TimeOfDay _breakStartTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _breakEndTime = const TimeOfDay(hour: 14, minute: 0);
  bool _hasListened = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate end > start
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      _showError('La hora de salida debe ser posterior a la de entrada');
      return;
    }

    // Validate break times if enabled
    if (_hasBreak) {
      final breakStart = _breakStartTime.hour * 60 + _breakStartTime.minute;
      final breakEnd = _breakEndTime.hour * 60 + _breakEndTime.minute;

      if (breakEnd <= breakStart) {
        _showError('El fin de receso debe ser posterior al inicio');
        return;
      }
      if (breakStart < startMinutes || breakEnd > endMinutes) {
        _showError('El receso debe estar dentro del horario laboral');
        return;
      }
    }

    final id = const Uuid().v4();
    await ref.read(shiftFormNotifierProvider.notifier).saveShift(
      id: id,
      name: _nameController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      breakStartHour: _hasBreak ? _breakStartTime.hour : null,
      breakStartMinute: _hasBreak ? _breakStartTime.minute : null,
      breakEndHour: _hasBreak ? _breakEndTime.hour : null,
      breakEndMinute: _hasBreak ? _breakEndTime.minute : null,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(shiftFormNotifierProvider);

    ref.listen<ShiftFormState>(shiftFormNotifierProvider, (_, next) {
      if (next.saved && !_hasListened) {
        _hasListened = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turno registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Horario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Name Section ─────────────────────────────────────
              Text('DETALLES DEL TURNO', 
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2
                )
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Identificador',
                  hintText: 'Ej. Oficina Estándar',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              
              // ── Work Hours Section ───────────────────────────────
              const SizedBox(height: 40),
              Text('JORNADA LABORAL', 
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2
                )
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _TimeCard(
                      title: 'ENTRADA',
                      time: _startTime,
                      onTap: () => _selectTime(
                        context,
                        initial: _startTime,
                        onSelected: (t) => _startTime = t,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeCard(
                      title: 'SALIDA',
                      time: _endTime,
                      onTap: () => _selectTime(
                        context,
                        initial: _endTime,
                        onSelected: (t) => _endTime = t,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Break / Lunch Section ────────────────────────────
              const SizedBox(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('RECESO / ALMUERZO', 
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2
                  )
                ),
                subtitle: const Text('Activar si aplica hora de almuerzo'),
                value: _hasBreak,
                onChanged: (val) => setState(() => _hasBreak = val),
                activeColor: AppColors.primary,
              ),

              if (_hasBreak) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeCard(
                        title: 'INICIO RECESO',
                        time: _breakStartTime,
                        accentColor: AppColors.orangeWarning,
                        onTap: () => _selectTime(
                          context,
                          initial: _breakStartTime,
                          onSelected: (t) => _breakStartTime = t,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TimeCard(
                        title: 'FIN RECESO',
                        time: _breakEndTime,
                        accentColor: AppColors.orangeWarning,
                        onTap: () => _selectTime(
                          context,
                          initial: _breakEndTime,
                          onSelected: (t) => _breakEndTime = t,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // ── Submit ────────────────────────────────────────────
              const SizedBox(height: 56),
              FilledButton(
                onPressed: formState.isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                child: formState.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                  : const Text('GUARDAR TURNO'),
              ),
              if (formState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(formState.errorMessage!, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Time Selection Card ─────────────────────────────────────────────

class _TimeCard extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final VoidCallback onTap;
  final Color? accentColor;

  const _TimeCard({
    required this.title,
    required this.time,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 18, color: color),
                const SizedBox(width: 8),
                Text(timeStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

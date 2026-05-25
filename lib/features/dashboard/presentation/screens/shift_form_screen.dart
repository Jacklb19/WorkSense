import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/shared/utils/app_snack_bar.dart';
import 'package:worksense_app/shared/widgets/styled/app_section_header.dart';
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

    final timeline = _buildShiftTimeline(
      start: _startTime,
      end: _endTime,
      breakStart: _hasBreak ? _breakStartTime : null,
      breakEnd: _hasBreak ? _breakEndTime : null,
    );

    if (timeline == null) {
      _showError('La hora de salida no puede ser igual a la de entrada');
      return;
    }

    if (_hasBreak && timeline.breakStart == null) {
      _showError('El fin de receso debe ser posterior al inicio');
      return;
    }

    if (_hasBreak &&
        (timeline.breakStart! < timeline.start ||
            timeline.breakEnd! > timeline.end)) {
      _showError('El receso debe estar dentro del horario laboral');
      return;
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
    AppSnackBar.showError(context, message);
  }

  _ShiftTimeline? _buildShiftTimeline({
    required TimeOfDay start,
    required TimeOfDay end,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
  }) {
    final startMinutes = _toMinutes(start);
    var endMinutes = _toMinutes(end);

    if (endMinutes == startMinutes) {
      return null;
    }

    if (endMinutes < startMinutes) {
      endMinutes += _minutesPerDay;
    }

    int? normalizedBreakStart;
    int? normalizedBreakEnd;
    if (breakStart != null && breakEnd != null) {
      normalizedBreakStart = _normalizeIntoShiftWindow(
        time: breakStart,
        shiftStartMinutes: startMinutes,
        shiftEndMinutes: endMinutes,
      );
      normalizedBreakEnd = _normalizeIntoShiftWindow(
        time: breakEnd,
        shiftStartMinutes: startMinutes,
        shiftEndMinutes: endMinutes,
      );

      if (normalizedBreakStart == null ||
          normalizedBreakEnd == null ||
          normalizedBreakEnd <= normalizedBreakStart) {
        return _ShiftTimeline(
          start: startMinutes,
          end: endMinutes,
          breakStart: null,
          breakEnd: null,
        );
      }
    }

    return _ShiftTimeline(
      start: startMinutes,
      end: endMinutes,
      breakStart: normalizedBreakStart,
      breakEnd: normalizedBreakEnd,
    );
  }

  int? _normalizeIntoShiftWindow({
    required TimeOfDay time,
    required int shiftStartMinutes,
    required int shiftEndMinutes,
  }) {
    final rawMinutes = _toMinutes(time);
    final directCandidate = rawMinutes;
    final overnightCandidate = rawMinutes + _minutesPerDay;

    if (directCandidate >= shiftStartMinutes &&
        directCandidate <= shiftEndMinutes) {
      return directCandidate;
    }
    if (overnightCandidate >= shiftStartMinutes &&
        overnightCandidate <= shiftEndMinutes) {
      return overnightCandidate;
    }
    return null;
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static const int _minutesPerDay = 24 * 60;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(shiftFormNotifierProvider);

    ref.listen<ShiftFormState>(shiftFormNotifierProvider, (_, next) {
      if (next.saved && !_hasListened) {
        _hasListened = true;
        AppSnackBar.showSuccess(context, 'Turno registrado exitosamente');
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Horario'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppSpacing.formMaxWidth(context)),
            child: Padding(
              padding: AppSpacing.formPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Name Section ─────────────────────────────────────
              const AppSectionHeader(title: 'DETALLES DEL TURNO'),
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
              const SizedBox(height: AppDimensions.spacing40),
              const AppSectionHeader(title: 'JORNADA LABORAL'),
              
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
                  const SizedBox(width: AppDimensions.spacingXxl),
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
const SizedBox(height: AppDimensions.spacingXxl),
                const AppSectionHeader(title: 'RECESO / ALMUERZO'),
                SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activar si aplica hora de almuerzo'),
                value: _hasBreak,
                onChanged: (val) => setState(() => _hasBreak = val),
                activeThumbColor: AppColors.primary,
              ),

              if (_hasBreak) ...[
                const SizedBox(height: AppDimensions.spacingXxl),
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
                    const SizedBox(width: AppDimensions.spacingXxl),
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
              const SizedBox(height: AppDimensions.spacingXxl),
              FilledButton(
                onPressed: formState.isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, AppDimensions.buttonHeightLg)),
                child: formState.isLoading 
                  ? const CircularProgressIndicator(color: AppColors.white, strokeWidth: AppDimensions.progressStrokeWidth) 
                  : const Text('GUARDAR TURNO'),
              ),
              if (formState.errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spacingXxl),
                Text(formState.errorMessage!, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: AppColors.error, fontSize: AppDimensions.fontBody)
                ),
              ],
],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftTimeline {
  final int start;
  final int end;
  final int? breakStart;
  final int? breakEnd;

  const _ShiftTimeline({
    required this.start,
    required this.end,
    required this.breakStart,
    required this.breakEnd,
  });
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
      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl, horizontal: AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: AppColors.grey500, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: AppDimensions.iconSm, color: color),
                const SizedBox(width: AppDimensions.spacingMd),
                Text(timeStr, style: const TextStyle(fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w600, color: AppColors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

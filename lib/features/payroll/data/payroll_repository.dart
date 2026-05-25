import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/domain/entities/payroll.dart';

/// Repositorio de nómina — todas las operaciones van directo a Supabase.
class PayrollRepository {
  PayrollRepository._();
  static final PayrollRepository instance = PayrollRepository._();

  final _client = Supabase.instance.client;

  // ── PayrollConfig ─────────────────────────────────────────────────────────

  Future<List<PayrollConfig>> fetchConfigs(String companyId) async {
    try {
      final rows = await _client
          .from('payroll_configs')
          .select()
          .eq('company_id', companyId);
      return (rows as List)
          .map((r) => PayrollConfig.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertConfig(PayrollConfig config) async {
    await _client.from('payroll_configs').upsert(config.toMap());
  }

  // ── PayrollPeriod ─────────────────────────────────────────────────────────

  Future<List<PayrollPeriod>> fetchPeriods(String companyId) async {
    try {
      final rows = await _client
          .from('payroll_periods')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => PayrollPeriod.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePeriod(PayrollPeriod period) async {
    await _client.from('payroll_periods').upsert(period.toMap());
  }

  Future<void> updatePeriodStatus(String periodId, PayrollStatus status) async {
    await _client
        .from('payroll_periods')
        .update({'status': status.value})
        .eq('id', periodId);
  }

  Future<void> deletePeriod(String periodId) async {
    await _client.from('payroll_entries').delete().eq('period_id', periodId);
    await _client.from('payroll_periods').delete().eq('id', periodId);
  }

  // ── PayrollEntry ──────────────────────────────────────────────────────────

  Future<List<PayrollEntry>> fetchEntries(String periodId) async {
    try {
      final rows = await _client
          .from('payroll_entries')
          .select()
          .eq('period_id', periodId)
          .order('gross_pay', ascending: false);
      return (rows as List)
          .map((r) => PayrollEntry.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<PayrollEntry> entries) async {
    if (entries.isEmpty) return;
    await _client
        .from('payroll_entries')
        .upsert(entries.map((e) => e.toMap()).toList());
  }

  Future<void> updateEntryDeductions(String entryId, double deductions) async {
    final row = await _client
        .from('payroll_entries')
        .select('gross_pay')
        .eq('id', entryId)
        .single();
    final gross = (row['gross_pay'] as num).toDouble();
    await _client.from('payroll_entries').update({
      'deductions': deductions,
      'net_pay': gross - deductions,
    }).eq('id', entryId);
  }

  // ── Cálculo automático de horas ───────────────────────────────────────────

  /// Calcula las horas trabajadas de cada empleado en el período consultando
  /// la tabla `attendance_logs` de Supabase.
  /// Retorna un mapa employeeId → horas.
  Future<Map<String, double>> calculateHoursWorked({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T').first;
      final end   = endDate.toIso8601String().split('T').first;

      final rows = await _client
          .from('attendance_logs')
          .select('employee_id, clock_in_time, clock_out_time')
          .eq('company_id', companyId)
          .gte('shift_date', start)
          .lte('shift_date', end)
          .not('clock_out_time', 'is', null);

      final hours = <String, double>{};
      for (final r in (rows as List)) {
        final empId   = r['employee_id'] as String?;
        final clockIn = r['clock_in_time'] as String?;
        final clockOut= r['clock_out_time'] as String?;
        if (empId == null || clockIn == null || clockOut == null) continue;
        final duration = DateTime.parse(clockOut)
            .difference(DateTime.parse(clockIn))
            .inMinutes / 60.0;
        hours[empId] = (hours[empId] ?? 0) + duration.clamp(0, 24);
      }
      return hours;
    } catch (_) {
      return {};
    }
  }

  /// Genera las entradas de nómina para un período, calculando horas automáticamente.
  Future<List<PayrollEntry>> generateEntries({
    required String periodId,
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> employeeIds,
    required Map<String, double> hourlyRates, // employeeId → rate
  }) async {
    final hoursMap = await calculateHoursWorked(
      companyId: companyId,
      startDate: startDate,
      endDate: endDate,
    );

    const uuid = Uuid();
    final entries = <PayrollEntry>[];
    for (final empId in employeeIds) {
      final hours  = hoursMap[empId] ?? 0;
      final rate   = hourlyRates[empId] ?? 0;
      final gross  = hours * rate;
      entries.add(PayrollEntry(
        id:          uuid.v4(),
        periodId:    periodId,
        employeeId:  empId,
        companyId:   companyId,
        hoursWorked: double.parse(hours.toStringAsFixed(2)),
        hourlyRate:  rate,
        grossPay:    double.parse(gross.toStringAsFixed(2)),
        deductions:  0,
        netPay:      double.parse(gross.toStringAsFixed(2)),
      ));
    }
    return entries;
  }
}

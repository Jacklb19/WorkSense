import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/domain/entities/payroll.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:worksense_app/features/payroll/data/payroll_repository.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Períodos ──────────────────────────────────────────────────────────────────

final payrollPeriodsProvider =
    AsyncNotifierProvider<PayrollPeriodsNotifier, List<PayrollPeriod>>(
  PayrollPeriodsNotifier.new,
);

class PayrollPeriodsNotifier
    extends AsyncNotifier<List<PayrollPeriod>> {
  @override
  Future<List<PayrollPeriod>> build() => _fetch();

  Future<List<PayrollPeriod>> _fetch() async {
    final companyId =
        ref.read(currentUserProvider).valueOrNull?.companyId ?? '';
    if (companyId.isEmpty) return [];
    return PayrollRepository.instance.fetchPeriods(companyId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String?> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final companyId   = currentUser?.companyId ?? '';
    final userId      = currentUser?.user?.id ?? '';
    if (companyId.isEmpty) return 'Sin empresa';

    state = const AsyncLoading();

    try {
      // 1. Obtener configuraciones de tarifas
      final configs = await PayrollRepository.instance.fetchConfigs(companyId);
      final rateMap = {for (final c in configs) c.employeeId: c.hourlyRate};

      // 2. Obtener todos los empleados de la empresa
      final employees = ref.read(adminEmployeesProvider).valueOrNull ?? [];
      final workerIds = employees
          .where((e) => e.role == AppRole.employee)
          .map((e) => e.id)
          .toList();

      // 3. Generar entradas (horas calculadas desde attendance_logs)
      final periodId = DateTime.now().millisecondsSinceEpoch.toString();
      final entries  = await PayrollRepository.instance.generateEntries(
        periodId:    periodId,
        companyId:   companyId,
        startDate:   startDate,
        endDate:     endDate,
        employeeIds: workerIds,
        hourlyRates: rateMap,
      );

      final totalGross = entries.fold<double>(0, (s, e) => s + e.grossPay);

      // 4. Guardar período
      final period = PayrollPeriod(
        id:            periodId,
        companyId:     companyId,
        name:          name,
        startDate:     startDate,
        endDate:       endDate,
        totalGross:    totalGross,
        employeeCount: entries.length,
        createdAt:     DateTime.now(),
        createdBy:     userId,
      );

      await PayrollRepository.instance.savePeriod(period);
      await PayrollRepository.instance.saveEntries(entries);

      await refresh();
      return null; // null = éxito
    } catch (e) {
      state = await AsyncValue.guard(_fetch);
      return e.toString();
    }
  }

  Future<void> updateStatus(String periodId, PayrollStatus status) async {
    await PayrollRepository.instance.updatePeriodStatus(periodId, status);
    await refresh();
  }

  Future<void> deletePeriod(String periodId) async {
    await PayrollRepository.instance.deletePeriod(periodId);
    await refresh();
  }
}

// ── Entradas de un período ────────────────────────────────────────────────────

final payrollEntriesProvider = FutureProviderFamily<List<PayrollEntry>, String>(
  (ref, periodId) => PayrollRepository.instance.fetchEntries(periodId),
);

// ── Configuraciones de tarifas ────────────────────────────────────────────────

final payrollConfigsProvider =
    AsyncNotifierProvider<PayrollConfigsNotifier, List<PayrollConfig>>(
  PayrollConfigsNotifier.new,
);

class PayrollConfigsNotifier extends AsyncNotifier<List<PayrollConfig>> {
  @override
  Future<List<PayrollConfig>> build() => _fetch();

  Future<List<PayrollConfig>> _fetch() async {
    final companyId =
        ref.read(currentUserProvider).valueOrNull?.companyId ?? '';
    if (companyId.isEmpty) return [];
    return PayrollRepository.instance.fetchConfigs(companyId);
  }

  Future<void> upsert(PayrollConfig config) async {
    await PayrollRepository.instance.upsertConfig(config);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

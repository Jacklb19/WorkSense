import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/repositories/employee_repository_impl.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

import '../../../../core/constants/app_constants.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return EmployeeRepositoryImpl(db, syncRepo);
});

// ── Employee List ─────────────────────────────────────────────────────────────

final employeesStreamProvider = StreamProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.watchEmployees();
});

final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.getEmployees();
});

// ── Employee Form State ───────────────────────────────────────────────────────

class EmployeeFormState {
  final bool isLoading;
  final bool saved;
  final String? errorMessage;

  const EmployeeFormState({
    this.isLoading = false,
    this.saved = false,
    this.errorMessage,
  });

  EmployeeFormState copyWith({
    bool? isLoading,
    bool? saved,
    String? errorMessage,
  }) {
    return EmployeeFormState(
      isLoading: isLoading ?? this.isLoading,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }
}

class EmployeeFormNotifier extends StateNotifier<EmployeeFormState> {
  final EmployeeRepository _localRepo;

  EmployeeFormNotifier(this._localRepo)
      : super(const EmployeeFormState());

  Future<void> saveEmployee({
    required String name,
    String companyId = AppConstants.defaultCompanyId,
    String? existingId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, saved: false);

    try {
      final employee = Employee(
        id: existingId ?? const Uuid().v4(),
        name: name.trim(),
        companyId: companyId,
        createdAt: DateTime.now(),
      );

      // Save locally (enqueues sync automatically)
      await _localRepo.saveEmployee(employee);

      state = state.copyWith(isLoading: false, saved: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al guardar empleado: $e',
      );
    }
  }

  Future<void> deleteEmployee(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _localRepo.deleteEmployee(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar empleado: $e',
      );
    }
  }

  void reset() {
    state = const EmployeeFormState();
  }
}

final employeeFormNotifierProvider =
    StateNotifierProvider<EmployeeFormNotifier, EmployeeFormState>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return EmployeeFormNotifier(repo);
});
